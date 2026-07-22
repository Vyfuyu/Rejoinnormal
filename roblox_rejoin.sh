#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  ROBLOX AUTO REJOIN - Termux (Root)
#  Tự động phát hiện Roblox bị văng/đóng, kill & mở lại game
# ============================================================

# ─────────────────────────────────────────
#  CẤU HÌNH MẶC ĐỊNH (có thể đổi khi chạy)
# ─────────────────────────────────────────
ROBLOX_PACKAGE="com.roblox.client"   # Package name Roblox
GAME_LINK=""                          # Link game / private server (nhập khi chạy)

CHECK_INTERVAL=5       # Kiểm tra mỗi N giây
RESTART_DELAY=5        # Chờ N giây sau khi kill trước khi mở lại
WARMUP_TIME=20         # Chờ N giây sau khi mở Roblox để game load xong
CRASH_COOLDOWN=10      # Chờ thêm N giây nếu crash liên tục
MAX_CRASHES_IN_ROW=5   # Ngưỡng crash liên tiếp → bật cooldown
LOG_FILE="$HOME/roblox_rejoin.log"
MAX_LOG_LINES=500

ENABLE_VIBRATE=true
ENABLE_TOAST=true
ENABLE_NOTIFICATION=true

# ─────────────────────────────────────────
#  MÀU SẮC
# ─────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
RESET='\033[0m'

# ─────────────────────────────────────────
#  BIẾN TRẠNG THÁI
# ─────────────────────────────────────────
REJOIN_COUNT=0
CRASH_STREAK=0
START_TIME=$(date +%s)

# ─────────────────────────────────────────
#  HÀM LOG
# ─────────────────────────────────────────
log() {
    local level="$1"
    local msg="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $msg" >> "$LOG_FILE"

    case "$level" in
        INFO)   echo -e "${GREEN}[INFO]${RESET}  $msg" ;;
        WARN)   echo -e "${YELLOW}[WARN]${RESET}  $msg" ;;
        ERROR)  echo -e "${RED}[ERROR]${RESET} $msg" ;;
        ACTION) echo -e "${CYAN}[ACTION]${RESET} $msg" ;;
        STAT)   echo -e "${MAGENTA}[STAT]${RESET}  $msg" ;;
        *)      echo -e "$msg" ;;
    esac

    local line_count
    line_count=$(wc -l < "$LOG_FILE" 2>/dev/null || echo 0)
    if [ "$line_count" -gt "$MAX_LOG_LINES" ]; then
        tail -n $((MAX_LOG_LINES / 2)) "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
    fi
}

# ─────────────────────────────────────────
#  HÀM TIỆN ÍCH
# ─────────────────────────────────────────
show_toast() {
    if [ "$ENABLE_TOAST" = "true" ]; then
        command -v termux-toast >/dev/null 2>&1 && termux-toast "$1" 2>/dev/null || true
    fi
}

send_notification() {
    if [ "$ENABLE_NOTIFICATION" = "true" ]; then
        command -v termux-notification >/dev/null 2>&1 && \
            termux-notification --title "Roblox Auto Rejoin" \
                --content "$1" --id 9001 --ongoing 2>/dev/null || true
    fi
}

vibrate_phone() {
    if [ "$ENABLE_VIBRATE" = "true" ]; then
        command -v termux-vibrate >/dev/null 2>&1 && termux-vibrate -d 300 2>/dev/null || true
    fi
}

is_roblox_running() {
    pidof "$ROBLOX_PACKAGE" >/dev/null 2>&1 && return 0
    pgrep -f "$ROBLOX_PACKAGE" >/dev/null 2>&1 && return 0
    ps -A 2>/dev/null | grep -q "$ROBLOX_PACKAGE" && return 0
    return 1
}

