# Usa la imagen oficial de PHP con Apache
FROM php:8.3-apache

# Instala dependencias del sistema
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    libpq-dev \
    libzip-dev \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    nodejs \
    npm \
    && docker-php-ext-install pdo pdo_pgsql zip gd mbstring bcmath xml \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Instala Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Instala Laravel installer globalmente
RUN composer global require laravel/installer


# Agregar el directorio de Composer al PATH de forma permanente
ENV PATH="/root/.config/composer/vendor/bin:/root/.composer/vendor/bin:${PATH}"

# Verificar que laravel esté disponible
RUN which laravel || echo "Laravel installer not in PATH"

# Configura Apache para Laravel
RUN a2enmod rewrite
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Establece el directorio de trabajo
WORKDIR /var/www/html

# Script de inicialización
COPY init-laravel.sh /usr/local/bin/init-laravel.sh
RUN chmod +x /usr/local/bin/init-laravel.sh

# Expone el puerto de Apache
EXPOSE 80

RUN npm i -g pnpm@9

# Comando para inicializar Laravel si no existe
CMD ["/usr/local/bin/init-laravel.sh"]