#!/bin/bash
# ============================================================
#  ROBLOX AUTO REJOIN - Termux (Root)
#  Tự động phát hiện Roblox bị văng/đóng, kill & mở lại game
# ============================================================

# ─────────────────────────────────────────
#  CẤU HÌNH - Chỉnh sửa tại đây
# ─────────────────────────────────────────
ROBLOX_PACKAGE="com.roblox.client"          # Package name chính thức của Roblox
GAME_LINK=""                                # Link game (vd: roblox://placeId=12345)
                                            # Để trống để script hỏi khi chạy

CHECK_INTERVAL=5          # Kiểm tra mỗi N giây
RESTART_DELAY=5           # Chờ N giây sau khi kill trước khi mở lại
WARMUP_TIME=20            # Chờ N giây sau khi mở Roblox để game load xong
CRASH_COOLDOWN=10         # Chờ thêm N giây nếu crash liên tục
MAX_CRASHES_IN_ROW=5      # Dừng cảnh báo nếu crash quá nhiều lần liên tiếp
LOG_FILE="$HOME/roblox_rejoin.log"          # File log
MAX_LOG_LINES=500         # Giới hạn dòng log (tự cắt bớt)
ENABLE_VIBRATE=true       # Rung điện thoại khi phát hiện crash (true/false)
ENABLE_TOAST=true         # Hiện thông báo toast (true/false)
ENABLE_NOTIFICATION=true  # Hiện notification (true/false)

# ─────────────────────────────────────────
#  MÀU SẮC TERMINAL
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
LAST_RESTART_TIME=0
SCRIPT_PID=$$

# ─────────────────────────────────────────
#  HÀM LOG
# ─────────────────────────────────────────
log() {
    local level="$1"
    local msg="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local line="[$timestamp] [$level] $msg"

    # In ra terminal với màu
    case "$level" in
        INFO)    echo -e "${GREEN}[INFO]${RESET}  $msg" ;;
        WARN)    echo -e "${YELLOW}[WARN]${RESET}  $msg" ;;
        ERROR)   echo -e "${RED}[ERROR]${RESET} $msg" ;;
        ACTION)  echo -e "${CYAN}[ACTION]${RESET} $msg" ;;
        STAT)    echo -e "${MAGENTA}[STAT]${RESET}  $msg" ;;
        *)       echo -e "$msg" ;;
    esac

    # Ghi vào file log
    echo "$line" >> "$LOG_FILE"

    # Cắt bớt log nếu quá dài
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
    if [ "$ENABLE_TOAST" = true ]; then
        am broadcast -a me.shikhir.forge.REQUEST_TOAST \
            --es "message" "$1" 2>/dev/null || true
        # Fallback: termux-toast nếu có
        command -v termux-toast &>/dev/null && termux-toast "$1" 2>/dev/null || true
    fi
}

send_notification() {
    if [ "$ENABLE_NOTIFICATION" = true ]; then
        command -v termux-notification &>/dev/null && \
            termux-notification \
                --title "Roblox Auto Rejoin" \
                --content "$1" \
                --id 9001 \
                --ongoing 2>/dev/null || true
    fi
}

vibrate() {
    if [ "$ENABLE_VIBRATE" = true ]; then
        command -v termux-vibrate &>/dev/null && termux-vibrate -d 300 2>/dev/null || true
    fi
}

# Kiểm tra xem Roblox có đang chạy không
is_roblox_running() {
    # Dùng pidof (root) để chính xác hơn
    if pidof "$ROBLOX_PACKAGE" &>/dev/null 2>&1; then
        return 0
    fi
    # Backup: dùng pgrep
    if pgrep -f "$ROBLOX_PACKAGE" &>/dev/null 2>&1; then
        return 0
    fi
    # Backup 2: dùng ps -A
    if ps -A 2>/dev/null | grep -q "$ROBLOX_PACKAGE"; then
        return 0
    fi
    return 1
}

# Lấy PID của Roblox
get_roblox_pid() {
    pidof "$ROBLOX_PACKAGE" 2>/dev/null \
        || pgrep -f "$ROBLOX_PACKAGE" 2>/dev/null \
        || ps -A 2>/dev/null | grep "$ROBLOX_PACKAGE" | awk '{print $1}' | head -1
}

# Kill hoàn toàn Roblox (root)
kill_roblox() {
    log "ACTION" "Đang kill Roblox..."
    local pid
    pid=$(get_roblox_pid)

    # Kill bằng am force-stop trước
    am force-stop "$ROBLOX_PACKAGE" 2>/dev/null || true
    sleep 1

    # Kill bằng PID nếu còn sót
    if [ -n "$pid" ]; then
        kill -9 $pid 2>/dev/null || true
    fi

    # Root: dùng killall
    killall -9 "$ROBLOX_PACKAGE" 2>/dev/null || true

    # Xóa cache RAM nếu cần (tránh Roblox bị đóng băng)
    # echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true

    sleep "$RESTART_DELAY"
    log "INFO" "Đã kill Roblox xong."
}

