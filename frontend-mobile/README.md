# fisd_mobile

FISD Mobile — app Flutter cho nhân viên, chạy trên Android (APK, cập nhật OTA
qua Shorebird) và như PWA trên web/iPhone (cập nhật qua service worker).

## Cập nhật OTA trên Android (Shorebird)

App đã tích hợp sẵn `shorebird_code_push` (xem `lib/core/cap_nhat/`) —
`main.dart` tự kiểm tra bản vá mỗi khi mở app / quay lại foreground, tải
ngầm nếu có, rồi hiện banner "Đóng và mở lại ứng dụng để áp dụng".

Phần còn lại (tạo app trên Shorebird, build/release) là thao tác cục bộ,
cần đăng nhập tài khoản Shorebird của bạn, KHÔNG thể tự động hoá:

```bash
# 1. Cài Shorebird CLI (một lần)
curl -s https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh | bash
# hoặc trên Windows: xem https://docs.shorebird.dev/quick-start/getting-started

# 2. Đăng nhập
shorebird login

# 3. Khởi tạo — tạo app trên Shorebird console + sinh file shorebird.yaml
#    (chạy trong thư mục frontend-mobile)
shorebird init

# 4. Build & phát hành bản đầy đủ đầu tiên (thay cho `flutter build apk`)
shorebird release android

# 5. Sau mỗi lần sửa code Dart (không đổi plugin native), phát hành bản vá OTA
shorebird patch android
```

Lưu ý:
- `shorebird.yaml` (chứa `app_id`) được sinh ra bởi `shorebird init` và cần
  commit vào repo để các lần release/patch sau dùng đúng app.
- Patch OTA chỉ áp dụng cho code Dart. Đổi native code (Kotlin/Gradle, thêm
  plugin mới) bắt buộc phải `shorebird release android` (build đầy đủ) rồi
  phân phối lại APK.
- Nếu app được build bằng `flutter build apk` thông thường (không qua
  Shorebird), `ShorebirdUpdater().isAvailable` sẽ trả `false` — banner cập
  nhật sẽ không hiện, không có lỗi gì xảy ra.

## Cập nhật PWA trên web

Khi deploy web mới (Railway rebuild → Flutter sinh `flutter_service_worker.js`
mới), trình duyệt của người dùng đang mở app sẽ tự phát hiện service worker
mới cài xong (`lib/core/cap_nhat/lang_nghe_pwa_web.dart`) và hiện banner
"Đã có phiên bản mới. Tải lại trang để cập nhật." — bấm "Tải lại" sẽ
`location.reload()` để nhận bản mới. Không cần cấu hình gì thêm.
