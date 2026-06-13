# FISD — Tài Liệu Dự Án

Hệ thống quản lý kho/bán hàng nội bộ. Backend FastAPI + Frontend Flutter.

---

## Thông Tin Triển Khai

| Thành phần | URL |
|---|---|
| Backend (Railway) | https://backend-production-0935.up.railway.app |
| GitHub repo | https://github.com/Dannyplusplus12/FISD-R |
| Thư mục local | `D:\Dev\APP\FISD` |

> **Lưu ý:** `backend-production-5efd` là project CŨ, không dùng nữa.

---

## Cấu Trúc Thư Mục

```
FISD/
├── backend/
│   ├── app/
│   │   ├── main.py              # Khởi động app, đăng ký router, seed dữ liệu mặc định
│   │   ├── models/              # SQLAlchemy ORM models
│   │   │   ├── san_pham.py      # SanPham, BienThe
│   │   │   ├── khach_hang.py    # KhuVuc, KhachHang, LichSuNo
│   │   │   ├── nhan_vien.py     # NhanVien
│   │   │   └── don_hang.py      # DonHang, ChiTietDon
│   │   ├── routers/             # FastAPI routers
│   │   │   ├── san_pham.py      # /products, /product-images/
│   │   │   ├── khach_hang.py    # /areas, /customers
│   │   │   ├── nhan_vien.py     # /employees, /auth
│   │   │   └── don_hang.py      # /orders, /checkout, /delivery-proofs/
│   │   ├── schemas/             # Pydantic request/response schemas
│   │   ├── database.py          # SQLAlchemy engine + get_db()
│   │   └── config.py            # Cấu hình môi trường (DATABASE_URL, v.v.)
│   ├── Dockerfile
│   └── railway.json
│
└── frontend/
    └── lib/
        ├── main.dart            # Entry point → CongXacThuc
        ├── core/
        │   ├── theme.dart       # AppColors, buildAppTheme()
        │   ├── api/
        │   │   ├── api_client.dart   # Dio instance, kBackendUrl
        │   │   └── endpoints.dart    # Tất cả đường dẫn API
        │   └── session/
        │       └── session.dart      # SessionNotifier, UserRole
        ├── models/
        │   ├── san_pham.dart    # SanPham, BienThe
        │   ├── khach_hang.dart  # KhachHang, TomTatKhuVuc, LichSuNoItem
        │   ├── nhan_vien.dart   # NhanVien
        │   ├── don_hang.dart    # DonHang, ChiTietDon, MatHangGio
        │   └── muc_dieu_huong.dart  # MucDieuHuong (nav item)
        ├── features/
        │   ├── xac_thuc/        # Đăng nhập PIN
        │   ├── tong_quan/       # Dashboard tổng quan
        │   ├── san_pham/        # Quản lý sản phẩm
        │   ├── don_hang/        # Quản lý đơn hàng
        │   ├── khach_hang/      # Khách hàng + khu vực
        │   └── nhan_vien/       # Nhân viên (chỉ manager)
        └── widgets/
            ├── khung_app.dart   # KhungApp + CongXacThuc (shell chính)
            └── thanh_ben.dart   # ThanhBen (sidebar trái)
```

---

## Tên Tiếng Việt — Quy Ước Đặt Tên

| Tiếng Anh | Tiếng Việt |
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

---

## Xác Thực (Authentication)

- **Kiểu:** PIN 4 chữ số, không cần chọn vai trò
- **Endpoint:** `POST /xac-thuc/dang-nhap-pin`
- **Request:** `{ "pin": "1234" }`
- **Response:** `{ "id": 1, "name": "Tên NV", "phone": "...", "role": "manager" }`
- **Vai trò:** `orderer` | `picker` | `manager`

**Tài khoản mặc định (seed):**

| PIN | Vai trò |
|---|---|
| 0000 | manager |
| 1111 | picker |
| 2222 | orderer |

---

## API Endpoints

Base URL: `https://backend-production-0935.up.railway.app`

### Xác Thực

| Method | Path | Mô tả |
|---|---|---|
| POST | `/xac-thuc/dang-nhap-pin` | Đăng nhập bằng PIN |

### Sản Phẩm

