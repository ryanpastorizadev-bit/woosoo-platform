---
status: canonical
last_reviewed: 2026-05-18
scope: ecosystem
---

# Woosoo Platform — Production Docker Plan

## Raspberry Pi Deployment · Complete Reference

---

## 0. Guiding Principles

1. **Build-time assembly, not runtime assembly.** The image is the artifact. The server runs it.
2. **Every service has a healthcheck.** No healthcheck = no trust.
3. **Deployment is a validated gate, not a hope.** Doctor must pass. Smoke must pass. Only then is deployment accepted.
4. **Failure is loud and immediate.** Silent failures are operational poison.
5. **Dev and prod are separate contracts.** No shared compose file that tries to be both.

---

## 1. Project Structure

```txt
woosoo/
├── apps/
│   ├── woosoo-nexus/              # Laravel app
│   ├── tablet-ordering-pwa/       # Nuxt static PWA
│   └── print-bridge/              # Node print bridge service
│
├── docker/
│   ├── php/
│   │   └── Dockerfile             # Laravel multi-stage build
│   ├── nginx/
│   │   ├── Dockerfile
│   │   ├── nginx.conf
│   │   └── sites/
│   │       ├── nexus.conf
│   │       └── tablet.conf
│   ├── tablet-pwa/
│   │   └── Dockerfile             # Nuxt static + Nginx
│   ├── print-bridge/
│   │   └── Dockerfile
│   └── scripts/
│       ├── wait-healthy.sh
│       └── smoke-check.sh
│
├── docker-compose.yml             # Shared base (no dev mounts, no prod images)
├── docker-compose.override.yml    # Dev: volume mounts, debug ports, mailpit
├── docker-compose.prod.yml        # Prod: image refs, resource limits, restart policies
│
├── deploy.sh                      # Production deploy script
├── .env.example                   # Committed template, no secrets
└── .env                           # Never committed. chmod 600.
```

---

## 2. Dockerfiles

### 2a. Laravel — `docker/php/Dockerfile`

```dockerfile
# ─── Stage 1: Base PHP runtime ──────────────────────────────────────────────
FROM php:8.3-fpm-alpine AS base

RUN apk add --no-cache \
    bash \
    curl \
    git \
    unzip \
    icu-dev \
    oniguruma-dev \
    libzip-dev \
    mysql-client \
    fcgi \
    && docker-php-ext-install \
        pdo \
        pdo_mysql \
        intl \
        mbstring \
        zip \
        opcache \
        pcntl \
    && apk del git unzip

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# OPcache tuned for production
RUN echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/opcache.ini \
 && echo "opcache.memory_consumption=128" >> /usr/local/etc/php/conf.d/opcache.ini \
 && echo "opcache.interned_strings_buffer=16" >> /usr/local/etc/php/conf.d/opcache.ini \
 && echo "opcache.max_accelerated_files=10000" >> /usr/local/etc/php/conf.d/opcache.ini \
 && echo "opcache.validate_timestamps=0" >> /usr/local/etc/php/conf.d/opcache.ini \
 && echo "opcache.save_comments=1" >> /usr/local/etc/php/conf.d/opcache.ini

WORKDIR /var/www/nexus


# ─── Stage 2: Vendor install ─────────────────────────────────────────────────
FROM base AS vendor

COPY apps/woosoo-nexus/composer.json apps/woosoo-nexus/composer.lock ./

RUN composer install \
    --no-dev \
    --prefer-dist \
    --no-interaction \
    --no-progress \
    --optimize-autoloader \
    --no-scripts


# ─── Stage 3: Production image ───────────────────────────────────────────────
FROM base AS production

WORKDIR /var/www/nexus

# Copy application source
COPY apps/woosoo-nexus ./

# Copy pre-built vendor from stage 2
COPY --from=vendor /var/www/nexus/vendor ./vendor

# Set permissions
RUN mkdir -p storage/logs storage/framework/{sessions,views,cache} bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R ug+rwX storage bootstrap/cache \
    # Remove dev artifacts
    && rm -rf .git tests

# Do NOT run artisan optimize here.
# Caches depend on .env values which are not present at build time.
# Caching happens in deploy.sh after .env is injected.

USER www-data

HEALTHCHECK --interval=15s --timeout=5s --retries=5 --start-period=20s \
    CMD SCRIPT_NAME=/health SCRIPT_FILENAME=/health REQUEST_METHOD=GET \
        cgi-fcgi -bind -connect 127.0.0.1:9000 >/dev/null 2>&1 || exit 1

CMD ["php-fpm"]
```

