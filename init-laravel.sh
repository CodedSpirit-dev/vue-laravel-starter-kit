#!/bin/bash
set -e

# --- CONFIGURACIÓN GENERAL ---
APP_DIR="/var/www/html"
LARAVEL_BIN="/root/.config/composer/vendor/bin/laravel"
export PATH="/root/.config/composer/vendor/bin:/root/.composer/vendor/bin:${PATH}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "🔧 Iniciando configuración de Laravel + Vue..."

cd "$APP_DIR"

# --- 1. Crear proyecto si no existe ---
if [ ! -f artisan ]; then
    log "📦 Laravel no encontrado. Creando proyecto nuevo..."

    # Limpia la carpeta solo si no está montada desde host (opcional)
    find "$APP_DIR" -mindepth 1 -not -name node_modules -exec rm -rf {} +

    # Instala Laravel installer si no existe
    if ! command -v laravel &> /dev/null; then
        log "⚙️  Laravel installer no encontrado. Instalando..."
        composer global require laravel/installer
    fi

    # Crear proyecto base
    laravel new . --force

    log "✅ Laravel creado correctamente."
fi

# --- 2. Instalar Jetstream (opcional) con Vue ---
if [ ! -d resources/js ]; then
    log "✨ Instalando Jetstream con Vue..."
    composer require laravel/jetstream
    php artisan jetstream:install vue
    npm install
    npm run build
fi

# --- 3. Instalar dependencias si faltan ---
if [ ! -d vendor ]; then
    log "📦 Instalando dependencias de Composer..."
    composer install --no-dev --optimize-autoloader
fi

# --- 4. Configurar permisos ---
log "🔐 Configurando permisos..."
chown -R www-data:www-data "$APP_DIR"
chmod -R 775 "$APP_DIR/storage" "$APP_DIR/bootstrap/cache"

# --- 5. Archivo .env y clave de app ---
if [ ! -f .env ]; then
    log "🧬 Creando archivo .env y clave de aplicación..."
    cp .env.example .env
    php artisan key:generate
fi

# --- 6. Configurar variables de base de datos ---
log "🛠️  Configurando .env para base de datos..."
sed -i "s/^DB_CONNECTION=.*/DB_CONNECTION=pgsql/" .env
sed -i "s/^DB_HOST=.*/DB_HOST=${DB_HOST}/" .env
sed -i "s/^DB_PORT=.*/DB_PORT=${DB_PORT}/" .env
sed -i "s/^DB_DATABASE=.*/DB_DATABASE=${DB_DATABASE}/" .env
sed -i "s/^DB_USERNAME=.*/DB_USERNAME=${DB_USERNAME}/" .env
sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=${DB_PASSWORD}/" .env

# Ejecutar migraciones
php artisan migrate

# --- 7. Esperar base de datos ---
log "⏳ Esperando conexión a la base de datos..."
until php artisan migrate:status &>/dev/null; do
    log "⏳ Aún sin conexión, reintentando..."
    sleep 2
done

# --- 8. Ejecutar migraciones ---
log "🚀 Ejecutando migraciones..."
php artisan migrate --force

# --- 9. Limpiar caché ---
log "🧹 Limpiando caché..."
php artisan config:clear
php artisan cache:clear
php artisan view:clear

# Permisos de Laravel
chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache

# Crear usuario adminUser::create([
php artisan tinker --execute="App\Models\User::factory()->create(
['name' => 'Admin User', 'email' => 'admin@example.com',
'password' => Hash::make('12345678')])"

php artisan tinker --execute="User::create([
    'name' => 'Admin User',
    'email' => 'admin@example.com',
    'password' => Hash::make('12345678')])"


# --- 10. Iniciar Apache ---
log "✅ Configuración completa. Iniciando Apache..."
exec apache2-foreground
