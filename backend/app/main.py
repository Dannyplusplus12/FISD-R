from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app.core.config import settings
from app.database import Base, engine, SessionLocal
from app.routers import san_pham, nhan_vien, khach_hang, don_hang, bao_cao, lenh_nhanh, kho_hang


def _khoi_tao_db():
    try:
        Base.metadata.create_all(bind=engine)
        _them_cot_neu_thieu()
        _seed_mac_dinh()
        _seed_kho_hang()
    except Exception as e:
        print(f"Warning: DB init skipped — {e}")


def _them_cot_neu_thieu():
    from app.database import IS_SQLITE
    db = SessionLocal()
    try:
        if IS_SQLITE:
            _them_cot_sqlite(db)
        else:
            _them_cot_postgres(db)
        db.commit()
    except Exception as e:
        print(f"Warning: column migration skipped — {e}")
    finally:
        db.close()


def _them_cot_sqlite(db):
    # Thêm cột mới vào đây khi cần mở rộng schema
    pass


def _them_cot_postgres(db):
    alterations = [
        ("vi_tri_bien_the", "so_luong", "INTEGER DEFAULT 0"),
    ]
    for table, col, col_type in alterations:
        try:
            db.execute(text(f"ALTER TABLE {table} ADD COLUMN IF NOT EXISTS {col} {col_type}"))
        except Exception:
            pass


def _add_col_safe(db, sql: str, table: str, col: str):
    try:
        result = db.execute(text(f"PRAGMA table_info({table})"))
        cols = [row[1] for row in result.fetchall()]
        if col not in cols:
            db.execute(text(sql))
    except Exception:
        pass


def _seed_mac_dinh():
    from app.models import KhuVuc, NhanVien
    db = SessionLocal()
    try:
        if not db.query(KhuVuc).first():
            db.add(KhuVuc(name="Khu vực mặc định"))
            db.commit()
        if not db.query(NhanVien).first():
            from app.utils import now_vn
            now_str = now_vn().strftime("%Y-%m-%d %H:%M")
            db.add_all([
                NhanVien(name="Quản lý", phone="", email="", address="", notes="",
                         role="manager", pin="0000", is_active=1, created_at=now_str),
                NhanVien(name="Nhân viên 1", phone="", email="", address="", notes="",
                         role="orderer", pin="1111", is_active=1, created_at=now_str),
                NhanVien(name="Picker 1", phone="", email="", address="", notes="",
                         role="picker", pin="2222", is_active=1, created_at=now_str),
            ])
            db.commit()
    except Exception as e:
        print(f"Warning: seeding skipped — {e}")
        db.rollback()
    finally:
        db.close()


def _seed_kho_hang():
    from app.models import KhoHang, BienThe, ViTriBienThe
    db = SessionLocal()
    try:
        existing = {k.ten for k in db.query(KhoHang).all()}
        for i in range(1, 5):
            if f"Kho {i}" not in existing:
                db.add(KhoHang(ten=f"Kho {i}", vi_tri="", ghi_chu=""))
        db.commit()
        kho1 = db.query(KhoHang).filter(KhoHang.ten == "Kho 1").first()
        if not kho1:
            return
        bts = db.query(BienThe).all()
        for bt in bts:
            has = db.query(ViTriBienThe).filter(ViTriBienThe.ma_bien_the == bt.id).first()
            if not has:
                if not bt.color:
                    bt.color = "Đen"
                if not bt.size:
                    bt.size = "40"
                db.add(ViTriBienThe(ma_bien_the=bt.id, ma_kho=kho1.id, so_luong=500))
        db.commit()
    except Exception as e:
        print(f"Warning: kho hang seed skipped — {e}")
        db.rollback()
    finally:
        db.close()


@asynccontextmanager
async def lifespan(app: FastAPI):
    _khoi_tao_db()
    yield


app = FastAPI(title="FISD API", version="1.0.0", lifespan=lifespan)

cors_origins = [o.strip() for o in settings.CORS_ALLOWED_ORIGINS.split(",") if o.strip()]
if not cors_origins or cors_origins == ["*"]:
    cors_origins = ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routers
app.include_router(san_pham.router)
app.include_router(san_pham.anh_router)
app.include_router(nhan_vien.router)
app.include_router(nhan_vien.auth_router)
app.include_router(khach_hang.khu_vuc_router)
app.include_router(khach_hang.khach_hang_router)
app.include_router(don_hang.router)
app.include_router(don_hang.anh_router)
app.include_router(bao_cao.router)
app.include_router(lenh_nhanh.router)
app.include_router(kho_hang.router)


