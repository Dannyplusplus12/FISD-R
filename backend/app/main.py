from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app.core.config import settings
from app.database import Base, engine, SessionLocal
from app.routers import san_pham, nhan_vien, khach_hang, don_hang, bao_cao, lenh_nhanh


def _khoi_tao_db():
    try:
        Base.metadata.create_all(bind=engine)
        _them_cot_neu_thieu()
        _seed_mac_dinh()
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
    # Thêm cột mới vào đây khi cần mở rộng schema
    # Ví dụ: ("don_hang", "ten_cot_moi", "TEXT DEFAULT ''")
    alterations = []
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
