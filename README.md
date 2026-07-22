# 🎮 Roblox Auto Rejoin — Termux Root

Tự động phát hiện Roblox bị văng / bị đóng, kill tiến trình cũ và mở lại game ngay lập tức. Chạy liên tục, không cần can thiệp thủ công.

---

## ⚡ Chạy 1 lệnh duy nhất

```sh
curl -sSL https://raw.githubusercontent.com/Vyfuyu/Rejoinnormal/main/install.sh | sh
```

> **Dùng `sh` không phải `bash`** — `sh` luôn có sẵn trong Termux, còn `bash` cần cài trước.  
> Installer sẽ tự cài `bash`, `termux-api`, tải script về, tạo alias `rbjoin`.

---

## 📋 Yêu cầu

| Yêu cầu | Chi tiết |
|---|---|
| **Termux** | Phiên bản mới nhất từ F-Droid |
| **Root** | Máy đã root (Magisk / KernelSU) |
| **Roblox** | Đã cài (`com.roblox.client`) |
| **curl** | `pkg install curl` |

> `bash` và `termux-api` sẽ được installer tự cài.

---

## 🚀 Cách dùng

### Lần đầu — cài đặt

```sh
# Bước cần làm trước nếu chưa có curl:
pkg install curl

# Chạy installer (dùng sh):
curl -sSL https://raw.githubusercontent.com/Vyfuyu/Rejoinnormal/main/install.sh | sh
```

### Chạy lại sau khi đã cài

```sh
# Dùng alias nhanh (sau khi mở lại Termux)
rbjoin

# Hoặc chạy thẳng
su -c "bash ~/roblox-rejoin/roblox_rejoin.sh"
```

### Cài thủ công (không dùng installer)

```sh
pkg install bash curl
curl -sSL https://raw.githubusercontent.com/Vyfuyu/Rejoinnormal/main/roblox_rejoin.sh -o ~/roblox_rejoin.sh
chmod +x ~/roblox_rejoin.sh
su -c "bash ~/roblox_rejoin.sh"
```

---

## ⚙️ Menu cấu hình khi chạy

Mỗi lần chạy, script hỏi 4 thứ:

| Câu hỏi | Mặc định | Ghi chú |
|---|---|---|
| **Package game** | `com.roblox.client` | Đổi nếu dùng bản Roblox khác |
| **Link game / private server** | *(nhập vào)* | Hỗ trợ nhiều định dạng |
| **Tần suất kiểm tra** | `5s` | Nhỏ hơn = phản ứng nhanh hơn nhưng tốn pin |
| **Thời gian chờ load game** | `20s` | Tăng nếu máy load chậm |

### Định dạng link được hỗ trợ

```
# Link game thường
roblox://placeId=10449761463

# Link private server (share link)
https://www.roblox.com/share?code=d7ca4f4683d09b41ade6fc5e5c439b47&type=Server

# Deeplink đầy đủ
roblox://experiences/start?linkCode=d7ca4f4683d09b41ade6fc5e5c439b47
```

> Script tự chuyển link `roblox.com/share?code=...` → deeplink `roblox://` để join đúng private server.

---

## ✨ Tính năng

| Tính năng | Chi tiết |
|---|---|
| 🔍 **Phát hiện đa lớp** | `pidof` + `pgrep` + `ps -A` — không bỏ sót |
| 💀 **Kill hoàn toàn** | `am force-stop` + `kill -9` + `killall` (root) |
| 📱 **Wake màn hình** | Tự bật màn hình trước khi mở lại Roblox |
| ⏳ **Cooldown thông minh** | Thêm delay nếu crash liên tục nhiều lần |
| 🔗 **Auto convert link** | Share link web → deeplink `roblox://` tự động |
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
├── install.sh         # Installer một lệnh (chạy với sh)
└── README.md          # Tài liệu này
```

---

## 🐛 Troubleshooting

| Vấn đề | Giải pháp |
|---|---|
| `bash: not found` | `pkg install bash` |
| `sh: bash: inaccessible` | Dùng `sh` thay `bash` trong lệnh curl |
| `am: not found` | Phải chạy trong Termux, không phải shell khác |
| Roblox không mở lại | Kiểm tra link đúng định dạng `roblox://placeId=...` |
| Không phát hiện crash | Kiểm tra package name đúng chưa (`pm list packages \| grep roblox`) |
| Rung/notification lỗi | `pkg install termux-api` + cấp quyền Termux API trong Settings Android |
| Script tự dừng sau vài giờ | Tắt battery optimization cho Termux trong Settings Android |
| Private server không join | Dùng định dạng `roblox://experiences/start?linkCode=CODE` |

---

## 📜 License

MIT — Dùng tự do, sửa thoải mái.
