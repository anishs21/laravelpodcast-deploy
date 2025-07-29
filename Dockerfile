# Build Stage
FROM php:7.4-fpm AS build

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip curl git zip libzip-dev libpng-dev libjpeg-dev libonig-dev libxml2-dev build-essential \
    && docker-php-ext-configure gd --with-jpeg \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip \
    && rm -rf /var/lib/apt/lists/*

# Copy Composer from official Composer image
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www

# Copy all source code
COPY . .

# Ensure .env exists
COPY .env.example .env

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --prefer-dist

# Laravel setup: cache config, route, view
RUN php artisan config:clear \
 && php artisan config:cache \
 && php artisan route:cache \
 && php artisan view:cache

# Fix permissions
RUN chown -R www-data:www-data /var/www \
 && chmod -R 775 storage bootstrap/cache

# Final Stage (runtime only)
FROM php:7.4-fpm-alpine

# Install runtime dependencies using apk (lightweight)
RUN apk add --no-cache \
    libzip-dev libpng-dev libjpeg-turbo-dev oniguruma-dev libxml2-dev \
    && docker-php-ext-configure gd --with-jpeg \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip

# Set working directory
WORKDIR /var/www

# Copy app from build stage
COPY --from=build /var/www /var/www

# Set permissions
RUN chown -R www-data:www-data /var/www \
 && chmod -R 775 /var/www/storage /var/www/bootstrap/cache

# Use non-root user
USER www-data

# Run Laravel app
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
