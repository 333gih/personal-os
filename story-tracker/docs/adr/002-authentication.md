# ADR 002: JWT Authentication Strategy (Fash Auth + API Gateway)

## Status

Accepted (revised)

## Context

Story Tracker must authenticate like the Personal OS frontend and fash-admin-portal: API calls go through Kong gateway (`api-personal-os.fashandcurious.com`) with `Authorization: Bearer` tokens issued by **fash-auth-service** (`api-auth.fashandcurious.com`).

The extension supports two audiences:

1. **Internal** — staff accounts, login only, `admin: true` required in JWT
2. **Commercial** — end users, login + register (Fash iOS pattern), no admin requirement

## Decision

### Two-service architecture

| Service | Base URL | Purpose |
|---------|----------|---------|
| fash-auth-service | `AUTH_API_URL` + `AUTH_LOCALE` | login, register, refresh, logout |
| Personal OS API | `API_BASE_URL` (Kong gateway) | reading progress sync |

### Auth flow

```
Popup → background → fash-auth POST /{locale}/api/v1/auth/login|register
  → TokenResponse (access_token, refresh_token, expires_in)
  → Internal: verify admin claim in JWT before saving session
  → storage.local

Sync → gateway API with Authorization: Bearer <access_token>
  → 401 → refresh via fash-auth → retry once
```

### Request shapes (same as frontend BFF upstream)

**Login / Refresh / Logout** include `application_id`:

- Internal uses `INTERNAL_APPLICATION_ID`
- Commercial uses `COMMERCIAL_APPLICATION_ID`

**Register** (commercial only):

```json
{ "email", "password", "name", "application_id" }
```

### Admin gate (internal only)

After login, decode JWT and require one of: `admin`, `is_admin`, `isAdmin` === true.
Reject with clear error if missing.

### Gateway client

- `requireAuth: true` — refuse API calls without token
- Auto-inject `Authorization: Bearer`
- On 401: refresh tokens via fash-auth, retry once

## Consequences

### Positive

- Matches production Personal OS / Fash stack
- Separate application IDs for internal vs commercial
- No localhost assumptions in default config
- Host permissions include both API domains

### Negative

- Application IDs must be provisioned in fash-auth-service
- Admin claim shape depends on fash-auth JWT payload
- Extension stores tokens in `storage.local` (standard WebExtension trade-off)

### Risks

- Register endpoint contract may differ slightly from Fash iOS → path is fixed, body fields documented
- JWT without admin claim blocks internal users → intentional security gate

## Alternatives Considered

| Approach | Rejected Because |
|----------|------------------|
| Login directly to personal-os-api `/auth/login` | Production uses fash-auth, not local auth |
| Single application_id for both modes | Cannot separate internal admin vs commercial users |
| Cookie-based BFF in extension | No Next.js server; extension must call fash-auth directly |