| Method | Path | Mô tả |
|---|---|---|
| GET | `/san-pham` | Lấy danh sách sản phẩm |
| POST | `/san-pham` | Tạo sản phẩm mới |
| PUT | `/san-pham/{id}` | Cập nhật sản phẩm |
| DELETE | `/san-pham/{id}` | Xóa sản phẩm |
| POST | `/anh-san-pham/upload` | Upload ảnh sản phẩm |
| GET | `/anh-san-pham/{ten_file}` | Lấy ảnh sản phẩm |

### Khu Vực & Khách Hàng

| Method | Path | Mô tả |
|---|---|---|
| GET | `/khu-vuc` | Lấy danh sách khu vực |
| POST | `/khu-vuc` | Tạo khu vực |
| PUT | `/khu-vuc/{id}` | Cập nhật khu vực |
| DELETE | `/khu-vuc/{id}` | Xóa khu vực |
| GET | `/khach-hang` | Lấy danh sách khách hàng |
| POST | `/khach-hang` | Tạo khách hàng |
| PUT | `/khach-hang/{id}` | Cập nhật khách hàng |
| DELETE | `/khach-hang/{id}` | Xóa khách hàng |
| GET | `/khach-hang/{id}/lich-su-no` | Lịch sử công nợ |
| POST | `/khach-hang/{id}/lich-su-no` | Thêm bản ghi công nợ |
| DELETE | `/khach-hang/{id}/lich-su-no/{log_id}` | Xóa bản ghi công nợ |

### Nhân Viên

| Method | Path | Mô tả |
|---|---|---|
| GET | `/nhan-vien` | Danh sách nhân viên |
| POST | `/nhan-vien` | Tạo nhân viên |
| PUT | `/nhan-vien/{id}` | Cập nhật nhân viên |
| DELETE | `/nhan-vien/{id}` | Xóa nhân viên |
| GET | `/nhan-vien/{id}/giao-hang` | Lịch sử giao hàng |
| GET | `/nhan-vien/{id}/hoat-dong` | Hoạt động gần đây |

### Đơn Hàng

| Method | Path | Mô tả |
|---|---|---|
| GET | `/don-hang/cho-duyet` | Đơn chờ duyệt |
| GET | `/don-hang/da-duyet` | Đơn đã duyệt |
| GET | `/don-hang/quan-ly` | Tất cả đơn (manager) |
| GET | `/don-hang/da-nhan?picker_id={id}` | Đơn đã nhận (picker) |
| DELETE | `/don-hang/{id}` | Xóa đơn |
| PUT | `/don-hang/{id}/duyet` | Duyệt đơn |
| DELETE | `/don-hang/{id}/tu-choi` | Từ chối đơn |
| DELETE | `/don-hang/{id}/huy` | Hủy đơn (manager) |
| PUT | `/don-hang/{id}/nhan` | Picker nhận đơn |
| PUT | `/don-hang/{id}/giao-kem-anh` | Giao hàng + upload ảnh |
| PUT | `/don-hang/{id}/xac-nhan` | Xác nhận hoàn thành |
| POST | `/thanh-toan/nhap` | Tạo đơn nháp (orderer) |
| POST | `/thanh-toan/desktop` | Tạo đơn nhanh (desktop) |
| GET | `/bang-chung-giao/{ten_file}` | Ảnh bằng chứng giao hàng |

### Dashboard

| Method | Path | Mô tả |
|---|---|---|
| GET | `/thong-ke` | Thống kê tổng quan |

---

## Luồng Đơn Hàng

```
pending → approved → assigned → completed
           ↓            ↓
         rejected     (picker nhận)
```

1. **Orderer** tạo đơn → trạng thái `pending`
2. **Manager** duyệt → `approved`; hoặc từ chối → xóa
3. **Picker** nhận đơn → `assigned`
4. **Picker** giao + upload ảnh → `completed`

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

**Biến môi trường backend:**
```
DATABASE_URL=postgresql://user:pass@host/db
TELEGRAM_BOT_TOKEN=...   (tuỳ chọn, backup đơn hàng)
TELEGRAM_CHAT_ID=...
CORS_ALLOWED_ORIGINS=http://localhost:*
```

---

## Deploy (Railway)

- Backend tự động build từ `backend/Dockerfile` khi push lên `master`
- Cấu hình: `backend/railway.json`
- Postgres được cấp sẵn bởi Railway, kết nối qua `DATABASE_URL`
- Dữ liệu mặc định được seed tự động khi khởi động lần đầu

```bash
git push origin master   # trigger Railway redeploy
```
