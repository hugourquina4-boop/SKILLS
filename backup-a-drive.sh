#!/bin/bash
# ============================================================
# BACKUP A GOOGLE DRIVE — Mi Stack Claude Code
# Sube una copia de seguridad completa a tu Google Drive
#
# REQUISITOS:
#   1. tener clasp instalado: npm install -g @google/clasp
#   2. Haber autenticado: clasp login
#   3. Tener rclone instalado para subir a Drive
#      (alternativa: subir el ZIP manualmente)
# ============================================================

FECHA=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/tmp/backup-claude-$FECHA"
ZIP_NAME="backup-claude-code-$FECHA.zip"

echo "Creando backup de tu stack Claude Code..."
mkdir -p "$BACKUP_DIR"

# Copiar configuracion de Claude Code
cp -r ~/.claude.json "$BACKUP_DIR/" 2>/dev/null || true
cp -r ~/.claude/settings.json "$BACKUP_DIR/" 2>/dev/null || true

# Copiar el repositorio de skills (sin node_modules ni .git)
echo "Empaquetando skills y agentes..."
rsync -av --exclude='.git' --exclude='node_modules' --exclude='.claude-flow/logs' \
  /home/user/SKILLS/ "$BACKUP_DIR/SKILLS/" 2>/dev/null || \
cp -r /home/user/SKILLS "$BACKUP_DIR/SKILLS"

# Incluir el script de instalacion
cp /home/user/SKILLS/install-todo-mi-stack.sh "$BACKUP_DIR/"

# Crear ZIP
cd /tmp
zip -r "$ZIP_NAME" "backup-claude-$FECHA/" -q
echo "ZIP creado: /tmp/$ZIP_NAME"

# ------------------------------------------------------------
# OPCION A: Subir con rclone (si esta instalado)
# ------------------------------------------------------------
if command -v rclone &> /dev/null; then
  echo "Subiendo a Google Drive con rclone..."
  # ID de la carpeta de Drive del usuario
  DRIVE_FOLDER="1l0YOiLA5x7sFX2KJ69VfmfSYdesPjKfW"
  rclone copy "/tmp/$ZIP_NAME" "gdrive:backup-claude/" --drive-root-folder-id="$DRIVE_FOLDER"
  echo "✓ Backup subido a Google Drive"
else
  echo ""
  echo "╔══════════════════════════════════════════════╗"
  echo "║  BACKUP LISTO — Sube manualmente a Drive     ║"
  echo "╠══════════════════════════════════════════════╣"
  echo "║  Archivo: /tmp/$ZIP_NAME"
  echo "║                                              ║"
  echo "║  Para subida automatica instala rclone:      ║"
  echo "║  https://rclone.org/install/                 ║"
  echo "║  Luego: rclone config (selecciona Google)    ║"
  echo "╚══════════════════════════════════════════════╝"
fi

# Limpiar temp
rm -rf "$BACKUP_DIR"
echo "Backup completado: $ZIP_NAME"
