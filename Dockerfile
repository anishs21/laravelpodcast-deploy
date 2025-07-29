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

# Copy source code before running Composer
COPY . .

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --prefer-dist

# Set permissions
RUN chown -R www-data:www-data /var/www

# Final Stage
FROM php:7.4-fpm-alpine

# Install runtime dependencies using apk (lightweight)
RUN apk add --no-cache \
    libzip-dev libpng-dev libjpeg-turbo-dev oniguruma-dev libxml2-dev \
    && docker-php-ext-configure gd --with-jpeg \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip

# Set working directory
WORKDIR /var/www

# Copy application from build stage
COPY --from=build /var/www /var/www

# Set correct ownership
RUN chown -R www-data:www-data /var/www

# Run container as non-root
USER www-data

# Start Laravel development server
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