# Mở lại Roblox với link game
open_roblox() {
    log "ACTION" "Đang mở lại Roblox... (link: $GAME_LINK)"

    # Monkey-patch: wake screen trước khi mở app
    input keyevent 26 2>/dev/null || true   # POWER key (wake)
    sleep 0.5
    input keyevent 82 2>/dev/null || true   # MENU key (unlock nếu không có password)
    sleep 0.5

    # Mở Roblox bằng intent
    am start -a android.intent.action.VIEW -d "$GAME_LINK" "$ROBLOX_PACKAGE" 2>/dev/null \
        || am start -n "${ROBLOX_PACKAGE}/${ROBLOX_PACKAGE}.RobloxMainActivity" 2>/dev/null \
        || monkey -p "$ROBLOX_PACKAGE" -c android.intent.category.LAUNCHER 1 2>/dev/null \
        || true

    log "INFO" "Đã gửi lệnh mở Roblox. Chờ ${WARMUP_TIME}s để game load..."
    sleep "$WARMUP_TIME"
}

# Thời gian chạy
uptime_str() {
    local secs=$(( $(date +%s) - START_TIME ))
    printf "%02dh %02dm %02ds" $((secs/3600)) $(( (secs%3600)/60 )) $((secs%60))
}

# In banner trạng thái
print_status() {
    echo -e "\n${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}  🎮 ROBLOX AUTO REJOIN - ĐANG CHẠY${RESET}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${CYAN}Lần rejoin:${RESET}   $REJOIN_COUNT"
    echo -e "  ${CYAN}Uptime:${RESET}       $(uptime_str)"
    echo -e "  ${CYAN}Crash streak:${RESET} $CRASH_STREAK"
    echo -e "  ${CYAN}Game link:${RESET}    $GAME_LINK"
    echo -e "  ${CYAN}Log file:${RESET}     $LOG_FILE"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
}

# ─────────────────────────────────────────
#  KIỂM TRA MÔI TRƯỜNG
# ─────────────────────────────────────────
check_environment() {
    echo -e "\n${BOLD}${CYAN}🔍 Đang kiểm tra môi trường...${RESET}\n"
    local ok=true

    # Kiểm tra root
    if [ "$(id -u)" -eq 0 ] || command -v su &>/dev/null; then
        echo -e "  ${GREEN}✓ Root / su: OK${RESET}"
    else
        echo -e "  ${RED}✗ Root / su: KHÔNG CÓ${RESET}"
        echo -e "    Cần chạy script với quyền root!"
        ok=false
    fi

    # Kiểm tra am (Android Activity Manager)
    if command -v am &>/dev/null; then
        echo -e "  ${GREEN}✓ am (Android): OK${RESET}"
    else
        echo -e "  ${RED}✗ am: KHÔNG TÌM THẤY${RESET}"
        ok=false
    fi

    # Kiểm tra Roblox đã cài chưa
    if pm list packages 2>/dev/null | grep -q "$ROBLOX_PACKAGE"; then
        echo -e "  ${GREEN}✓ Roblox đã cài: OK ($ROBLOX_PACKAGE)${RESET}"
    else
        echo -e "  ${YELLOW}⚠ Không phát hiện $ROBLOX_PACKAGE${RESET}"
        echo -e "    Script vẫn chạy nhưng hãy kiểm tra package name!"
    fi

    # Kiểm tra termux-api (tuỳ chọn)
    if command -v termux-vibrate &>/dev/null; then
        echo -e "  ${GREEN}✓ termux-api: OK${RESET}"
    else
        echo -e "  ${YELLOW}⚠ termux-api không có (vibrate/notification bị tắt)${RESET}"
        ENABLE_VIBRATE=false
        ENABLE_NOTIFICATION=false
    fi

    echo ""
    if [ "$ok" = false ]; then
        echo -e "${RED}Môi trường chưa đủ yêu cầu. Dừng lại.${RESET}"
        exit 1
    fi
}

# ─────────────────────────────────────────
#  XỬ LÝ TÍN HIỆU (Ctrl+C)
# ─────────────────────────────────────────
cleanup() {
    echo -e "\n\n${YELLOW}[WARN]  Script bị dừng bởi người dùng.${RESET}"
    log "WARN" "Script dừng thủ công. Tổng rejoin: $REJOIN_COUNT | Uptime: $(uptime_str)"
    echo -e "${CYAN}Log được lưu tại: $LOG_FILE${RESET}\n"
    exit 0
}
trap cleanup SIGINT SIGTERM

