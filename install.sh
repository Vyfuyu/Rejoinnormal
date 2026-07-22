#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  ROBLOX AUTO REJOIN - One-liner Installer
#  curl -sSL https://raw.githubusercontent.com/Vyfuyu/Rejoinnormal/main/install.sh | bash
# ============================================================

REPO_RAW="https://raw.githubusercontent.com/Vyfuyu/Rejoinnormal/main"
INSTALL_DIR="$HOME/roblox-rejoin"
SCRIPT_NAME="roblox_rejoin.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

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

# ── Bước 1: Cài bash + gói cần thiết ──
echo -e "${CYAN}[1/4]${RESET} Cài bash và các gói cần thiết..."
pkg install -y bash curl termux-api ncurses-utils 2>/dev/null || true
echo -e "  ${GREEN}✓ Gói đã cài${RESET}"

# ── Bước 2: Tạo thư mục ──
echo -e "\n${CYAN}[2/4]${RESET} Tạo thư mục $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
echo -e "  ${GREEN}✓ $INSTALL_DIR${RESET}"

# ── Bước 3: Download script ──
echo -e "\n${CYAN}[3/4]${RESET} Tải script từ GitHub..."
DEST="$INSTALL_DIR/$SCRIPT_NAME"

if curl -fsSL "${REPO_RAW}/${SCRIPT_NAME}" -o "$DEST"; then
    chmod +x "$DEST"
    echo -e "  ${GREEN}✓ Đã tải: $DEST${RESET}"
else
    echo -e "  ${RED}✗ Tải thất bại! Kiểm tra kết nối mạng.${RESET}"
    exit 1
fi

# ── Bước 4: Tạo alias nhanh ──
echo -e "\n${CYAN}[4/4]${RESET} Tạo lệnh nhanh 'rbjoin'..."
SHELL_RC="$HOME/.bashrc"
ALIAS_LINE="alias rbjoin='su -c \"bash ${DEST}\"'"

if grep -q "alias rbjoin=" "$SHELL_RC" 2>/dev/null; then
    sed -i "s|alias rbjoin=.*|${ALIAS_LINE}|" "$SHELL_RC"
else
    echo "" >> "$SHELL_RC"
    echo "# Roblox Auto Rejoin" >> "$SHELL_RC"
    echo "${ALIAS_LINE}" >> "$SHELL_RC"
fi
echo -e "  ${GREEN}✓ Alias 'rbjoin' đã thêm vào $SHELL_RC${RESET}"

# ── Hoàn tất ──
echo -e "\n${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}${GREEN}  ✅ CÀI ĐẶT HOÀN TẤT!${RESET}"
echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "  ${YELLOW}Chạy ngay:${RESET}"
echo -e "  su -c \"bash ${DEST}\""
echo ""
echo -e "  ${YELLOW}Hoặc dùng alias (sau khi mở lại Termux):${RESET}"
echo -e "  rbjoin"
echo ""

read -rp "▶ Chạy Roblox Auto Rejoin ngay bây giờ? (y/n): " RUN_NOW
if [ "$RUN_NOW" = "y" ] || [ "$RUN_NOW" = "Y" ]; then
    echo ""
    su -c "bash $DEST"
fi