get_roblox_pid() {
    pidof "$ROBLOX_PACKAGE" 2>/dev/null \
        || pgrep -f "$ROBLOX_PACKAGE" 2>/dev/null \
        || ps -A 2>/dev/null | grep "$ROBLOX_PACKAGE" | awk '{print $1}' | head -1
}

kill_roblox() {
    log "ACTION" "Đang kill Roblox ($ROBLOX_PACKAGE)..."
    local pid
    pid=$(get_roblox_pid)
    am force-stop "$ROBLOX_PACKAGE" 2>/dev/null || true
    sleep 1
    if [ -n "$pid" ]; then
        kill -9 $pid 2>/dev/null || true
    fi
    killall -9 "$ROBLOX_PACKAGE" 2>/dev/null || true
    sleep "$RESTART_DELAY"
    log "INFO" "Kill xong."
}

open_roblox() {
    log "ACTION" "Mở lại Roblox: $GAME_LINK"
    input keyevent 26 2>/dev/null || true
    sleep 0.5
    input keyevent 82 2>/dev/null || true
    sleep 0.5

    am start -a android.intent.action.VIEW -d "$GAME_LINK" "$ROBLOX_PACKAGE" 2>/dev/null \
        || am start -n "${ROBLOX_PACKAGE}/${ROBLOX_PACKAGE}.RobloxMainActivity" 2>/dev/null \
        || monkey -p "$ROBLOX_PACKAGE" -c android.intent.category.LAUNCHER 1 2>/dev/null \
        || true

    log "INFO" "Chờ ${WARMUP_TIME}s để Roblox load..."
    sleep "$WARMUP_TIME"
}

uptime_str() {
    local secs=$(( $(date +%s) - START_TIME ))
    printf "%02dh %02dm %02ds" $((secs/3600)) $(( (secs%3600)/60 )) $((secs%60))
}

print_status() {
    echo -e "\n${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}  🎮 ROBLOX AUTO REJOIN - ĐANG CHẠY${RESET}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${CYAN}Package:${RESET}      $ROBLOX_PACKAGE"
    echo -e "  ${CYAN}Link game:${RESET}    $GAME_LINK"
    echo -e "  ${CYAN}Lần rejoin:${RESET}   $REJOIN_COUNT"
    echo -e "  ${CYAN}Uptime:${RESET}       $(uptime_str)"
    echo -e "  ${CYAN}Crash streak:${RESET} $CRASH_STREAK"
    echo -e "  ${CYAN}Log:${RESET}          $LOG_FILE"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
}

# ─────────────────────────────────────────
#  MENU CẤU HÌNH TRƯỚC KHI CHẠY
# ─────────────────────────────────────────
setup_menu() {
    clear
    echo -e "${BOLD}${MAGENTA}"
    cat << 'EOF'
  ____       _     _            
 |  _ \ ___ | |__ | | _____  __
 | |_) / _ \| '_ \| |/ _ \ \/ /
 |  _ < (_) | |_) | | (_) >  < 
 |_| \_\___/|_.__/|_|\___/_/\_\
  Auto Rejoin v2.1 - Termux Root
