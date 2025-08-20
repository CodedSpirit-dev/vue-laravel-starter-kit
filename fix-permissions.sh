#!/bin/bash

# Corrige permisos de un proyecto Laravel + Vite en WSL/Linux

set -e  # Salir si hay un error
set -u  # Error si se usan variables no definidas

# === Configuración ===
PROJECT_DIR="./src"
USER_ID=$(id -u)
GROUP_ID=$(id -g)

YELLOW='\033[1;33m'
GREEN='\033[1;32m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🔧 Corrigiendo permisos en $PROJECT_DIR...${NC}"

# Verifica existencia del directorio
if [ ! -d "$PROJECT_DIR" ]; then
  echo -e "${RED}❌ El directorio $PROJECT_DIR no existe.${NC}"
  exit 1
fi

# Cambia propiedad completa al usuario actual (si se puede)
echo -e "⏳ Asignando dueño a UID $USER_ID en $PROJECT_DIR..."
chown -R $USER_ID:$GROUP_ID "$PROJECT_DIR" || echo -e "${YELLOW}⚠️  No se pudo cambiar el propietario (probablemente volumen montado desde Windows).${NC}"

# Da permisos solo a carpetas necesarias
for dir in "$PROJECT_DIR/storage" "$PROJECT_DIR/bootstrap/cache"; do
  if [ -d "$dir" ]; then
    chmod -R ug+rwX "$dir"
    echo -e "✅ Permisos corregidos en $dir"
  else
    echo -e "${YELLOW}⚠️  $dir no existe, omitido.${NC}"
  fi
done

# Permisos para node_modules (solo si existe)
NODE_MODULES="$PROJECT_DIR/node_modules"
if [ -d "$NODE_MODULES" ]; then
  chmod -R ug+rwX "$NODE_MODULES"
  echo -e "✅ Permisos corregidos en node_modules"
fi

echo -e "${GREEN}🎉 Todos los permisos han sido corregidos correctamente.${NC}"