# ─────────────────────────────────────────
#  VÒNG LẶP CHÍNH
# ─────────────────────────────────────────
main_loop() {
    log "INFO" "Bắt đầu vòng lặp giám sát. PID script: $SCRIPT_PID"
    log "INFO" "Game link: $GAME_LINK | Check interval: ${CHECK_INTERVAL}s"

    # Đảm bảo Roblox mở ngay khi bắt đầu nếu chưa chạy
    if ! is_roblox_running; then
        log "INFO" "Roblox chưa mở. Đang khởi động lần đầu..."
        open_roblox
    else
        log "INFO" "Roblox đang chạy. Bắt đầu giám sát..."
    fi

    local consecutive_open=0   # Đếm số lần kiểm tra thấy Roblox đang chạy

    while true; do
        sleep "$CHECK_INTERVAL"

        if is_roblox_running; then
            consecutive_open=$((consecutive_open + 1))
            CRASH_STREAK=0

            # Cứ 60 lần check (= CHECK_INTERVAL * 60 giây) mới log 1 lần
            if (( consecutive_open % 12 == 0 )); then
                local mins=$(( consecutive_open * CHECK_INTERVAL / 60 ))
                log "INFO" "Roblox đang chạy bình thường. (~${mins}p) | Rejoin: $REJOIN_COUNT | Uptime: $(uptime_str)"
            fi
        else
            consecutive_open=0
            CRASH_STREAK=$((CRASH_STREAK + 1))
            REJOIN_COUNT=$((REJOIN_COUNT + 1))

            log "WARN" "⚠️  Roblox KHÔNG CÒN CHẠY! (Crash/Văng lần #$CRASH_STREAK | Rejoin #$REJOIN_COUNT)"
            vibrate
            show_toast "Roblox bị văng! Đang rejoin (#$REJOIN_COUNT)..."
            send_notification "Roblox bị văng lần $REJOIN_COUNT. Đang rejoin..."

            # Nếu crash liên tục quá nhiều, thêm cooldown
            if [ "$CRASH_STREAK" -ge "$MAX_CRASHES_IN_ROW" ]; then
                log "WARN" "Crash liên tục $CRASH_STREAK lần! Chờ thêm ${CRASH_COOLDOWN}s cooldown..."
                sleep "$CRASH_COOLDOWN"
            fi

            # Kill tiến trình cũ
            kill_roblox

            # Mở lại game
            open_roblox

            log "ACTION" "✅ Rejoin #$REJOIN_COUNT hoàn tất. Tiếp tục giám sát..."

            # Xác nhận Roblox đã mở sau warmup
            if is_roblox_running; then
                log "INFO" "Xác nhận: Roblox đang chạy sau rejoin."
            else
                log "WARN" "Cảnh báo: Roblox có thể chưa mở thành công sau rejoin!"
            fi
        fi
    done
}

# ─────────────────────────────────────────
#  NHẬP LINK GAME
# ─────────────────────────────────────────
get_game_link() {
    if [ -z "$GAME_LINK" ]; then
        echo -e "${BOLD}${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "${BOLD}  🎮 ROBLOX AUTO REJOIN TOOL v2.0${RESET}"
        echo -e "${BOLD}${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo ""
        echo -e "${CYAN}Nhập link Roblox game của bạn:${RESET}"
        echo -e "${YELLOW}  Ví dụ: roblox://placeId=10449761463${RESET}"
        echo -e "${YELLOW}  Hoặc:  https://www.roblox.com/games/10449761463${RESET}"
        echo -e "${YELLOW}  Hoặc:  roblox://experiences/start?placeId=10449761463${RESET}"
        echo ""
        read -rp "  🔗 Link game: " GAME_LINK
        echo ""

        if [ -z "$GAME_LINK" ]; then
            echo -e "${RED}Chưa nhập link! Dùng link mặc định mở Roblox.${RESET}"
            GAME_LINK="roblox://navigateTo?navigationTarget=home"
        fi
    fi
}

# ─────────────────────────────────────────
#  KHỞI ĐỘNG
# ─────────────────────────────────────────
clear
echo -e "${BOLD}${MAGENTA}"
cat << 'EOF'
  ____       _     _            
 |  _ \ ___ | |__ | | _____  __
 | |_) / _ \| '_ \| |/ _ \ \/ /
 |  _ < (_) | |_) | | (_) >  < 
 |_| \_\___/|_.__/|_|\___/_/\_\
  Auto Rejoin Tool v2.0 - Termux Root
EOF
echo -e "${RESET}"

# Nhận link game
get_game_link

# Kiểm tra môi trường
check_environment

# Tạo file log nếu chưa có
touch "$LOG_FILE"
log "INFO" "═══════════════ SESSION BẮT ĐẦU ═══════════════"
log "INFO" "Game link: $GAME_LINK"
log "INFO" "Package:   $ROBLOX_PACKAGE"
log "INFO" "Check interval: ${CHECK_INTERVAL}s | Restart delay: ${RESTART_DELAY}s | Warmup: ${WARMUP_TIME}s"

# In trạng thái ban đầu
print_status

echo -e "${BOLD}${GREEN}🚀 Đang bắt đầu giám sát Roblox...${RESET}"
echo -e "${YELLOW}   Nhấn Ctrl+C để dừng script.${RESET}\n"
sleep 2

# Bắt đầu vòng lặp chính
main_loop
