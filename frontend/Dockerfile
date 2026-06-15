FROM node:22-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci

FROM node:22-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Local dev: build-args from docker-compose .env
# Jenkins/prod: NEXT_PUBLIC_* from secret file only (fash-portal-fe pattern)
ARG NEXT_PUBLIC_API_URL=http://localhost:8080/api/v1
ARG NEXT_PUBLIC_SITE_URL=http://localhost:3000

RUN --mount=type=secret,id=env_build,required=false \
    if [ -f /run/secrets/env_build ]; then \
      set -a && . /run/secrets/env_build && set +a; \
    else \
      export NEXT_PUBLIC_API_URL="${NEXT_PUBLIC_API_URL}"; \
      export NEXT_PUBLIC_SITE_URL="${NEXT_PUBLIC_SITE_URL}"; \
    fi && \
    echo "NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL}" && \
    echo "NEXT_PUBLIC_SITE_URL=${NEXT_PUBLIC_SITE_URL}" && \
    npm run build

FROM node:22-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
RUN addgroup --system --gid 1001 nodejs && adduser --system --uid 1001 nextjs
RUN mkdir -p public && chown nextjs:nodejs public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
USER nextjs
EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME=0.0.0.0
CMD ["node", "server.js"]