EOF
    echo -e "${RESET}"

    echo -e "${BOLD}${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}  ⚙️  CẤU HÌNH${RESET}"
    echo -e "${BOLD}${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""

    # ── Package name ──
    echo -e "${CYAN}[1] Package Roblox${RESET}"
    echo -e "    Mặc định: ${YELLOW}com.roblox.client${RESET}"
    echo -e "    Ví dụ khác: com.roblox.client (Android), biz.turbonium.roblox..."
    read -rp "    Nhập package (Enter = dùng mặc định): " INPUT_PKG
    if [ -n "$INPUT_PKG" ]; then
        ROBLOX_PACKAGE="$INPUT_PKG"
    fi
    echo -e "    → ${GREEN}$ROBLOX_PACKAGE${RESET}\n"

    # ── Link game / private server ──
    echo -e "${CYAN}[2] Link Game / Private Server${RESET}"
    echo -e "    ${YELLOW}Định dạng được hỗ trợ:${RESET}"
    echo -e "    • roblox://placeId=10449761463"
    echo -e "    • roblox://experiences/start?placeId=10449761463&linkCode=abc123"
    echo -e "    • https://www.roblox.com/share?code=xxx&type=Server"
    echo -e ""
    echo -e "    ${YELLOW}Link của bạn:${RESET}"
    echo -e "    https://www.roblox.com/share?code=d7ca4f4683d09b41ade6fc5e5c439b47&type=Server"
    read -rp "    Nhập link (Enter = dùng link trên): " INPUT_LINK

    if [ -z "$INPUT_LINK" ]; then
        INPUT_LINK="https://www.roblox.com/share?code=d7ca4f4683d09b41ade6fc5e5c439b47&type=Server"
    fi

    # Chuyển link web share → deeplink roblox:// nếu có thể
    if echo "$INPUT_LINK" | grep -q "roblox.com/share"; then
        local share_code
        share_code=$(echo "$INPUT_LINK" | grep -oP '(?<=code=)[^&]+' || echo "")
        if [ -n "$share_code" ]; then
            GAME_LINK="roblox://experiences/start?linkCode=${share_code}"
            echo -e "    → ${GREEN}Đã chuyển sang deeplink: $GAME_LINK${RESET}\n"
        else
            GAME_LINK="$INPUT_LINK"
            echo -e "    → ${GREEN}$GAME_LINK${RESET}\n"
        fi
    else
        GAME_LINK="$INPUT_LINK"
        echo -e "    → ${GREEN}$GAME_LINK${RESET}\n"
    fi

    # ── Interval ──
    echo -e "${CYAN}[3] Tần suất kiểm tra (giây)${RESET}"
    echo -e "    Mặc định: ${YELLOW}${CHECK_INTERVAL}s${RESET} — càng nhỏ phản ứng càng nhanh nhưng tốn pin hơn"
    read -rp "    Nhập số giây (Enter = $CHECK_INTERVAL): " INPUT_INTERVAL
    if [ -n "$INPUT_INTERVAL" ] && echo "$INPUT_INTERVAL" | grep -qE '^[0-9]+$'; then
        CHECK_INTERVAL="$INPUT_INTERVAL"
    fi
    echo -e "    → ${GREEN}${CHECK_INTERVAL}s${RESET}\n"

    # ── Warmup time ──
    echo -e "${CYAN}[4] Thời gian chờ sau khi mở Roblox (giây)${RESET}"
    echo -e "    Mặc định: ${YELLOW}${WARMUP_TIME}s${RESET} — cần đủ thời gian để game load xong"
    read -rp "    Nhập số giây (Enter = $WARMUP_TIME): " INPUT_WARMUP
    if [ -n "$INPUT_WARMUP" ] && echo "$INPUT_WARMUP" | grep -qE '^[0-9]+$'; then
        WARMUP_TIME="$INPUT_WARMUP"
    fi
    echo -e "    → ${GREEN}${WARMUP_TIME}s${RESET}\n"

    echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}  ✅ Cấu hình xong! Bắt đầu giám sát...${RESET}"
    echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${YELLOW}Nhấn Ctrl+C để dừng bất lúc nào.${RESET}\n"
    sleep 2
}

