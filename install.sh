#!/bin/bash
# ============================================================
#  ROBLOX AUTO REJOIN - One-liner Installer
#  curl -sSL https://raw.githubusercontent.com/Vyfuyu/Rejoinnormal/main/install.sh | bash
# ============================================================

set -e

REPO_RAW="https://raw.githubusercontent.com/Vyfuyu/Rejoinnormal/main"
INSTALL_DIR="$HOME/roblox-rejoin"
SCRIPT_NAME="roblox_rejoin.sh"

# Màu sắc
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

clear
echo -e "${BOLD}${CYAN}"
cat << 'EOF'
  ____       _     _            
 |  _ \ ___ | |__ | | _____  __
 | |_) / _ \| '_ \| |/ _ \ \/ /
 |  _ < (_) | |_) | | (_) >  < 
 |_| \_\___/|_.__/|_|\___/_/\_\
  Auto Rejoin Installer - Termux Root
EOF
echo -e "${RESET}"

echo -e "${BOLD}🔧 Bắt đầu cài đặt...${RESET}\n"

# ── Bước 1: Kiểm tra môi trường ──
echo -e "${CYAN}[1/5]${RESET} Kiểm tra môi trường..."

if ! command -v curl &>/dev/null && ! command -v wget &>/dev/null; then
    echo -e "${RED}✗ Cần cài curl hoặc wget trước:${RESET}"
    echo -e "    pkg install curl"
    exit 1
fi
echo -e "  ${GREEN}✓ curl/wget OK${RESET}"

# ── Bước 2: Cài gói cần thiết ──
echo -e "\n${CYAN}[2/5]${RESET} Cài gói cần thiết (termux-api, ncurses-utils)..."
if command -v pkg &>/dev/null; then
    pkg install -y termux-api ncurses-utils 2>/dev/null || true
    echo -e "  ${GREEN}✓ Gói đã cài (hoặc đã có sẵn)${RESET}"
else
    echo -e "  ${YELLOW}⚠ Không phải Termux, bỏ qua bước này${RESET}"
fi

# ── Bước 3: Tạo thư mục cài đặt ──
echo -e "\n${CYAN}[3/5]${RESET} Tạo thư mục $INSTALL_DIR ..."
mkdir -p "$INSTALL_DIR"
echo -e "  ${GREEN}✓ $INSTALL_DIR${RESET}"

# ── Bước 4: Download script chính ──
echo -e "\n${CYAN}[4/5]${RESET} Đang tải script từ GitHub..."

SCRIPT_URL="$REPO_RAW/$SCRIPT_NAME"
DEST="$INSTALL_DIR/$SCRIPT_NAME"

if command -v curl &>/dev/null; then
    curl -sSL "$SCRIPT_URL" -o "$DEST"
else
    wget -q "$SCRIPT_URL" -O "$DEST"
fi

chmod +x "$DEST"
echo -e "  ${GREEN}✓ Đã tải: $DEST${RESET}"

# ── Bước 5: Tạo alias lệnh nhanh ──
echo -e "\n${CYAN}[5/5]${RESET} Tạo lệnh nhanh 'rbjoin'..."

SHELL_RC="$HOME/.bashrc"
[ -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.zshrc"

ALIAS_LINE="alias rbjoin='su -c \"bash $DEST\"'"

if grep -q "alias rbjoin=" "$SHELL_RC" 2>/dev/null; then
    sed -i "s|alias rbjoin=.*|$ALIAS_LINE|" "$SHELL_RC"
else
    echo "" >> "$SHELL_RC"
    echo "# Roblox Auto Rejoin" >> "$SHELL_RC"
    echo "$ALIAS_LINE" >> "$SHELL_RC"
fi

echo -e "  ${GREEN}✓ Alias 'rbjoin' đã được thêm vào $SHELL_RC${RESET}"

# ── Hoàn tất ──
echo -e "\n${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}${GREEN}  ✅ CÀI ĐẶT HOÀN TẤT!${RESET}"
echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "${BOLD}Cách chạy:${RESET}"
echo -e "  ${YELLOW}# Chạy ngay bây giờ:${RESET}"
echo -e "  su -c \"bash $DEST\""
echo ""
echo -e "  ${YELLOW}# Hoặc dùng alias sau khi reload shell:${RESET}"
echo -e "  source $SHELL_RC && rbjoin"
echo ""
echo -e "  ${YELLOW}# File script:${RESET} $DEST"
echo -e "  ${YELLOW}# Log file:${RESET}    ~/roblox_rejoin.log"
echo ""

# Hỏi có muốn chạy ngay không
read -rp "▶ Chạy Roblox Auto Rejoin ngay bây giờ? (y/n): " RUN_NOW
if [[ "$RUN_NOW" =~ ^[Yy]$ ]]; then
    echo ""
    su -c "bash $DEST"
fi
