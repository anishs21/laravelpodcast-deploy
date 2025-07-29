# Build Stage
FROM php:7.4-fpm AS build

# Install build dependencies (use --no-install-recommends for apt to reduce size)
RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip curl git zip libzip-dev libpng-dev libjpeg-dev libonig-dev libxml2-dev build-essential \
    && docker-php-ext-configure gd --with-jpeg \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

RUN composer install --no-dev --optimize-autoloader --prefer-dist

COPY . .

# Fix permissions
RUN chown -R www-data:www-data /var/www

# Final Stage
FROM php:7.4-fpm-alpine

# Install runtime dependencies using apk (Alpine)
RUN apk add --no-cache \
    libzip-dev libpng-dev libjpeg-turbo-dev oniguruma-dev libxml2-dev \
    && docker-php-ext-configure gd --with-jpeg \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip

WORKDIR /var/www

COPY --from=build /var/www /var/www

# Set proper permissions
RUN chown -R www-data:www-data /var/www

USER www-data

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
