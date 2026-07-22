#!/bin/sh
# ============================================================
#  ROBLOX AUTO REJOIN - One-liner Installer
#  curl -sSL https://raw.githubusercontent.com/Vyfuyu/Rejoinnormal/main/install.sh | sh
# ============================================================

REPO_RAW="https://raw.githubusercontent.com/Vyfuyu/Rejoinnormal/main"
INSTALL_DIR="$HOME/roblox-rejoin"
SCRIPT_NAME="roblox_rejoin.sh"
DEST="$INSTALL_DIR/$SCRIPT_NAME"
BASH_BIN="/data/data/com.termux/files/usr/bin/bash"
SHELL_RC="$HOME/.bashrc"

info()  { printf '\033[0;32m[INFO]\033[0m  %s\n' "$1"; }
warn()  { printf '\033[1;33m[WARN]\033[0m  %s\n' "$1"; }
err()   { printf '\033[0;31m[ERROR]\033[0m %s\n' "$1"; }
step()  { printf '\n\033[0;36m[%s]\033[0m %s\n' "$1" "$2"; }

clear
printf '\033[1m\033[35m'
printf '  ____       _     _            \n'
printf ' |  _ \ ___ | |__ | | _____  __\n'
printf ' | |_) / _ \| '"'"'_ \| |/ _ \ \/ /\n'
printf ' |  _ < (_) | |_) | | (_) >  < \n'
printf ' |_| \_\___/|_.__/|_|\___/_/\_\\\n'
printf '  Auto Rejoin Installer - Termux Root\n'
printf '\033[0m\n'
printf '\033[1m🔧 Bắt đầu cài đặt...\033[0m\n'

# ── Bước 1: Cài bash + gói cần thiết ──
step "1/4" "Cài bash, curl, termux-api..."
pkg install -y bash curl termux-api 2>/dev/null || warn "Một số gói cài không được, tiếp tục..."

# Kiểm tra bash
if [ ! -f "$BASH_BIN" ]; then
    err "Không tìm thấy bash tại $BASH_BIN"
    err "Thử: pkg install bash"
    exit 1
fi
info "bash OK → $BASH_BIN"

# ── Bước 2: Tạo thư mục ──
step "2/4" "Tạo thư mục $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
info "$INSTALL_DIR OK"

# ── Bước 3: Download script chính ──
step "3/4" "Tải script từ GitHub..."
if curl -fsSL "${REPO_RAW}/${SCRIPT_NAME}" -o "$DEST"; then
    # Ghi đúng shebang bash Termux vào dòng đầu
    printf '%s\n' "#!${BASH_BIN}" > "$DEST.tmp"
    tail -n +2 "$DEST" >> "$DEST.tmp"
    mv "$DEST.tmp" "$DEST"
    chmod +x "$DEST"
    info "Đã tải: $DEST"
else
    err "Tải thất bại! Kiểm tra kết nối mạng."
    exit 1
fi

# ── Bước 4: Tạo alias dùng FULL PATH bash ──
step "4/4" "Tạo lệnh nhanh 'rbjoin'..."

# Xoá alias cũ nếu có, rồi ghi lại
if grep -q "rbjoin" "$SHELL_RC" 2>/dev/null; then
    grep -v "rbjoin\|Roblox Auto Rejoin" "$SHELL_RC" > "$SHELL_RC.tmp" && mv "$SHELL_RC.tmp" "$SHELL_RC"
fi
printf '\n# Roblox Auto Rejoin\nalias rbjoin='"'"'su -c "%s %s"'"'"'\n' "$BASH_BIN" "$DEST" >> "$SHELL_RC"

info "Alias 'rbjoin' đã thêm vào $SHELL_RC"
info "Nội dung alias:"
grep "rbjoin" "$SHELL_RC" | tail -1

# ── Hoàn tất ──
printf '\n\033[1m\033[32m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m\n'
printf '\033[1m\033[32m  ✅ CÀI ĐẶT HOÀN TẤT!\033[0m\n'
printf '\033[1m\033[32m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m\n\n'
printf '\033[1;33m  Chạy ngay (copy lệnh này):\033[0m\n'
printf '  su -c "%s %s"\n\n' "$BASH_BIN" "$DEST"
printf '\033[1;33m  Sau khi mở lại Termux, dùng:\033[0m\n'
printf '  source %s && rbjoin\n\n' "$SHELL_RC"

# Hỏi chạy ngay — đọc từ /dev/tty để hoạt động kể cả khi dùng curl | sh
printf '▶ Chạy Roblox Auto Rejoin ngay bây giờ? (y/n): '
read -r RUN_NOW </dev/tty
if [ "$RUN_NOW" = "y" ] || [ "$RUN_NOW" = "Y" ]; then
    printf '\n'
    su -c "$BASH_BIN $DEST"
fi
