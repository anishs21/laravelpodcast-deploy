# Build Stage
FROM php:7.4-fpm AS build

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip curl git zip libzip-dev libpng-dev libjpeg-dev libonig-dev libxml2-dev build-essential \
    && docker-php-ext-configure gd --with-jpeg \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip \
    && rm -rf /var/lib/apt/lists/*

# Copy Composer from official image
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www

# Copy application files
COPY . .

# Ensure essential directories exist
RUN mkdir -p storage/logs bootstrap/cache

# Copy .env if not already present
COPY .env.example .env

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --prefer-dist

# Generate app key
RUN php artisan key:generate

# Cache config, route, and views
RUN php artisan config:clear && \
    php artisan config:cache && \
   # php artisan route:cache && \
    php artisan view:cache

# Set permissions
RUN chown -R www-data:www-data /var/www && \
    chmod -R 775 storage bootstrap/cache

# Final Runtime Stage
FROM php:7.4-fpm-alpine

# Install runtime dependencies
RUN apk add --no-cache \
    libzip-dev libpng-dev libjpeg-turbo-dev oniguruma-dev libxml2-dev \
    && docker-php-ext-configure gd --with-jpeg \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip

# Set working directory
WORKDIR /var/www

# Copy app from build stage
COPY --from=build /var/www /var/www

# Ensure log/cache dirs exist in runtime
RUN mkdir -p storage/logs bootstrap/cache && \
    chown -R www-data:www-data storage bootstrap/cache && \
    chmod -R 775 storage bootstrap/cache

# Set correct ownership
RUN chown -R www-data:www-data /var/www

# Run container as non-root
USER www-data

# Start Laravel development server
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