> **Note on the PHP-FPM healthcheck:** `cgi-fcgi` hits the FPM socket directly and confirms
> the process pool is accepting connections — not just that the binary exists.
> This requires `fcgi` in apk and `cgi-fcgi` binary. If unavailable on your Alpine build,
> use `php-fpm-healthcheck` as a fallback.

### 2b. Nginx — `docker/nginx/Dockerfile`

```dockerfile
FROM nginx:1.25-alpine

RUN apk add --no-cache curl

COPY docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY docker/nginx/sites/ /etc/nginx/conf.d/

HEALTHCHECK --interval=15s --timeout=5s --retries=10 --start-period=30s \
    CMD curl -fsS http://localhost/api/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
```

### 2c. Nginx config — `docker/nginx/sites/nexus.conf`

```nginx
upstream nexus_fpm {
    server nexus-app:9000;
}

server {
    listen 80;
    server_name _;
    root /var/www/nexus/public;

    index index.php;
    client_max_body_size 64M;

    # Laravel app
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    # PHP-FPM
    location ~ \.php$ {
        fastcgi_pass nexus_fpm;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_read_timeout 60;
    }

    # Reverb WebSocket — /reverb, not /app
    location /reverb {
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_read_timeout 60s;
        proxy_send_timeout 60s;
        proxy_pass http://nexus-reverb:8080;
    }

    # Health endpoint — no PHP required, fast nginx stub
    location /api/health {
        access_log off;
        return 200 "ok\n";
        add_header Content-Type text/plain;
    }

    # Block dot files
    location ~ /\. {
        deny all;
    }
}
```

> **Why `/api/health` returns 200 from Nginx directly:**  
> It proves Nginx is alive and routing. Laravel's own health is confirmed by `woosoo:doctor`.
> Avoid routing health through PHP-FPM on every container poll — it adds unnecessary load
> on a Pi and creates a cascade dependency.

### 2d. Tablet PWA — `docker/tablet-pwa/Dockerfile`

```dockerfile
# ─── Stage 1: Build ──────────────────────────────────────────────────────────
FROM node:22-alpine AS build

WORKDIR /app

COPY apps/tablet-ordering-pwa/package*.json ./
RUN npm ci --prefer-offline

COPY apps/tablet-ordering-pwa ./

# Build-time public env vars must be set here
# Pass via --build-arg in docker-compose.prod.yml
ARG NUXT_PUBLIC_API_BASE
ARG NUXT_PUBLIC_REVERB_HOST
ARG NUXT_PUBLIC_REVERB_PORT
ARG NUXT_PUBLIC_REVERB_SCHEME
ARG NUXT_PUBLIC_REVERB_APP_KEY

ENV NUXT_PUBLIC_API_BASE=$NUXT_PUBLIC_API_BASE
ENV NUXT_PUBLIC_REVERB_HOST=$NUXT_PUBLIC_REVERB_HOST
ENV NUXT_PUBLIC_REVERB_PORT=$NUXT_PUBLIC_REVERB_PORT
ENV NUXT_PUBLIC_REVERB_SCHEME=$NUXT_PUBLIC_REVERB_SCHEME
ENV NUXT_PUBLIC_REVERB_APP_KEY=$NUXT_PUBLIC_REVERB_APP_KEY

RUN npm run generate


# ─── Stage 2: Serve static output ────────────────────────────────────────────
FROM nginx:1.25-alpine AS production

RUN apk add --no-cache curl

COPY --from=build /app/.output/public /usr/share/nginx/html

# Simple SPA routing — redirect 404s to index.html
COPY docker/tablet-pwa/nginx.conf /etc/nginx/conf.d/default.conf

HEALTHCHECK --interval=15s --timeout=5s --retries=10 --start-period=20s \
    CMD curl -fsS http://localhost/ || exit 1

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

`docker/tablet-pwa/nginx.conf`:

```nginx
server {
    listen 80;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /health {
        access_log off;
        return 200 "ok\n";
        add_header Content-Type text/plain;
    }
}
```

### 2e. Print Bridge — `docker/print-bridge/Dockerfile`

```dockerfile
FROM node:22-alpine AS build

WORKDIR /app

COPY apps/print-bridge/package*.json ./
RUN npm ci --prefer-offline

COPY apps/print-bridge ./
RUN npm run build 2>/dev/null || true   # if using tsc; skip if plain JS


FROM node:22-alpine AS production

WORKDIR /app

RUN apk add --no-cache curl

COPY --from=build /app ./

USER node

