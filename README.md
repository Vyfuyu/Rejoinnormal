# 🎮 Roblox Auto Rejoin — Termux Root

Tự động phát hiện Roblox bị văng / bị đóng, kill tiến trình cũ và mở lại game ngay lập tức. Chạy liên tục nền, không cần can thiệp thủ công.

---

## ⚡ Chạy 1 lệnh duy nhất

```bash
curl -sSL https://raw.githubusercontent.com/Vyfuyu/Rejoinnormal/main/install.sh | bash
```

> Lệnh trên sẽ tự cài gói, tải script, tạo alias `rbjoin` và hỏi có muốn chạy ngay không.

---

## 📋 Yêu cầu

| Yêu cầu | Chi tiết |
|---|---|
| **Termux** | Phiên bản mới nhất từ F-Droid |
| **Root** | Máy đã root (Magisk / KernelSU) |
| **Roblox** | Đã cài sẵn (`com.roblox.client`) |
| **curl** | `pkg install curl` |
| **termux-api** *(tuỳ chọn)* | `pkg install termux-api` — để có rung + notification |

---

## 🚀 Cách dùng

### Lần đầu — cài đặt

```bash
# Cài đặt đầy đủ
curl -sSL https://raw.githubusercontent.com/Vyfuyu/Rejoinnormal/main/install.sh | bash
```

### Chạy lại sau khi đã cài

```bash
# Dùng alias nhanh (sau khi cài)
rbjoin

# Hoặc chạy thẳng
su -c "bash ~/roblox-rejoin/roblox_rejoin.sh"
```

### Cài thủ công (không dùng installer)

```bash
# Tải script
curl -sSL https://raw.githubusercontent.com/Vyfuyu/Rejoinnormal/main/roblox_rejoin.sh -o ~/roblox_rejoin.sh
chmod +x ~/roblox_rejoin.sh

# Chạy với root
su -c "bash ~/roblox_rejoin.sh"
```

---

## ⚙️ Cấu hình

Mở file `roblox_rejoin.sh`, chỉnh phần **CẤU HÌNH** ở đầu file:

```bash
GAME_LINK=""          # Link game Roblox (nhập khi chạy nếu để trống)
CHECK_INTERVAL=5      # Kiểm tra mỗi 5 giây
RESTART_DELAY=5       # Chờ 5s sau khi kill trước khi mở lại
WARMUP_TIME=20        # Chờ 20s để Roblox load game xong
CRASH_COOLDOWN=10     # Cooldown thêm nếu crash liên tục
MAX_CRASHES_IN_ROW=5  # Ngưỡng phát hiện crash liên tiếp
ENABLE_VIBRATE=true   # Rung khi phát hiện crash
ENABLE_TOAST=true     # Hiện toast notification
ENABLE_NOTIFICATION=true  # Hiện thanh notification
```

### Định dạng link game

```
roblox://placeId=10449761463
roblox://experiences/start?placeId=10449761463
https://www.roblox.com/games/10449761463
```

---

## ✨ Tính năng

- 🔍 **Phát hiện crash đa lớp** — dùng `pidof` + `pgrep` + `ps -A`, không bỏ sót
- 💀 **Kill hoàn toàn** — `am force-stop` + `kill -9` + `killall` (root)
- 📱 **Wake màn hình** — tự bật màn hình trước khi launch lại Roblox
- ⏳ **Cooldown thông minh** — tự thêm delay nếu crash liên tục nhiều lần
- 📊 **Thống kê real-time** — đếm số rejoin, uptime, crash streak
- 📝 **Log file** — lưu tại `~/roblox_rejoin.log`, tự cắt bớt khi quá dài
- 🔔 **Thông báo** — Toast + Notification + Rung khi phát hiện crash
- 🛑 **Dừng sạch** — Ctrl+C để dừng, hiện tổng kết thống kê

---

## 📁 Cấu trúc file

```
Rejoinnormal/
├── roblox_rejoin.sh   # Script chính — vòng lặp giám sát
├── install.sh         # Installer một lệnh
└── README.md          # Tài liệu này
```

---

## 🐛 Troubleshooting

| Vấn đề | Giải pháp |
|---|---|
| `am: not found` | Chạy trong Termux, không phải shell thường |
| Roblox không mở lại được | Kiểm tra lại `GAME_LINK`, thử định dạng `roblox://placeId=...` |
| Script không phát hiện crash | Kiểm tra `ROBLOX_PACKAGE` có đúng không (`com.roblox.client`) |
| Rung/notification không hoạt động | Cài `pkg install termux-api` và cấp quyền Termux API |
| Script dừng sau vài giờ | Tắt battery optimization cho Termux trong cài đặt Android |

---

## 📜 License

MIT — Dùng tự do, sửa thoải mái.
