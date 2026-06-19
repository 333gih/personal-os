# Tích hợp Personal OS vào stack fash

**Đã patch trực tiếp trong `D:\Project\fash`** (Kong + Traefik + fash-rbac skip). Snippet trong thư mục này chỉ để tham chiếu / staging-prod.

## Luồng production

```
Browser → personal-os-fe.fashandcurious.com → Traefik → personal-os-fe-app-{env}:3000
Browser → api-personal-os.fashandcurious.com  → Traefik → Kong → personal-os-api:8080
```

- API **không** join `traefik-public` — chỉ `iot-public-net-{env}` (Kong gọi upstream).
- FE join `traefik-public` (Traefik terminate TLS).

## Hostnames

| Vai trò | Subdomain |
|---------|-----------|
| **Frontend** | `personal-os-fe.fashandcurious.com` |
| **API** | `api-personal-os.fashandcurious.com` |

```bash
NEXT_PUBLIC_SITE_URL=https://personal-os-fe.fashandcurious.com
NEXT_PUBLIC_API_URL=https://api-personal-os.fashandcurious.com/api/v1
CORS_ORIGINS=https://personal-os-fe.fashandcurious.com
```

## File đã sửa trong fash

| File | Thay đổi |
|------|----------|
| `fash-api-gateway/docker/entrypoint.sh` | `PERSONAL_OS_API_HOST`, `API_SUBDOMAIN_PERSONAL_OS_HOST` |
| `fash-api-gateway/config/kong.yml.tpl` | upstream, service, routes, rate-limit (no JWT) |
| `fash-api-gateway/kong/plugins/fash-rbac/handler.lua` | skip RBAC cho `personal-os-api` |
| `traefix/dynamic/services.yml` | FE router + api-personal-os → Kong |
| `traefix/traefix.yml` | TLS SAN |

## Deploy sau khi merge fash

1. Redeploy **fash-api-gateway** (Kong config + fash-rbac plugin).
2. Reload Traefik (file provider watch hoặc restart container).
3. Thêm vào gateway Jenkins secret: `PERSONAL_OS_API_HOST=personal-os-api:8080` và `https://personal-os-fe.fashandcurious.com` vào `CORS_ALLOWED_ORIGINS`.
4. Deploy **personal-os** Jenkins pipeline (API + FE + Postgres).

## Verify

```bash
curl https://api-personal-os.fashandcurious.com/health
curl -I https://personal-os-fe.fashandcurious.com/login
```

## Troubleshooting: `failure to get a peer from the ring-balancer` (503)

Kong trả JSON này khi **upstream `personal-os-api.upstream` không có target healthy** — Kong biết route `api-personal-os.fashandcurious.com` nhưng **không gọi được** container Go API.

Đây **không phải** lỗi JWT/extension; là lỗi **Docker network / container chưa chạy**.

### Luồng đúng

```
Client → Traefik (api-personal-os.*)
       → Kong (fash-api-gateway trên iot-public-net-prod)
       → DNS personal-os-api:8080
       → container personal-os-api-app-prod
```

Kong config (`fash-api-gateway/config/kong.yml.tpl`):

- `PERSONAL_OS_API_HOST=personal-os-api:8080` (Jenkins secret `env-fash-api-gateway-prod`)
- Active healthcheck: `GET /health` trên target đó
- Nếu DNS fail hoặc healthcheck fail 3 lần → target **UNHEALTHY** → `ring-balancer` 503

### Checklist trên VPS (prod)

```bash
ENV=prod
GW=fash-api-gateway-${ENV}
API=personal-os-api-app-${ENV}
NET=iot-public-net-${ENV}

# 1) Container API có chạy không?
docker ps -a --filter name=${API}

# 2) /health trong container?
docker exec ${API} wget -qO- http://127.0.0.1:8080/health

# 3) Kong resolve được personal-os-api trên cùng mạng không?
docker run --rm --network ${NET} curlimages/curl:8.5.0 -sf http://personal-os-api:8080/health

# 4) API đã join iot-public-net với alias chưa?
docker network inspect ${NET} --format '{{json .Containers}}' | jq .

# 5) Kong join cùng mạng chưa?
docker inspect ${GW} --format '{{range $k,$v := .NetworkSettings.Networks}}{{$k}} {{end}}'

# 6) Qua Kong (từ trong container Kong)
docker exec ${GW} curl -s -o /dev/null -w "%{http_code}\n" \
  -H "Host: api-personal-os.fashandcurious.com" http://127.0.0.1:8000/health
# Kỳ vọng: 200 (không phải 503)

# 7) Public
curl -s https://api-personal-os.fashandcurious.com/health
```

### Hotfix (gateway dev, personal-os prod)

Thêm vào Jenkins secret `env-personal-os-api-prod`:

```env
IOT_PUBLIC_NET=iot-public-net-dev
```

Trên VPS ngay lập tức:

```bash
# Nếu chỉ nối nhầm prod network — rút ra (tùy chọn)
docker network disconnect iot-public-net-prod personal-os-api-app-prod 2>/dev/null || true

# Nối đúng mạng Kong đang dùng
docker network connect --alias personal-os-api iot-public-net-dev personal-os-api-app-prod

docker run --rm --network iot-public-net-dev curlimages/curl:8.5.0 -sf http://personal-os-api:8080/health
curl -s https://api-personal-os.fashandcurious.com/health
```

### Nguyên nhân hay gặp

| # | Triệu chứng | Cách xử lý |
|---|-------------|------------|
| 1 | `docker ps` không thấy `personal-os-api-app-prod` | Chạy Jenkins job **personal-os** (API+FE), kiểm tra log build |
| 2 | API running nhưng bước (3) fail | `docker network connect --alias personal-os-api ...` (xem hotfix) |
| 3 | Jenkins personal-os báo upstream OK nhưng sau đó API restart | Xem `docker logs personal-os-api-app-prod` (DB, env, crash) |
| 4 | Gateway prod chưa redeploy sau khi thêm personal-os routes | Redeploy **fash-api-gateway** prod |
| 5 | `IOT_PUBLIC_NET` sai (prod API trên `iot-public-net-prod`, Kong trên `dev`) | Set `IOT_PUBLIC_NET=iot-public-net-dev` trong **env-personal-os-api-prod** |
| 6 | Secret gateway thiếu `PERSONAL_OS_API_HOST` | Thêm `PERSONAL_OS_API_HOST=personal-os-api:8080` vào `env-fash-api-gateway-prod` |

### Fix lâu dài (đã chỉnh trong fash-api-gateway)

- Upstream `personal-os-api.upstream`: thêm `tcp_failures` + **passive healthchecks** (giống `core-service`)
- Service `personal-os-api`: `port: 8080` (khớp target)

Sau khi sửa `kong.yml.tpl`: **redeploy fash-api-gateway** + đảm bảo personal-os API trên `iot-public-net-prod`.

**Migrations:** Jenkins áp dụng `005_reading_progress.sql` và `006_reading_progress_latest_per_story.sql` mỗi deploy. Nếu deploy cũ chưa chạy, apply thủ công:

```bash
cat backend/migrations/005_reading_progress.sql | docker exec -i personal-os-pg-prod psql -U "$USER" -d personalos
cat backend/migrations/006_reading_progress_latest_per_story.sql | docker exec -i personal-os-pg-prod psql -U "$USER" -d personalos
```
