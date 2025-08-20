# Documentación de Setup: Laravel + Vue + Inertia + Vite + Docker (WSL2 Compatible)

Este documento describe paso a paso cómo crear un entorno de desarrollo moderno utilizando Laravel con Vue (Inertia.js), Vite, Docker y WSL2, incluyendo configuraciones para permisos, hot module reload y problemas comunes solucionados.

---

## 1. Requisitos previos

* Docker Desktop (con WSL2 habilitado)
* WSL2 con Ubuntu (o distro Linux)
* Composer instalado en WSL
* Node.js y npm instalados

---

## 2. Estructura base del proyecto

```
project-root/
├── docker-compose.yml
├── Dockerfile
├── init-laravel.sh
├── fix-permissions.sh
└── src/              # Proyecto Laravel se crea aquí
```

---

## 3. Crear el proyecto Laravel localmente

```bash
cd project-root
mkdir src && cd src
composer create-project laravel/laravel . --prefer-dist
```

Agregar Jetstream + Vue (opcional):

```bash
composer require laravel/jetstream
php artisan jetstream:install vue
npm install && npm run build
```

Copiar archivo .env y generar clave:

```bash
cp .env.example .env
php artisan key:generate
```

---

## 4. Vite config con HMR para Docker

Archivo `vite.config.ts`:

```ts
import vue from '@vitejs/plugin-vue';
import laravel from 'laravel-vite-plugin';
import tailwindcss from '@tailwindcss/vite';
import { defineConfig } from 'vite';

export default defineConfig({
    server: {
        host: 'localhost',
        port: 5173,
        strictPort: true,
        hmr: {
            host: 'localhost',
        },
    },
    plugins: [
        laravel({
            input: ['resources/js/app.ts'],
            ssr: 'resources/js/ssr.ts',
            refresh: true,
        }),
        tailwindcss(),
        vue({
            template: {
                transformAssetUrls: {
                    base: null,
                    includeAbsolute: false,
                },
            },
        }),
    ],
});
```

---

## 5. Docker: archivos clave

### `Dockerfile`

Basado en `php:8.3-apache`, con soporte para PostgreSQL, Node, Composer, Laravel Installer. Se expone Apache en `:80`.

### `docker-compose.yml`

```yaml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: laravel_vue_app
    volumes:
      - ./src:/var/www/html
      - laravel_node_modules:/var/www/html/node_modules
    ports:
      - "8000:80"
    environment:
      - DB_HOST=db
      - DB_PORT=5432
      - DB_DATABASE=data_entry
      - DB_USERNAME=postgres
      - DB_PASSWORD=postgres
    depends_on:
      - db
    networks:
      - app-network

  db:
    image: postgres:17
    container_name: laravel_vue_db
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: data_entry
    ports:
      - "5435:5432"
    volumes:
      - db_data:/var/lib/postgresql/data
    networks:
      - app-network

  vite:
    image: node:20-alpine
    container_name: laravel_vue_vite
    working_dir: /var/www/html
    volumes:
      - ./src:/var/www/html
      - vite_node_modules:/var/www/html/node_modules
    ports:
      - "5173:5173"
    command: >
      sh -c "while [ ! -f package.json ]; do echo '⏳ Esperando package.json...'; sleep 2; done && npm install && npm run dev"
    depends_on:
      - app
    networks:
      - app-network

volumes:
  db_data:
  laravel_node_modules:
  vite_node_modules:

networks:
  app-network:
    driver: bridge
```

---

## 6. Script de inicialización Laravel

### `init-laravel.sh` (fragmento final)

```bash
# Permisos de Laravel
chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache

# Migraciones y limpieza
php artisan migrate --force
php artisan config:clear
php artisan cache:clear
php artisan view:clear

exec apache2-foreground
```

---

## 7. Corrección de permisos desde el host

### `fix-permissions.sh`

```bash
#!/bin/bash

PROJECT_DIR="./src"
USER_ID=$(id -u)
GROUP_ID=$(id -g)

echo "🔧 Corrigiendo permisos en $PROJECT_DIR..."

chown -R $USER_ID:$GROUP_ID $PROJECT_DIR || echo "⚠️  No se pudo cambiar el dueño (volumen montado?)"
chmod -R ug+rwX $PROJECT_DIR/storage $PROJECT_DIR/bootstrap/cache
chmod -R ug+rwX $PROJECT_DIR/node_modules || true

echo "✅ Permisos corregidos."
```

---

## 8. Variables importantes en `.env`

```env
APP_URL=http://localhost
ASSET_URL=http://localhost:5173
VITE_PORT=5173
DB_CONNECTION=pgsql
DB_HOST=db
DB_PORT=5432
DB_DATABASE=data_entry
DB_USERNAME=postgres
DB_PASSWORD=postgres
```

---

## 9. Crear un usuario manual (si no tienes frontend de registro)

```bash
php artisan tinker

User::create([
    'name' => 'Victor Verdeja',
    'email' => 'victor@example.com',
    'password' => Hash::make('12345678'),
]);
```

---

## 10. Comandos de desarrollo rápido

```bash
./fix-permissions.sh
npm install
npm run dev

# Lanzar stack
docker compose up --build

# Acceder a Laravel
http://localhost:8000

# Acceder a Vite (debug)
http://localhost:5173
```

---

## ✅ Resultado esperado

* Laravel funcional en `localhost:8000`
* Vite con HMR funcionando desde `localhost:5173`
* Vue montado vía Inertia
* Migraciones aplicadas
* Permisos resueltos incluso en WSL2
* Cero errores de CORS, chown, o `0B` en scripts

---

## 🧠 Recomendado

* Agrega `.vscode/settings.json` para formateo, paths y compatibilidad de entornos
* Usar `make dev` o `npm run sail` para automatizar flujo dev en el futuro