@app.post("/admin/khoi-tao-kho")
def admin_khoi_tao_kho():
    """Reset toàn bộ bien_the + vi_tri_bien_the, tạo 4 kho, mỗi sp 1 biến thể Đen/40/500."""
    from app.models import KhoHang, BienThe, ViTriBienThe, SanPham
    db = SessionLocal()
    try:
        db.query(ViTriBienThe).delete(synchronize_session=False)
        db.query(BienThe).delete(synchronize_session=False)
        db.commit()
        for i in range(1, 5):
            if not db.query(KhoHang).filter(KhoHang.ten == f"Kho {i}").first():
                db.add(KhoHang(ten=f"Kho {i}", vi_tri="", ghi_chu=""))
        db.commit()
        kho1 = db.query(KhoHang).filter(KhoHang.ten == "Kho 1").first()
        sps = db.query(SanPham).all()
        for sp in sps:
            bt = BienThe(product_id=sp.id, color="Đen", size="40", price=0, stock=500)
            db.add(bt)
            db.flush()
            db.add(ViTriBienThe(ma_bien_the=bt.id, ma_kho=kho1.id, so_luong=500))
        db.commit()
        return {"status": "ok", "san_pham": len(sps), "kho_1_id": kho1.id}
    except Exception as e:
        db.rollback()
        return {"status": "error", "detail": str(e)}
    finally:
        db.close()


@app.post("/admin/import-gia")
def admin_import_gia():
    """Xóa sản phẩm không có lịch sử đơn, cập nhật giá từ dữ liệu tham chiếu."""
    from app.models import KhoHang, BienThe, ViTriBienThe, SanPham
    GIA_THAM_CHIEU = {
        'BCRO': 90000, 'BNIKE': 60000, 'CHUCAO': 100000, 'CHUTHAP': 85000,
        'DEPLONG': 150000, 'G5320': 330000, 'G8820': 360000, 'GA175': 245000,
        'GA176': 265000, 'GA176 N': 260000, 'GA180': 240000, 'GIAYNAM': 265000,
        'GON532': 330000, 'GS5205': 255000, 'GTIGE': 295000, 'GV18': 235000,
        'HOKA2': 175000, 'KCRO': 90000, 'LOANGNAM': 100000, 'LOANGNU': 100000,
        'LONGDEN': 150000, 'NIKE2': 95000, 'NIKETQ': 85000, 'SAMBA': 180000,
        'SDHOKA1': 140000, 'SDHOKAXIN': 210000, 'SRIENGTQ': 80000, 'STE': 75000,
        'TRONCAO': 100000, 'TRONTHAP': 85000, 'VIENTQ': 88000, 'XEAD': 102000,
    }
    db = SessionLocal()
    try:
        tat_ca = db.query(SanPham).all()
        xoa, giu = 0, 0
        for sp in tat_ca:
            if sp.name not in GIA_THAM_CHIEU and (sp.code or '') not in GIA_THAM_CHIEU:
                db.query(ViTriBienThe).filter(
                    ViTriBienThe.ma_bien_the.in_(
                        [bt.id for bt in db.query(BienThe).filter(BienThe.product_id == sp.id).all()]
                    )
                ).delete(synchronize_session=False)
                db.query(BienThe).filter(BienThe.product_id == sp.id).delete(synchronize_session=False)
                db.delete(sp)
                xoa += 1
            else:
                giu += 1
        db.commit()
        cap_nhat = 0
        for sp in db.query(SanPham).all():
            gia = GIA_THAM_CHIEU.get(sp.name) or GIA_THAM_CHIEU.get(sp.code or '')
            if gia is None:
                continue
            for bt in db.query(BienThe).filter(BienThe.product_id == sp.id).all():
                bt.price = gia
                cap_nhat += 1
        ton_kho_update = 0
        for bt in db.query(BienThe).all():
            tong = sum(v.so_luong for v in db.query(ViTriBienThe).filter(ViTriBienThe.ma_bien_the == bt.id).all())
            bt.stock = tong
            ton_kho_update += 1
        db.commit()
        return {"status": "ok", "xoa": xoa, "giu": giu, "cap_nhat_gia": cap_nhat}
    except Exception as e:
        db.rollback()
        return {"status": "error", "detail": str(e)}
    finally:
        db.close()


@app.get("/")
def root():
    return {"status": "ok", "app": "FISD API"}


@app.get("/health")
def health():
    return {"status": "healthy"}


@app.get("/thong-ke")
def stats():
    from app.models import SanPham, KhachHang, DonHang, NhanVien
    db = SessionLocal()
    try:
        tong_sp = db.query(SanPham).count()
        tong_kh = db.query(KhachHang).count()
        tong_don = db.query(DonHang).filter(DonHang.status == "completed").count()
        tong_no = sum(int(kh.debt or 0) for kh in db.query(KhachHang).all())
        cho_duyet = db.query(DonHang).filter(DonHang.status == "pending").count()
        da_duyet = db.query(DonHang).filter(DonHang.status == "approved").count()
        dang_giao = db.query(DonHang).filter(DonHang.status == "assigned").count()
        return {
            "total_products": tong_sp, "total_customers": tong_kh,
            "total_orders": tong_don, "total_debt": tong_no,
            "pending_orders": cho_duyet, "approved_orders": da_duyet,
            "delivering_orders": dang_giao,
        }
    except Exception as e:
        return {"error": str(e)}
    finally:
        db.close()