HEALTHCHECK --interval=30s --timeout=5s --retries=5 --start-period=20s \
    CMD curl -fsS http://localhost:3100/health || exit 1

EXPOSE 3100

CMD ["node", "dist/index.js"]
```

The Print Bridge **must** expose `GET /health` that returns:

- `200` if bridge can reach Nexus API and printer is reachable
- `503` if either check fails

Silent print failure is operational poison. This endpoint is the antidote.

---

## 3. Docker Compose Files

### 3a. `docker-compose.yml` — Shared base

```yaml
version: "3.9"

networks:
  woosoo:
    driver: bridge

volumes:
  mysql_data:
  redis_data:
  nexus_storage:

services:

  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    volumes:
      - mysql_data:/var/lib/mysql
    networks:
      - woosoo
    healthcheck:
      test: ["CMD-SHELL", "mysqladmin ping -h localhost -u${MYSQL_USER} -p${MYSQL_PASSWORD} --silent"]
      interval: 10s
      timeout: 5s
      retries: 15
      start_period: 40s

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    networks:
      - woosoo
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "${REDIS_PASSWORD}", "ping"]
      interval: 10s
      timeout: 3s
      retries: 10
      start_period: 10s

  nexus-app:
    build:
      context: .
      dockerfile: docker/php/Dockerfile
      target: production
    environment:
      - APP_ENV=${APP_ENV}
      - APP_KEY=${APP_KEY}
      - APP_URL=${APP_URL}
      - DB_HOST=mysql
      - DB_PORT=3306
      - DB_DATABASE=${MYSQL_DATABASE}
      - DB_USERNAME=${MYSQL_USER}
      - DB_PASSWORD=${MYSQL_PASSWORD}
      - REDIS_HOST=redis
      - REDIS_PASSWORD=${REDIS_PASSWORD}
      - SESSION_DRIVER=redis
      - CACHE_STORE=redis
      - QUEUE_CONNECTION=redis
      - REVERB_APP_KEY=${REVERB_APP_KEY}
      - REVERB_APP_SECRET=${REVERB_APP_SECRET}
      - REVERB_APP_ID=${REVERB_APP_ID}
    volumes:
      - nexus_storage:/var/www/nexus/storage
    networks:
      - woosoo
    depends_on:
      mysql:
        condition: service_healthy
      redis:
        condition: service_healthy

  nexus-queue:
    build:
      context: .
      dockerfile: docker/php/Dockerfile
      target: production
    command: php artisan queue:work redis --sleep=3 --tries=3 --max-time=3600
    environment:
      - APP_ENV=${APP_ENV}
      - APP_KEY=${APP_KEY}
      - DB_HOST=mysql
      - DB_PORT=3306
      - DB_DATABASE=${MYSQL_DATABASE}
      - DB_USERNAME=${MYSQL_USER}
      - DB_PASSWORD=${MYSQL_PASSWORD}
      - REDIS_HOST=redis
      - REDIS_PASSWORD=${REDIS_PASSWORD}
      - QUEUE_CONNECTION=redis
    volumes:
      - nexus_storage:/var/www/nexus/storage
    networks:
      - woosoo
    depends_on:
      nexus-app:
        condition: service_healthy

  nexus-scheduler:
    build:
      context: .
      dockerfile: docker/php/Dockerfile
      target: production
    command: >
      sh -c "while true; do php artisan schedule:run --verbose --no-interaction; sleep 60; done"
    environment:
      - APP_ENV=${APP_ENV}
      - APP_KEY=${APP_KEY}
      - DB_HOST=mysql
      - DB_PORT=3306
      - DB_DATABASE=${MYSQL_DATABASE}
      - DB_USERNAME=${MYSQL_USER}
      - DB_PASSWORD=${MYSQL_PASSWORD}
      - REDIS_HOST=redis
      - REDIS_PASSWORD=${REDIS_PASSWORD}
    volumes:
      - nexus_storage:/var/www/nexus/storage
    networks:
      - woosoo
    depends_on:
      nexus-app:
        condition: service_healthy

  nexus-reverb:
    build:
      context: .
      dockerfile: docker/php/Dockerfile
      target: production
    command: php artisan reverb:start --host=0.0.0.0 --port=8080
    environment:
      - APP_ENV=${APP_ENV}
      - APP_KEY=${APP_KEY}
      - REVERB_APP_KEY=${REVERB_APP_KEY}
      - REVERB_APP_SECRET=${REVERB_APP_SECRET}
      - REVERB_APP_ID=${REVERB_APP_ID}
      - REDIS_HOST=redis
      - REDIS_PASSWORD=${REDIS_PASSWORD}
    networks:
      - woosoo
    depends_on:
      nexus-app:
        condition: service_healthy

  nginx:
    build:
      context: .
      dockerfile: docker/nginx/Dockerfile
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - nexus_storage:/var/www/nexus/storage:ro
    networks:
      - woosoo
    depends_on:
      nexus-app:
        condition: service_healthy

  tablet-pwa:
    build:
      context: .
      dockerfile: docker/tablet-pwa/Dockerfile
    networks:
      - woosoo

  print-bridge:
    build:
      context: .
      dockerfile: docker/print-bridge/Dockerfile
    environment:
      - NEXUS_API_BASE=${APP_URL}
      - NEXUS_BRIDGE_KEY=${PRINT_BRIDGE_KEY}
      - PRINTER_HOST=${PRINTER_HOST}
      - PRINTER_PORT=${PRINTER_PORT}
    networks:
      - woosoo
