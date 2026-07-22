# 🎮 Roblox Auto Rejoin — Termux Root

Tự động phát hiện Roblox bị văng / bị đóng, kill tiến trình cũ và mở lại game ngay lập tức. Chạy liên tục nền, không cần can thiệp thủ công.

---

## ⚡ Chạy 1 lệnh duy nhất

```bash
curl -sSL https://raw.githubusercontent.com/Vyfuyu/Rejoinnormal/main/install.sh | bash
```

> Lệnh trên tự cài `bash`, `termux-api`, tải script về, tạo alias `rbjoin` và hỏi chạy ngay không.

---

## 📋 Yêu cầu

| Yêu cầu | Chi tiết |
|---|---|
| **Termux** | Phiên bản mới nhất từ F-Droid |
| **Root** | Máy đã root (Magisk / KernelSU) |
| **Roblox** | Đã cài sẵn (`com.roblox.client`) |
| **curl** | `pkg install curl` |
| **termux-api** *(tuỳ chọn)* | `pkg install termux-api` — rung + notification |

---

## 🚀 Cách dùng

### Lần đầu — cài đặt

```bash
curl -sSL https://raw.githubusercontent.com/Vyfuyu/Rejoinnormal/main/install.sh | bash
```

### Chạy lại sau khi đã cài

```bash
# Dùng alias nhanh
rbjoin

# Hoặc chạy thẳng
su -c "bash ~/roblox-rejoin/roblox_rejoin.sh"
```

### Cài thủ công (không dùng installer)

```bash
pkg install bash curl
curl -sSL https://raw.githubusercontent.com/Vyfuyu/Rejoinnormal/main/roblox_rejoin.sh -o ~/roblox_rejoin.sh
chmod +x ~/roblox_rejoin.sh
su -c "bash ~/roblox_rejoin.sh"
```

---

## ⚙️ Menu cấu hình khi chạy

Mỗi lần chạy, script hỏi bạn 4 thứ:

| Câu hỏi | Mặc định | Ghi chú |
|---|---|---|
| **Package game** | `com.roblox.client` | Đổi nếu dùng bản Roblox khác |
| **Link game / private server** | *(nhập vào)* | Hỗ trợ nhiều định dạng |
| **Tần suất kiểm tra** | `5s` | Nhỏ hơn = nhanh hơn nhưng tốn pin |
| **Thời gian chờ load game** | `20s` | Tăng nếu máy chậm |

### Định dạng link được hỗ trợ

```
# Link game thường
roblox://placeId=10449761463

# Link private server (share link)
https://www.roblox.com/share?code=d7ca4f4683d09b41ade6fc5e5c439b47&type=Server

# Deeplink đầy đủ
roblox://experiences/start?placeId=10449761463&linkCode=abc123
```

> Script tự chuyển link `roblox.com/share?code=...` → deeplink `roblox://` để mở đúng private server.

---

## ✨ Tính năng

| Tính năng | Chi tiết |
|---|---|
| 🔍 **Phát hiện đa lớp** | `pidof` + `pgrep` + `ps -A` — không bỏ sót |
| 💀 **Kill hoàn toàn** | `am force-stop` + `kill -9` + `killall` (root) |
| 📱 **Wake màn hình** | Tự bật màn hình trước khi mở lại Roblox |
| ⏳ **Cooldown thông minh** | Thêm delay nếu crash liên tục nhiều lần |
| 🔗 **Auto convert link** | Share link web → deeplink roblox:// tự động |
| 📦 **Đổi package dễ dàng** | Nhập package name khi chạy, không cần sửa file |
| 📊 **Thống kê real-time** | Đếm rejoin, uptime, crash streak |
| 📝 **Log file** | `~/roblox_rejoin.log`, tự cắt bớt khi quá dài |
| 🔔 **Thông báo** | Toast + Notification + Rung khi phát hiện crash |
| 🛑 **Dừng sạch** | Ctrl+C → hiện tổng kết |

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
| `bash: not found` | Chạy `pkg install bash` trước |
| `am: not found` | Phải chạy trong Termux, không phải shell khác |
| Roblox không mở lại | Kiểm tra `GAME_LINK`, thử định dạng `roblox://placeId=...` |
| Không phát hiện crash | Kiểm tra package name đúng chưa |
| Rung/notification lỗi | `pkg install termux-api` + cấp quyền Termux API trong Settings |
| Script tự dừng sau vài giờ | Tắt battery optimization cho Termux trong cài đặt Android |
| Private server không join | Dùng định dạng `roblox://experiences/start?linkCode=CODE` |

---

## 📜 License

MIT — Dùng tự do, sửa thoải mái.
