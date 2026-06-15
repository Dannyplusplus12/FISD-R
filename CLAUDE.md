# FISD — Claude Instructions

Hệ thống quản lý kho/bán hàng nội bộ bằng tiếng Việt.
Backend FastAPI + Frontend Flutter, deploy trên Railway.

---

## Quan Trọng — Đọc Trước

- **Thư mục làm việc:** `D:\Dev\APP\FISD` (KHÔNG phải `D:\Dev\APP\FISD-r` — đó là project tham khảo cũ, KHÔNG chỉnh sửa)
- **GitHub repo:** `FISD-R` (tên repo khác tên thư mục local)
- **Backend URL đúng:** `https://backend-production-0935.up.railway.app`
- **Backend URL CŨ (không dùng):** `https://backend-production-5efd.up.railway.app`

---

## Cấu Trúc Project

```
FISD/
├── CLAUDE.md          ← file này
├── TAILIEU.md         ← tài liệu API endpoints đầy đủ
├── backend/           ← FastAPI app
│   ├── app/
│   │   ├── main.py
│   │   ├── models/
│   │   ├── routers/
│   │   ├── schemas/
│   │   ├── database.py
│   │   └── core/config.py
│   ├── Dockerfile
│   └── railway.json
└── frontend/          ← Flutter app
    └── lib/
        ├── main.dart
        ├── core/
        │   ├── theme.dart
        │   ├── api/api_client.dart
        │   ├── api/endpoints.dart
        │   └── session/session.dart
        ├── models/
        ├── features/
        └── widgets/
```

---

## Quy Tắc Đặt Tên — Tiếng Việt Hoàn Toàn

Mọi tên biến, hàm, class, file, URL đều dùng tiếng Việt (có dấu gạch ngang cho URL).

### Class / File

| Khái niệm | Tên dùng |
|---|---|
| Product | SanPham |
| Variant | BienThe |
| Area | KhuVuc |
| Customer | KhachHang |
| Debt history | LichSuNo |
| Employee | NhanVien |
| Order | DonHang |
| Order item | ChiTietDon |
| Cart item | MatHangGio |
| Nav item | MucDieuHuong |
| App shell | KhungApp |
| Sidebar | ThanhBen |
| Auth gate | CongXacThuc |

### URL Endpoints

| Nhóm | Prefix |
|---|---|
| Sản phẩm | `/san-pham` |
| Ảnh sản phẩm | `/anh-san-pham` |
| Khu vực | `/khu-vuc` |
| Khách hàng | `/khach-hang` |
| Lịch sử nợ | `/khach-hang/{id}/lich-su-no` |
| Nhân viên | `/nhan-vien` |
| Xác thực | `/xac-thuc` |
| Đơn hàng | `/don-hang` |
| Thanh toán | `/thanh-toan` |
| Bằng chứng giao | `/bang-chung-giao` |
| Thống kê | `/thong-ke` |

---

## Backend — Quy Tắc

### Stack
- Python 3.12, FastAPI, SQLAlchemy 2.0 (sync), PostgreSQL (Railway) / SQLite (local)
- Import tuyệt đối: `from app.database import get_db` — KHÔNG dùng `from ..database`
- HTTP client đồng bộ: `httpx.Client()` — KHÔNG dùng `requests`
- Telegram backup chạy trong `threading.Thread(daemon=True)` để không block response

### Tiền (VND)
- Luôn lưu và trả về kiểu `int` — KHÔNG bao giờ dùng `float`

### Trạng Thái Đơn Hàng
```
pending → approved → assigned → completed
           ↓
         rejected / cancelled (xóa khỏi DB)
```

### Router Files
- `routers/san_pham.py` — prefix `/san-pham`, ảnh `/anh-san-pham/`
- `routers/khach_hang.py` — `khu_vuc_router` prefix `/khu-vuc`, `khach_hang_router` prefix `/khach-hang`
- `routers/nhan_vien.py` — `router` prefix `/nhan-vien`, `auth_router` prefix `/xac-thuc`
- `routers/don_hang.py` — không prefix (route path đầy đủ `/don-hang/...`)

### Database Migrations
`main.py` tự động thêm cột mới khi khởi động:
- SQLite: dùng `PRAGMA table_info` + `ALTER TABLE ADD COLUMN`
- Postgres: dùng `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`