# ─────────────────────────────────────────
#  KIỂM TRA MÔI TRƯỜNG
# ─────────────────────────────────────────
check_environment() {
    local ok=true
    echo -e "${CYAN}🔍 Kiểm tra môi trường...${RESET}"

    if [ "$(id -u)" -eq 0 ] || command -v su >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓ Root/su: OK${RESET}"
    else
        echo -e "  ${RED}✗ Không có quyền root!${RESET}"
        ok=false
    fi

    if command -v am >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓ am (Android): OK${RESET}"
    else
        echo -e "  ${RED}✗ am không tìm thấy — cần chạy trong Termux${RESET}"
        ok=false
    fi

    if pm list packages 2>/dev/null | grep -q "$ROBLOX_PACKAGE"; then
        echo -e "  ${GREEN}✓ $ROBLOX_PACKAGE: Đã cài${RESET}"
    else
        echo -e "  ${YELLOW}⚠ Không phát hiện $ROBLOX_PACKAGE (kiểm tra lại package name)${RESET}"
    fi

    if command -v termux-vibrate >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓ termux-api: OK${RESET}"
    else
        echo -e "  ${YELLOW}⚠ termux-api chưa cài → vibrate/notification tắt${RESET}"
        ENABLE_VIBRATE=false
        ENABLE_NOTIFICATION=false
    fi

    echo ""

    if [ "$ok" = "false" ]; then
        echo -e "${RED}Môi trường thiếu yêu cầu. Dừng.${RESET}"
        exit 1
    fi
}

# ─────────────────────────────────────────
#  DỪNG SẠCH
# ─────────────────────────────────────────
cleanup() {
    echo -e "\n\n${YELLOW}Script dừng thủ công.${RESET}"
    log "WARN" "Dừng thủ công. Tổng rejoin: $REJOIN_COUNT | Uptime: $(uptime_str)"
    echo -e "${CYAN}Log: $LOG_FILE${RESET}\n"
    exit 0
}
trap cleanup INT TERM

# ─────────────────────────────────────────
#  VÒNG LẶP CHÍNH
# ─────────────────────────────────────────
main_loop() {
    log "INFO" "═══════════ SESSION BẮT ĐẦU ═══════════"
    log "INFO" "Package: $ROBLOX_PACKAGE | Link: $GAME_LINK"
    log "INFO" "Check: ${CHECK_INTERVAL}s | Delay: ${RESTART_DELAY}s | Warmup: ${WARMUP_TIME}s"

    if ! is_roblox_running; then
        log "INFO" "Roblox chưa mở → mở lần đầu..."
        open_roblox
    else
        log "INFO" "Roblox đang chạy → bắt đầu giám sát..."
    fi

    local consecutive_open=0

    while true; do
        sleep "$CHECK_INTERVAL"

        if is_roblox_running; then
            consecutive_open=$((consecutive_open + 1))
            CRASH_STREAK=0
            if [ $((consecutive_open % 12)) -eq 0 ]; then
                local mins=$(( consecutive_open * CHECK_INTERVAL / 60 ))
                log "INFO" "OK ~${mins}p | Rejoin: $REJOIN_COUNT | Uptime: $(uptime_str)"
            fi
        else
            consecutive_open=0
            CRASH_STREAK=$((CRASH_STREAK + 1))
            REJOIN_COUNT=$((REJOIN_COUNT + 1))

            log "WARN" "⚠ Roblox VĂNG! Crash streak: $CRASH_STREAK | Rejoin #$REJOIN_COUNT"
            vibrate_phone
            show_toast "Roblox văng! Rejoin #$REJOIN_COUNT..."
            send_notification "Roblox văng lần $REJOIN_COUNT. Đang rejoin..."

            if [ "$CRASH_STREAK" -ge "$MAX_CRASHES_IN_ROW" ]; then
                log "WARN" "Crash liên tục $CRASH_STREAK lần → cooldown ${CRASH_COOLDOWN}s"
                sleep "$CRASH_COOLDOWN"
            fi

            kill_roblox
            open_roblox

            if is_roblox_running; then
                log "ACTION" "✅ Rejoin #$REJOIN_COUNT OK"
            else
                log "WARN" "Roblox có thể chưa mở sau rejoin #$REJOIN_COUNT"
            fi
        fi
    done
}

# ─────────────────────────────────────────
#  KHỞI ĐỘNG
# ─────────────────────────────────────────
setup_menu
check_environment
touch "$LOG_FILE"
print_status
main_loop
