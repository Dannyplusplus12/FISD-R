# FISD — Frontend Flutter

Giao diện quản lý kho/bán hàng nội bộ. Kết nối với backend FastAPI trên Railway.

---

## Yêu cầu

- **Flutter SDK** `>= 3.11.3` — [Hướng dẫn cài đặt](https://docs.flutter.dev/get-started/install)
- Sau khi cài, chạy `flutter doctor` để kiểm tra môi trường

### Theo nền tảng

| Nền tảng | Yêu cầu thêm |
|---|---|
| Web (Chrome) | Không cần gì thêm |
| Windows | Visual Studio 2022 với workload **Desktop development with C++** |
| Android | Android Studio + Android SDK + thiết bị hoặc emulator |

---

## Chạy local

```bash
cd frontend
flutter pub get
flutter run -d chrome       # web
flutter run -d windows      # windows desktop
flutter devices             # xem danh sách thiết bị khả dụng
```

Backend URL được cấu hình trong `lib/core/api/api_client.dart`.  
Mặc định trỏ tới: `https://backend-production-0935.up.railway.app`

---

## Cấu trúc thư mục

```
lib/
├── main.dart
├── core/
│   ├── api/
│   │   ├── api_client.dart      # Dio client, base URL
│   │   └── endpoints.dart       # Tất cả URL endpoints
│   ├── session/session.dart     # Lưu phiên đăng nhập (SharedPreferences)
│   └── theme.dart
├── models/                      # Data classes
├── features/                    # Mỗi feature có 3 file: repository / provider / page
│   ├── xac_thuc/                # Đăng nhập PIN
│   ├── san_pham/                # Sản phẩm & biến thể
│   ├── khach_hang/              # Khách hàng & khu vực
│   ├── don_hang/                # Đơn hàng
│   └── nhan_vien/               # Nhân viên (manager only)
└── widgets/                     # Widget dùng chung
```

---

## Đăng nhập

Dùng PIN 4 chữ số — không chọn vai trò. Backend tự trả về `role`.

| PIN | Vai trò |
|---|---|
| `0000` | Quản lý (manager) |
| `1111` | Nhân viên đặt hàng (orderer) |
| `2222` | Picker |
