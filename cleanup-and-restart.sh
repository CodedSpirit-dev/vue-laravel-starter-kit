#!/bin/bash

echo "🧹 Limpiando configuración de Docker..."

# Parar todos los contenedores
docker-compose down

# Eliminar volúmenes (esto borra la base de datos!)
echo "⚠️  Eliminando volúmenes de base de datos..."
docker-compose down -v

# Eliminar imágenes para forzar rebuild
echo "🗑️  Eliminando imágenes..."
docker rmi $(docker images "laravel_vue*" -q) 2>/dev/null || true

# Limpiar directorio src si existe
if [ -d "./src" ]; then
    echo "🗂️  Limpiando directorio src..."
    sudo rm -rf ./src/*
    sudo rm -rf ./src/.[^.]*
fi

echo "✨ Limpieza completada. Construyendo desde cero..."

# Construir y ejecutar
docker-compose up --build

echo "🚀 Configuración completada!"
echo ""
echo "Accede a:"
echo "  Laravel: http://localhost:8000"
echo "  Vite:    http://localhost:5173"
echo "  DB:      localhost:5435"