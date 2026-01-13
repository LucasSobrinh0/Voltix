#!/bin/sh
set -e

cd /var/www/html

php artisan config:clear || true
php artisan cache:clear || true
php artisan view:clear || true

mkdir -p storage/framework/cache storage/framework/sessions storage/framework/views
chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache

php artisan package:discover --ansi
php artisan config:cache

php artisan migrate --force || true

php-fpm -D
exec nginx -g "daemon off;"