### Seed Mặc Định (tự động khi DB trống)
| PIN | Tên | Vai trò |
|---|---|---|
| 0000 | Quản lý | manager |
| 1111 | Nhân viên 1 | orderer |
| 2222 | Picker 1 | picker |

---

## Frontend — Quy Tắc

### Stack
- Flutter/Dart, Riverpod (state management), Dio (HTTP), SharedPreferences (session)

### Cấu Trúc Feature
Mỗi feature có 3 file theo pattern **Repository → Provider → Page**:
```
features/<ten>/
  <ten>_repository.dart   ← gọi API (dùng ApiEndpoints.xxx)
  <ten>_provider.dart     ← AsyncNotifier, state management
  <ten>_page.dart         ← UI
```

**Vai trò từng tầng:**
- **Repository** — chỉ biết về mạng: gọi API, parse JSON, trả về model hoặc ném exception. Không biết về UI.
- **Provider** — cầu nối duy nhất giữa repository và UI: giữ state, gọi repository, expose data qua Riverpod `AsyncNotifier`.
- **Page** — chỉ `ref.watch()` / `ref.read()` provider. Không gọi API trực tiếp.

**Luồng dữ liệu:**
```
Page → (action) → Provider → Repository → API
Page ← (watch)  ← Provider ← Repository ← API
```

### Providers Quan Trọng
| Provider | File | Mô tả |
|---|---|---|
| `sanPhamProvider` | features/san_pham/ | danh sách sản phẩm |
| `khachHangProvider` | features/khach_hang/ | danh sách khách hàng |
| `khuVucProvider` | features/khach_hang/ | danh sách khu vực |
| `quanLyDonHangProvider` | features/don_hang/ | đơn hàng (manager view) |
| `donHangChoProvider` | features/don_hang/ | đơn chờ duyệt |
| `nhanVienProvider` | features/nhan_vien/ | danh sách nhân viên |
| `xacThucProvider` | features/xac_thuc/ | trạng thái đăng nhập |
| `sessionProvider` | core/session/session.dart | phiên làm việc hiện tại |

### Endpoints
Tất cả URL đặt trong `core/api/endpoints.dart` — KHÔNG hardcode URL trong repository.

### Session / Auth
- Đăng nhập bằng PIN 4 chữ số — KHÔNG chọn vai trò
- Backend tự trả về `role` dựa trên PIN
- `Session.isManager`, `Session.isPicker`, `Session.isOrderer` để phân quyền UI
- Trang nhân viên chỉ hiện với manager

### Navigation
- `CongXacThuc` → kiểm tra session → `KhungApp` (đã đăng nhập) hoặc `DangNhapPage`
- `KhungApp` chứa `ThanhBen` (sidebar) + trang hiện tại
- Menu: Tổng Quan → Sản Phẩm → Đơn Hàng → Khách Hàng → Nhân Viên (manager only)

---

## Deploy

### Railway
- Push lên `master` → Railway tự build Docker → deploy
- `backend/Dockerfile` + `backend/railway.json` kiểm soát build
- Postgres kết nối qua biến môi trường `DATABASE_URL` (Railway inject tự động)

### Biến Môi Trường Backend
```
DATABASE_URL=postgresql://...        (Railway inject)
TELEGRAM_BOT_TOKEN=...               (tuỳ chọn)
TELEGRAM_CHAT_ID=...                 (tuỳ chọn)
CORS_ALLOWED_ORIGINS=*
MAX_DELIVERY_PHOTO_MB=10
DELIVERY_UPLOAD_DIR=/tmp/delivery_proofs
```

### Lệnh Deploy
```bash
git add .
git commit -m "feat: mô tả thay đổi"
git push origin master
```

---

## Chạy Local

```bash
# Backend
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload
# → http://localhost:8000

# Frontend
cd frontend
flutter pub get
flutter run -d chrome
```

---

## Những Điều KHÔNG Làm

- KHÔNG chỉnh sửa `D:\Dev\APP\FISD-r` (project tham khảo cũ)
- KHÔNG gọi `https://backend-production-5efd.up.railway.app` (backend cũ)
- KHÔNG dùng `float` cho tiền VND
- KHÔNG dùng `requests` library trong backend (dùng `httpx.Client()`)
- KHÔNG dùng relative import trong backend (`from ..x import y`)
- KHÔNG hardcode URL trong Flutter (dùng `ApiEndpoints.xxx`)
- KHÔNG đặt tên biến/class bằng tiếng Anh cho code mới
