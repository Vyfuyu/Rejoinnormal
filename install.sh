#!/bin/sh
# ============================================================
#  ROBLOX AUTO REJOIN - One-liner Installer
#  Chạy với sh (luôn có sẵn trong Termux), không cần bash
#  curl -sSL https://raw.githubusercontent.com/Vyfuyu/Rejoinnormal/main/install.sh | sh
# ============================================================

REPO_RAW="https://raw.githubusercontent.com/Vyfuyu/Rejoinnormal/main"
INSTALL_DIR="$HOME/roblox-rejoin"
SCRIPT_NAME="roblox_rejoin.sh"
DEST="$INSTALL_DIR/$SCRIPT_NAME"
SHELL_RC="$HOME/.bashrc"

# Dùng printf thay echo -e cho tương thích sh
info()   { printf '\033[0;32m[INFO]\033[0m  %s\n' "$1"; }
warn()   { printf '\033[1;33m[WARN]\033[0m  %s\n' "$1"; }
error()  { printf '\033[0;31m[ERROR]\033[0m %s\n' "$1"; }
step()   { printf '\033[0;36m[%s]\033[0m %s\n' "$1" "$2"; }
bold()   { printf '\033[1m%s\033[0m\n' "$1"; }

clear

printf '\033[1m\033[35m'
printf '  ____       _     _            \n'
printf ' |  _ \ ___ | |__ | | _____  __\n'
printf ' | |_) / _ \| '"'"'_ \| |/ _ \ \/ /\n'
printf ' |  _ < (_) | |_) | | (_) >  < \n'
printf ' |_| \_\___/|_.__/|_|\___/_/\_\\n'
printf '  Auto Rejoin Installer - Termux Root\n'
printf '\033[0m\n'

bold "🔧 Bắt đầu cài đặt..."
printf '\n'

# ── Bước 1: Cài bash + gói cần thiết ──
step "1/4" "Cài bash, curl, termux-api..."
if ! pkg install -y bash curl termux-api 2>/dev/null; then
    warn "Một số gói cài không được, tiếp tục..."
fi
info "Gói đã cài xong"

# Xác nhận bash có ở đúng chỗ không
BASH_BIN="/data/data/com.termux/files/usr/bin/bash"
if [ ! -f "$BASH_BIN" ]; then
    BASH_BIN="$(command -v bash 2>/dev/null || true)"
fi
if [ -z "$BASH_BIN" ]; then
    error "Không tìm thấy bash sau khi cài! Thử: pkg install bash"
    exit 1
fi
info "bash OK: $BASH_BIN"

# ── Bước 2: Tạo thư mục ──
printf '\n'
step "2/4" "Tạo thư mục $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
info "$INSTALL_DIR OK"

# ── Bước 3: Download script chính ──
printf '\n'
step "3/4" "Tải script từ GitHub..."
if curl -fsSL "${REPO_RAW}/${SCRIPT_NAME}" -o "$DEST"; then
    # Sửa shebang cho đúng path bash trên máy này
    sed -i "1s|.*|#!${BASH_BIN}|" "$DEST"
    chmod +x "$DEST"
    info "Đã tải: $DEST"
else
    error "Tải thất bại! Kiểm tra kết nối mạng."
    exit 1
fi

# ── Bước 4: Tạo alias nhanh ──
printf '\n'
step "4/4" "Tạo lệnh nhanh 'rbjoin'..."
ALIAS_LINE="alias rbjoin='su -c \"${BASH_BIN} ${DEST}\"'"
if grep -q "alias rbjoin=" "$SHELL_RC" 2>/dev/null; then
    sed -i "s|alias rbjoin=.*|${ALIAS_LINE}|" "$SHELL_RC"
else
    printf '\n# Roblox Auto Rejoin\n%s\n' "${ALIAS_LINE}" >> "$SHELL_RC"
fi
info "Alias 'rbjoin' đã thêm vào $SHELL_RC"

# ── Hoàn tất ──
printf '\n'
printf '\033[1m\033[32m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m\n'
printf '\033[1m\033[32m  ✅ CÀI ĐẶT HOÀN TẤT!\033[0m\n'
printf '\033[1m\033[32m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m\n'
printf '\n'
printf '\033[1;33m  Chạy ngay:\033[0m\n'
printf '  su -c "%s %s"\n' "$BASH_BIN" "$DEST"
printf '\n'
printf '\033[1;33m  Hoặc dùng alias (mở lại Termux):\033[0m\n'
printf '  rbjoin\n'
printf '\n'

printf '▶ Chạy Roblox Auto Rejoin ngay bây giờ? (y/n): '
read -r RUN_NOW
if [ "$RUN_NOW" = "y" ] || [ "$RUN_NOW" = "Y" ]; then
    printf '\n'
    su -c "$BASH_BIN $DEST"
fi
