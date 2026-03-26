#!/bin/bash
# ============================================================
# INSTALACION AUTOMATICA — Mi Stack Claude Code Completo
# Ejecutar en cualquier maquina nueva con:
#   bash install-todo-mi-stack.sh
# ============================================================

set -e
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════╗"
echo "║     INSTALACION AUTOMATICA DE MI STACK       ║"
echo "║         Claude Code + MCP Servers            ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"

# ------------------------------------------------------------
# 1. VERIFICAR PREREQUISITOS
# ------------------------------------------------------------
echo -e "${YELLOW}[1/5] Verificando prerequisitos...${NC}"

if ! command -v node &> /dev/null; then
  echo "Node.js no encontrado. Instalando via nvm..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
  source ~/.bashrc
  nvm install 22
  nvm use 22
else
  echo "Node.js: $(node --version) ✓"
fi

if ! command -v claude &> /dev/null; then
  echo "Claude Code no encontrado. Instalando..."
  # En Mac/Linux:
  npm install -g @anthropic-ai/claude-code 2>/dev/null || \
  curl -fsSL https://claude.ai/install.sh | bash
else
  echo "Claude Code: $(claude --version) ✓"
fi

# ------------------------------------------------------------
# 2. INSTALAR CLIs GLOBALES
# ------------------------------------------------------------
echo -e "${YELLOW}[2/5] Instalando CLIs globales...${NC}"

npm install -g @google/clasp && echo "clasp ✓"

# ------------------------------------------------------------
# 3. INSTALAR MCP SERVERS
# ------------------------------------------------------------
echo -e "${YELLOW}[3/5] Instalando MCP Servers en Claude Code...${NC}"

# Detectar directorio del proyecto
PROJECT_DIR="$(pwd)"

# Agregar todos los MCP servers
claude mcp add ruflo    -- npx ruflo@latest mcp start   && echo "ruflo MCP ✓"
claude mcp add remotion -- npx @remotion/mcp             && echo "remotion MCP ✓"
claude mcp add expo     -- npx expo-mcp                  && echo "expo MCP ✓"
claude mcp add whatsapp -- npx whatsapp-mcp              && echo "whatsapp MCP ✓"
claude mcp add playwright -- npx @playwright/mcp         && echo "playwright MCP ✓"
claude mcp add pdf      -- npx mcp-pdf                   && echo "pdf MCP ✓"

# ------------------------------------------------------------
# 4. INICIALIZAR RUFLO (98 agentes + 30 skills)
# ------------------------------------------------------------
echo -e "${YELLOW}[4/5] Inicializando RuFlo V3...${NC}"
npx ruflo@latest init --wizard 2>/dev/null && echo "RuFlo inicializado ✓" || echo "RuFlo ya inicializado"

# ------------------------------------------------------------
# 5. RESTAURAR MIS SKILLS Y AGENTES PERSONALIZADOS
# ------------------------------------------------------------
echo -e "${YELLOW}[5/5] Restaurando skills y agentes personalizados...${NC}"

# Clonar el repositorio de skills si no existe
SKILLS_DIR="$HOME/.claude/skills/mis-skills"
if [ ! -d "$SKILLS_DIR" ]; then
  mkdir -p "$SKILLS_DIR"
fi

# Descargar skills de obra/superpowers
SUPERPOWERS_SKILLS=(
  brainstorming dispatching-parallel-agents executing-plans
  finishing-a-development-branch receiving-code-review requesting-code-review
  subagent-driven-development systematic-debugging test-driven-development
  using-git-worktrees using-superpowers verification-before-completion
  writing-plans writing-skills
)

echo "Instalando 14 skills de obra/superpowers..."
for skill in "${SUPERPOWERS_SKILLS[@]}"; do
  dest="$HOME/.claude/skills/superpowers-${skill}"
  mkdir -p "$dest"
  curl -fsSL "https://raw.githubusercontent.com/obra/superpowers/main/skills/${skill}/SKILL.md" \
    -o "$dest/SKILL.md" 2>/dev/null && echo "  ✓ superpowers-$skill" || echo "  ✗ superpowers-$skill (error)"
done

# Instalar humanizalo
echo "Instalando humanizalo..."
git clone https://github.com/Hainrixz/humanizalo.git /tmp/humanizalo 2>/dev/null || true
rm -rf /tmp/humanizalo/.git
cp -r /tmp/humanizalo "$HOME/.claude/skills/humanizalo"
echo "  ✓ humanizalo"

# Instalar UI UX Pro Max
echo "Instalando ui-ux-pro-max..."
git clone --branch dev https://github.com/Angel1104/ui-ux-pro-max-skill.git /tmp/ui-ux-pro-max 2>/dev/null || true
rm -rf /tmp/ui-ux-pro-max/.git
cp -r /tmp/ui-ux-pro-max "$HOME/.claude/skills/ui-ux-pro-max"
echo "  ✓ ui-ux-pro-max"

# ------------------------------------------------------------
# RESUMEN FINAL
# ------------------------------------------------------------
echo ""
echo -e "${GREEN}"
echo "╔══════════════════════════════════════════════╗"
echo "║         INSTALACION COMPLETADA ✓             ║"
echo "╠══════════════════════════════════════════════╣"
echo "║  MCP Servers: ruflo, remotion, expo,         ║"
echo "║               whatsapp, playwright, pdf      ║"
echo "║  Skills: 14 superpowers + humanizalo +       ║"
echo "║          ui-ux-pro-max + ruflo (98 agentes)  ║"
echo "║  CLIs: @google/clasp                         ║"
echo "╠══════════════════════════════════════════════╣"
echo "║  Siguiente paso: ejecutar 'claude' para      ║"
echo "║  iniciar Claude Code con todo activo         ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"