```

### 3b. `docker-compose.override.yml` — Development only

```yaml
# Loaded automatically by `docker compose up` in dev.
# Never used in production.

services:

  nexus-app:
    build:
      target: base         # dev uses base stage, not production
    volumes:
      - ./apps/woosoo-nexus:/var/www/nexus   # live code mount
    environment:
      - APP_ENV=local
      - APP_DEBUG=true
    ports:
      - "9003:9003"        # Xdebug

  mysql:
    ports:
      - "3306:3306"        # expose for TablePlus/Sequel Ace

  redis:
    ports:
      - "6379:6379"

  mailpit:
    image: axllent/mailpit
    ports:
      - "8025:8025"
      - "1025:1025"
    networks:
      - woosoo
```

### 3c. `docker-compose.prod.yml` — Production overrides

```yaml
services:

  nexus-app:
    image: woosoo-nexus-app:${IMAGE_TAG:-latest}
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 512m

  nexus-queue:
    image: woosoo-nexus-app:${IMAGE_TAG:-latest}
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 256m

  nexus-scheduler:
    image: woosoo-nexus-app:${IMAGE_TAG:-latest}
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 128m

  nexus-reverb:
    image: woosoo-nexus-app:${IMAGE_TAG:-latest}
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 128m

  nginx:
    image: woosoo-nginx:${IMAGE_TAG:-latest}
    restart: unless-stopped

  tablet-pwa:
    image: woosoo-tablet-pwa:${IMAGE_TAG:-latest}
    restart: unless-stopped
    build:
      args:
        NUXT_PUBLIC_API_BASE: ${APP_URL}
        NUXT_PUBLIC_REVERB_HOST: ${REVERB_HOST}
        NUXT_PUBLIC_REVERB_PORT: ${REVERB_PORT}
        NUXT_PUBLIC_REVERB_SCHEME: ${REVERB_SCHEME}
        NUXT_PUBLIC_REVERB_APP_KEY: ${REVERB_APP_KEY}

  print-bridge:
    image: woosoo-print-bridge:${IMAGE_TAG:-latest}
    restart: unless-stopped

  mysql:
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 512m

  redis:
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 128m
```

---

## 4. Scripts

### 4a. `docker/scripts/wait-healthy.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

SERVICE="$1"
MAX_WAIT="${2:-120}"   # seconds before giving up
ELAPSED=0

echo "⏳ Waiting for $SERVICE to become healthy..."

while true; do
  CONTAINER_ID=$(docker compose ps -q "$SERVICE" 2>/dev/null || true)

  if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No container found for service: $SERVICE"
    exit 1
  fi

  STATUS=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_ID" 2>/dev/null || echo "none")

  if [ "$STATUS" = "healthy" ]; then
    echo "✅ $SERVICE is healthy."
    exit 0
  fi

  if [ "$STATUS" = "unhealthy" ]; then
    echo "❌ $SERVICE is unhealthy. Aborting."
    docker inspect --format='{{json .State.Health}}' "$CONTAINER_ID" | python3 -m json.tool || true
    exit 1
  fi

  if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
    echo "❌ Timed out waiting for $SERVICE after ${MAX_WAIT}s."
    exit 1
  fi

  sleep 3
  ELAPSED=$((ELAPSED + 3))
done
```

### 4b. `docker/scripts/smoke-check.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

BASE="${1:-https://localhost}"
TABLET="${2:-http://localhost:4443}"

echo "=== HTTP Smoke Checks ==="

