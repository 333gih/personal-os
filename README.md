# Personal OS

Self-hosted personal knowledge platform — tích hợp với stack **fash** trên cùng VPS (Traefik + Kong + SeaweedFS).

## Kiến trúc (production trên VPS fash)

```
Browser
   │
   ▼
Traefik (traefik-public) ── personal-os-fe.fashandcurious.com ──► personal-os-fe-app-dev:3000
   │
   └── api-personal-os.fashandcurious.com ──► Kong ──► personal-os-api:8080
                              │
                              ├── personal-os-pg-dev (Postgres + pgvector)
                              └── seaweedfs-s3:8333 (bucket personal-os/)
```

**Không dùng:** Nginx riêng, MinIO riêng, microservices, K8s.

## Quick start (local dev)

```bash
cd docker
cp .env.example .env
docker compose up -d --build
```

- Frontend: http://localhost:3000
- API: http://localhost:8080
- Login: `admin@personal-os.local` / `changeme123`

Với SeaweedFS fash đang chạy:

```bash
docker compose -f docker-compose.yml -f docker-compose.seaweedfs.yml up -d
```

## Deploy production (Jenkins — một job, cả API + FE)

**Một Jenkinsfile** deploy đồng thời:
- `personal-os-api-app-{env}` (Go API)
- `personal-os-fe-app-{env}` (Next.js)
- `personal-os-pg-{env}` (Postgres)

1. Upload secret `env-personal-os-dev` từ [`deploy/jenkins-env.example`](deploy/jenkins-env.example)
2. Patch fash Traefik + Kong: [`deploy/fash-integration/README.md`](deploy/fash-integration/README.md)
3. Sửa `GIT_REPO` trong [`Jenkinsfile`](Jenkinsfile)
4. **Build** một lần → cả 2 service lên (FE chỉ deploy sau khi API `/health` OK)

## Cấu trúc project

```
personal-os/
├── backend/           # Go API (Gin, GORM, pgvector)
├── frontend/          # Next.js 15
├── docker/            # Local compose (Postgres + API + FE)
├── deploy/
│   ├── fash-integration/   # Snippet Traefik + Kong
│   ├── jenkins-env.example
│   └── migrate-storage-to-seaweedfs.sh
└── Jenkinsfile        # CI/CD API + FE
```

## Storage (SeaweedFS — giống core-service)

| Biến | Ví dụ |
|------|-------|
| `STORAGE_PROVIDER` | `seaweedfs` |
| `S3_ENDPOINT` | `seaweedfs-s3:8333` |
| `S3_BUCKET` | `personal-os` |
| `S3_PUBLIC_BASE_URL` | `https://storage.fashandcurious.com/personal-os` |

Object keys: `personal-os/{user-id}/{uuid}.ext` — tách biệt với `fash-uploads`.

Migrate từ MinIO cũ: [`deploy/migrate-storage-to-seaweedfs.sh`](deploy/migrate-storage-to-seaweedfs.sh) + `migrations/003_storage_key_prefix.sql`.

## API

OpenAPI: [`backend/docs/openapi.yaml`](backend/docs/openapi.yaml)

Production base URL: `https://api-personal-os.fashandcurious.com/api/v1`

## Hostnames

| Env | Frontend | API |
|-----|----------|-----|
| prod | `personal-os-fe.fashandcurious.com` | `api-personal-os.fashandcurious.com` |

FE gọi API qua `NEXT_PUBLIC_API_URL=https://api-personal-os.fashandcurious.com/api/v1`

Chi tiết VPS: [`deploy/ubuntu-vps.md`](deploy/ubuntu-vps.md)
