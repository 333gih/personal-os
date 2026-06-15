# Ubuntu VPS Deployment (cùng fash)

Hostnames production:

| | URL |
|---|-----|
| FE | https://personal-os-fe.fashandcurious.com |
| API | https://api-personal-os.fashandcurious.com |

## Jenkins secret (`env-personal-os-dev`)

Upload [`jenkins-env.example`](jenkins-env.example) as Jenkins **Secret file** credential.

Jenkinsfile loads **toàn bộ** biến từ file này — không hardcode trong pipeline:

```groovy
withCredentials([file(credentialsId: "env-personal-os-${params.ENVIRONMENT}", variable: 'ENV_FILE')]) {
  set -a; . "$ENV_FILE"; set +a   // deploy
  docker build --secret id=env_build,src="$ENV_FILE"  // FE build
  docker run --env-file "$ENV_FILE"  // API + FE runtime
}
```

```bash
NEXT_PUBLIC_SITE_URL=https://personal-os-fe.fashandcurious.com
NEXT_PUBLIC_API_URL=https://api-personal-os.fashandcurious.com/api/v1
CORS_ORIGINS=https://personal-os-fe.fashandcurious.com
POSTGRES_DATABASE_HOST=personal-os-pg
STORAGE_PROVIDER=seaweedfs
S3_ENDPOINT=seaweedfs-s3:8333
S3_PUBLIC_BASE_URL=https://storage.fashandcurious.com/personal-os
TRUSTED_PROXIES="127.0.0.1/8,::1/128,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12,100.64.0.0/10"
```

Biến Postgres theo core-service: `POSTGRES_DATABASE_*` (Jenkins tự build `DATABASE_URL` nếu không set).

## Patch fash

[`fash-integration/README.md`](fash-integration/README.md)

## Local dev

```bash
cd docker && cp .env.example .env && docker compose up -d --build
```

FE `.env.local`:

```bash
NEXT_PUBLIC_SITE_URL=http://localhost:3000
NEXT_PUBLIC_API_URL=http://localhost:8080/api/v1
```

## Verify

```bash
curl https://api-personal-os.fashandcurious.com/health
curl -I https://personal-os-fe.fashandcurious.com/login
```