check() {
  local label="$1"
  local url="$2"
  local expected="${3:-200}"

  STATUS=$(curl -k -o /dev/null -s -w "%{http_code}" "$url")
  if [ "$STATUS" = "$expected" ]; then
    echo "  ✅ $label → $STATUS"
  else
    echo "  ❌ $label → $STATUS (expected $expected)"
    exit 1
  fi
}

check "Nginx health"        "$BASE/api/health"
check "Laravel login page"  "$BASE/login"
check "Tablet PWA"          "$TABLET/"
check "Print Bridge health" "http://localhost:3100/health"

echo "=== All smoke checks passed ==="
```

### 4c. `deploy.sh` — Production deploy script

```bash
#!/usr/bin/env bash
set -euo pipefail

COMPOSE="docker compose -f docker-compose.yml -f docker-compose.prod.yml"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║   Woosoo Platform — Production Deploy ║"
echo "╚══════════════════════════════════════╝"
echo ""

# ── 1. Build all images ───────────────────────────────────────────────────────
echo "▶ [1/9] Building images..."
$COMPOSE build --no-cache

# ── 2. Start databases ────────────────────────────────────────────────────────
echo "▶ [2/9] Starting MySQL and Redis..."
$COMPOSE up -d mysql redis

echo "▶ [2/9] Waiting for MySQL..."
bash docker/scripts/wait-healthy.sh mysql 120

echo "▶ [2/9] Waiting for Redis..."
bash docker/scripts/wait-healthy.sh redis 60

# ── 3. Start Laravel app ──────────────────────────────────────────────────────
echo "▶ [3/9] Starting Laravel app (PHP-FPM)..."
$COMPOSE up -d nexus-app

echo "▶ [3/9] Waiting for Laravel app container..."
bash docker/scripts/wait-healthy.sh nexus-app 90

# ── 4. Prepare Laravel runtime ────────────────────────────────────────────────
echo "▶ [4/9] Clearing stale caches..."
$COMPOSE exec nexus-app php artisan optimize:clear

echo "▶ [4/9] Running migrations..."
$COMPOSE exec nexus-app php artisan migrate --force

echo "▶ [4/9] Ensuring storage link..."
$COMPOSE exec nexus-app sh -c '
  if [ ! -L public/storage ]; then
    php artisan storage:link
    echo "  Storage link created."
  else
    echo "  Storage link already exists."
  fi
'

echo "▶ [4/9] Rebuilding Laravel caches..."
$COMPOSE exec nexus-app php artisan config:cache
$COMPOSE exec nexus-app php artisan route:cache
$COMPOSE exec nexus-app php artisan view:cache
$COMPOSE exec nexus-app php artisan event:cache

# ── 5. Start Nginx ────────────────────────────────────────────────────────────
echo "▶ [5/9] Starting Nginx..."
$COMPOSE up -d nginx

echo "▶ [5/9] Waiting for Nginx..."
bash docker/scripts/wait-healthy.sh nginx 60

# ── 6. Start remaining services ───────────────────────────────────────────────
echo "▶ [6/9] Starting queue, scheduler, reverb, PWA, print bridge..."
$COMPOSE up -d nexus-queue nexus-scheduler nexus-reverb tablet-pwa print-bridge

echo "▶ [6/9] Waiting for Tablet PWA..."
bash docker/scripts/wait-healthy.sh tablet-pwa 60

echo "▶ [6/9] Waiting for Print Bridge..."
bash docker/scripts/wait-healthy.sh print-bridge 60

# ── 7. Platform doctor ────────────────────────────────────────────────────────
echo "▶ [7/9] Running platform doctor..."
if ! $COMPOSE exec nexus-app php artisan woosoo:doctor; then
  echo ""
  echo "❌ woosoo:doctor FAILED. Deployment halted."
  echo "   Review output above. Fix issues and re-run deploy.sh."
  exit 1
fi

# ── 8. HTTP smoke checks ──────────────────────────────────────────────────────
echo "▶ [8/9] Running HTTP smoke checks..."
bash docker/scripts/smoke-check.sh "https://localhost" "http://localhost:4443"

# ── 9. Final status ───────────────────────────────────────────────────────────
echo "▶ [9/9] Final container status:"
$COMPOSE ps

echo ""
echo "✅ Deployment completed successfully."
echo "   Platform is healthy and smoke checks passed."
```

---

## 5. Operational Notes

- `.env` is environment input, never source-controlled (`chmod 600` on-device).
- Do not use `docker-compose.override.yml` in production.
- Keep production image tags explicit (`IMAGE_TAG`) so rollback is deterministic.
- Run deployment only after the preflight checks are passing and dependencies are reachable.
