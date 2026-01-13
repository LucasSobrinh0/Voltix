FROM composer:2 AS vendor
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --prefer-dist --no-interaction --no-progress --no-scripts

FROM node:20 AS frontend
WORKDIR /app
COPY package.json package-lock.json* yarn.lock* pnpm-lock.yaml* ./
RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi
COPY . .
RUN npm run build && test -f public/build/manifest.json

FROM php:8.4-fpm-alpine

RUN apk add --no-cache nginx bash postgresql-dev icu-dev oniguruma-dev libzip-dev \
 && docker-php-ext-install pdo_pgsql intl mbstring zip opcache

WORKDIR /var/www/html
COPY . .
COPY --from=vendor /app/vendor ./vendor
COPY --from=frontend /app/public/build ./public/build
COPY --from=frontend /app/public/build/manifest.json ./public/build/manifest.json


COPY nginx.conf /etc/nginx/http.d/default.conf
COPY start.sh /start.sh
RUN chmod +x /start.sh \
 && mkdir -p /run/nginx \
 && chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

EXPOSE 80
CMD ["/start.sh"]