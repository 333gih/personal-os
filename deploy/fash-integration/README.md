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
NEXT_PUBLIC_API_URL=/api/v1
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
