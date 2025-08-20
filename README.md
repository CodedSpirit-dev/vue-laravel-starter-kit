# Setup Documentation: Laravel + Vue + Inertia + Vite + Docker (WSL2 Compatible)

This document describes step-by-step how to create a modern development environment using Laravel with Vue (Inertia.js), Vite, Docker, and WSL2, including configurations for permissions, hot module reload, and common issues resolved.

---

## 1. Prerequisites

* Docker Desktop (with WSL2 enabled)
* WSL2 with Ubuntu (or other Linux distro)
* Composer installed in WSL
* Node.js and npm installed

---

## 2. Base Project Structure

```
project-root/
├── docker-compose.yml
├── Dockerfile
├── init-laravel.sh
├── fix-permissions.sh
└── src/              # Laravel project is created here
```

---

## 3. Create Laravel Project Locally

```bash
cd project-root
mkdir src && cd src
composer create-project laravel/laravel . --prefer-dist
```

Add Jetstream + Vue (optional):

```bash
composer require laravel/jetstream
php artisan jetstream:install vue
npm install && npm run build
```

Copy the `.env` file and generate the key:

```bash
cp .env.example .env
php artisan key:generate
```

---

## 4. Vite Config with HMR for Docker

`vite.config.ts`:

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

## 5. Docker: Key Files

### `Dockerfile`

Based on `php:8.3-apache`, with support for PostgreSQL, Node, Composer, Laravel Installer. Exposes Apache on port `:80`.

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
      sh -c "while [ ! -f package.json ]; do echo '⏳ Waiting for package.json...'; sleep 2; done && npm install && npm run dev"
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

## 6. Laravel Initialization Script

### `init-laravel.sh` (final fragment)

```bash
# Laravel permissions
chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache

# Migrations and cleanup
php artisan migrate --force
php artisan config:clear
php artisan cache:clear
php artisan view:clear

exec apache2-foreground
```

---

## 7. Fix Permissions from Host

### `fix-permissions.sh`

```bash
#!/bin/bash

PROJECT_DIR="./src"
USER_ID=$(id -u)
GROUP_ID=$(id -g)

echo "🔧 Fixing permissions in $PROJECT_DIR..."

chown -R $USER_ID:$GROUP_ID $PROJECT_DIR || echo "⚠️  Could not change owner (mounted volume?)"
chmod -R ug+rwX $PROJECT_DIR/storage $PROJECT_DIR/bootstrap/cache
chmod -R ug+rwX $PROJECT_DIR/node_modules || true

echo "✅ Permissions fixed."
```

---

## 8. Important Variables in `.env`

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

## 9. Create a User Manually (if no registration frontend)

```bash
php artisan tinker

User::create([
    'name' => 'Victor Verdeja',
    'email' => 'victor@example.com',
    'password' => Hash::make('12345678'),
]);
```

---

## 10. Quick Development Commands

```bash
./fix-permissions.sh
npm install
npm run dev

# Launch stack
docker compose up --build

# Access Laravel
http://localhost:8000

# Access Vite (debug)
http://localhost:5173
```

---

## ✅ Expected Result

* Laravel running at `localhost:8000`
* Vite with HMR running at `localhost:5173`
* Vue mounted via Inertia
* Migrations applied
* Permissions resolved even in WSL2
* Zero errors from CORS, `chown`, or empty scripts

---

## 🧠 Recommended

* Add `.vscode/settings.json` for formatting, paths, and environment compatibility
* Use `make dev` or `npm run sail` to automate the dev workflow in the future
