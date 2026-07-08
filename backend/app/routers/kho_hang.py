import json
import os
import uuid
from typing import Optional

from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, UploadFile
from pydantic import BaseModel
from sqlalchemy import func as sqla_func
from sqlalchemy.orm import Session

from app import s3
from app.core.config import settings
from app.database import get_db
from app.models import BienThe, DonHang, KhoHang, NhanVien, SanPham, ViTriBienThe
from app.utils import now_vn, parse_duong_dan_anh

router = APIRouter(tags=["Kho hàng"])

_EXTENSIONS_HOP_LE = {".jpg", ".jpeg", ".png", ".webp", ".heic"}
_MAX_ANH_BYTES = settings.MAX_DELIVERY_PHOTO_MB * 1024 * 1024


# ── Schema ────────────────────────────────────────────────────────────────────

class TaoKhoHang(BaseModel):
    ten: str
    vi_tri: str = ""
    ghi_chu: str = ""


class CapNhatKhoHang(BaseModel):
    ten: str
    vi_tri: str = ""
    ghi_chu: str = ""


class CapNhatBienThe(BaseModel):
    color: str = ""
    size: str = ""
    price: int = 0
    stock: int = 0


class ThemBienThe(BaseModel):
    product_id: int
    color: str = ""
    size: str = ""
    price: int = 0
    stock: int = 0


class CapNhatGhiChuPicker(BaseModel):
    picker_id: int
    ghi_chu: str = ""


class CapNhatSoLuong(BaseModel):
    so_luong: int


class ThemBienTheVaoKho(BaseModel):
    bt_id: int
    so_luong: int = 0


# ── Helper ───────────────────────────────────────────────────────────────────

def _la_s3_key(duong_dan: str) -> bool:
    return bool(duong_dan) and not duong_dan.startswith("/") and not duong_dan.startswith("http")


def _tinh_lai_ton_kho(bt_id: int, db: Session):
    tong = db.query(sqla_func.sum(ViTriBienThe.so_luong)).filter(
        ViTriBienThe.ma_bien_the == bt_id
    ).scalar() or 0
    bt = db.query(BienThe).filter(BienThe.id == bt_id).first()
    if bt:
        bt.stock = int(tong)


def _serialize_kho(kho: KhoHang) -> dict:
    return {"id": kho.id, "ten": kho.ten, "vi_tri": kho.vi_tri or "", "ghi_chu": kho.ghi_chu or ""}


def _kho_cua_bien_the(bt_id: int, db: Session) -> list:
    rows = db.query(ViTriBienThe).filter(ViTriBienThe.ma_bien_the == bt_id).all()
    result = []
    for r in rows:
        if r.kho_hang:
            result.append({"id": r.kho_hang.id, "ten": r.kho_hang.ten, "vi_tri": r.kho_hang.vi_tri or ""})
    return result


def _serialize_bien_the(bt: BienThe, db: Session) -> dict:
    return {
        "id": bt.id,
        "color": bt.color or "",
        "size": bt.size or "",
        "price": int(bt.price or 0),
        "stock": int(bt.stock or 0),
        "warehouses": _kho_cua_bien_the(bt.id, db),
    }


# ── Kho hàng CRUD ─────────────────────────────────────────────────────────────

@router.get("/kho-hang")
def lay_danh_sach_kho(db: Session = Depends(get_db)):
    return [_serialize_kho(k) for k in db.query(KhoHang).order_by(KhoHang.id).all()]


@router.post("/kho-hang")
def tao_kho(data: TaoKhoHang, db: Session = Depends(get_db)):
    kho = KhoHang(ten=data.ten.strip(), vi_tri=data.vi_tri.strip(), ghi_chu=data.ghi_chu.strip())
    db.add(kho)
    db.commit()
    db.refresh(kho)
    return _serialize_kho(kho)


@router.put("/kho-hang/{kho_id}")
def cap_nhat_kho(kho_id: int, data: CapNhatKhoHang, db: Session = Depends(get_db)):
    kho = db.query(KhoHang).filter(KhoHang.id == kho_id).first()
    if not kho:
        raise HTTPException(status_code=404, detail="Kho không tồn tại")
    kho.ten = data.ten.strip()
    kho.vi_tri = data.vi_tri.strip()
    kho.ghi_chu = data.ghi_chu.strip()
    db.commit()
    return _serialize_kho(kho)


@router.delete("/kho-hang/{kho_id}")
def xoa_kho(kho_id: int, db: Session = Depends(get_db)):
    kho = db.query(KhoHang).filter(KhoHang.id == kho_id).first()
    if not kho:
        raise HTTPException(status_code=404, detail="Kho không tồn tại")
    db.delete(kho)
    db.commit()
    return {"status": "deleted"}


# ── Biến thể CRUD ─────────────────────────────────────────────────────────────

@router.post("/bien-the")
def them_bien_the(data: ThemBienThe, db: Session = Depends(get_db)):
    sp = db.query(SanPham).filter(SanPham.id == data.product_id).first()
    if not sp:
        raise HTTPException(status_code=404, detail="Sản phẩm không tồn tại")
    bt = BienThe(product_id=data.product_id, color=data.color, size=data.size,
                 price=data.price, stock=data.stock)
    db.add(bt)
    db.flush()
    # Tự động tạo vi_tri_bien_the cho tất cả kho đã gán cho các biến thể khác của cùng sản phẩm
    other_ids = [v.id for v in sp.variants if v.id != bt.id]
    if other_ids:
        kho_ids = {row[0] for row in db.query(ViTriBienThe.ma_kho).filter(
            ViTriBienThe.ma_bien_the.in_(other_ids)).distinct().all()}
        for kho_id in kho_ids:
            db.add(ViTriBienThe(ma_bien_the=bt.id, ma_kho=kho_id, so_luong=0))
    db.commit()
    db.refresh(bt)
    return _serialize_bien_the(bt, db)


@router.put("/bien-the/{bt_id}")
def cap_nhat_bien_the(bt_id: int, data: CapNhatBienThe, db: Session = Depends(get_db)):
    bt = db.query(BienThe).filter(BienThe.id == bt_id).first()
    if not bt:
        raise HTTPException(status_code=404, detail="Biến thể không tồn tại")
    bt.color = data.color
    bt.size = data.size
    bt.price = data.price
    bt.stock = data.stock
    db.commit()
    return _serialize_bien_the(bt, db)


@router.delete("/bien-the/{bt_id}")
def xoa_bien_the(bt_id: int, db: Session = Depends(get_db)):
    bt = db.query(BienThe).filter(BienThe.id == bt_id).first()
    if not bt:
        raise HTTPException(status_code=404, detail="Biến thể không tồn tại")
    db.delete(bt)
    db.commit()
    return {"status": "deleted"}


# ── Gán kho cho biến thể ──────────────────────────────────────────────────────

@router.post("/bien-the/{bt_id}/kho/{kho_id}")
def them_kho_cho_bien_the(bt_id: int, kho_id: int, db: Session = Depends(get_db)):
    bt = db.query(BienThe).filter(BienThe.id == bt_id).first()
    if not bt:
        raise HTTPException(status_code=404, detail="Biến thể không tồn tại")
    kho = db.query(KhoHang).filter(KhoHang.id == kho_id).first()
    if not kho:
        raise HTTPException(status_code=404, detail="Kho không tồn tại")
    da_co = db.query(ViTriBienThe).filter(
        ViTriBienThe.ma_bien_the == bt_id, ViTriBienThe.ma_kho == kho_id
    ).first()
    if not da_co:
        db.add(ViTriBienThe(ma_bien_the=bt_id, ma_kho=kho_id))
        db.commit()
    return {"status": "ok", "warehouses": _kho_cua_bien_the(bt_id, db)}


@router.delete("/bien-the/{bt_id}/kho/{kho_id}")
def xoa_kho_khoi_bien_the(bt_id: int, kho_id: int, db: Session = Depends(get_db)):
    row = db.query(ViTriBienThe).filter(
        ViTriBienThe.ma_bien_the == bt_id, ViTriBienThe.ma_kho == kho_id
    ).first()
    if row:
        db.delete(row)
        db.commit()
    return {"status": "ok", "warehouses": _kho_cua_bien_the(bt_id, db)}


# ── Gán kho hàng loạt cho TẤT CẢ biến thể của sản phẩm ─────────────────────

@router.post("/san-pham/{sp_id}/kho/{kho_id}")
def them_kho_cho_san_pham(sp_id: int, kho_id: int, db: Session = Depends(get_db)):
    sp = db.query(SanPham).filter(SanPham.id == sp_id).first()
    if not sp:
        raise HTTPException(status_code=404, detail="Sản phẩm không tồn tại")
    kho = db.query(KhoHang).filter(KhoHang.id == kho_id).first()
    if not kho:
        raise HTTPException(status_code=404, detail="Kho không tồn tại")
    for bt in sp.variants:
        da_co = db.query(ViTriBienThe).filter(
            ViTriBienThe.ma_bien_the == bt.id, ViTriBienThe.ma_kho == kho_id
        ).first()
        if not da_co:
            db.add(ViTriBienThe(ma_bien_the=bt.id, ma_kho=kho_id))
    db.commit()
    return {"status": "ok"}


@router.delete("/san-pham/{sp_id}/kho/{kho_id}")
def xoa_kho_khoi_san_pham(sp_id: int, kho_id: int, db: Session = Depends(get_db)):
    sp = db.query(SanPham).filter(SanPham.id == sp_id).first()
    if not sp:
        raise HTTPException(status_code=404, detail="Sản phẩm không tồn tại")
    bt_ids = [bt.id for bt in sp.variants]
    if bt_ids:
        db.query(ViTriBienThe).filter(
            ViTriBienThe.ma_bien_the.in_(bt_ids), ViTriBienThe.ma_kho == kho_id
        ).delete(synchronize_session=False)
        db.commit()
    return {"status": "ok"}


# ── Warehouse-centric: xem / thêm / xóa / sửa số lượng ──────────────────────

@router.get("/kho-hang/{kho_id}/san-pham")
def lay_san_pham_trong_kho(kho_id: int, db: Session = Depends(get_db)):
    kho = db.query(KhoHang).filter(KhoHang.id == kho_id).first()
    if not kho:
        raise HTTPException(status_code=404, detail="Kho không tồn tại")
    rows = db.query(ViTriBienThe).filter(ViTriBienThe.ma_kho == kho_id).all()
    sp_map: dict = {}
    for row in rows:
        bt = db.query(BienThe).filter(BienThe.id == row.ma_bien_the).first()
        if not bt or not getattr(bt, "san_pham", None):
            continue
        sp = bt.san_pham
        if sp.id not in sp_map:
            key = sp.image_path or ""
            sp_map[sp.id] = {
                "id": sp.id, "ten": sp.name,
                "image": s3.presigned_url(key) if _la_s3_key(key) else "",
                "bien_thes": [],
            }
        sp_map[sp.id]["bien_thes"].append({
            "id": bt.id, "mau_sac": bt.color or "", "kich_co": bt.size or "",
            "don_gia": int(bt.price or 0), "so_luong": int(row.so_luong or 0),
        })
    return list(sp_map.values())


@router.post("/kho-hang/{kho_id}/bien-the/{bt_id}")
def them_bien_the_vao_kho(kho_id: int, bt_id: int, data: ThemBienTheVaoKho, db: Session = Depends(get_db)):
    if not db.query(KhoHang).filter(KhoHang.id == kho_id).first():
        raise HTTPException(status_code=404, detail="Kho không tồn tại")
    if not db.query(BienThe).filter(BienThe.id == bt_id).first():
        raise HTTPException(status_code=404, detail="Biến thể không tồn tại")
    da_co = db.query(ViTriBienThe).filter(
        ViTriBienThe.ma_bien_the == bt_id, ViTriBienThe.ma_kho == kho_id
    ).first()
    if da_co:
        da_co.so_luong = max(0, data.so_luong)
    else:
        db.add(ViTriBienThe(ma_bien_the=bt_id, ma_kho=kho_id, so_luong=max(0, data.so_luong)))
    _tinh_lai_ton_kho(bt_id, db)
    db.commit()
    return {"status": "ok"}


@router.put("/kho-hang/{kho_id}/bien-the/{bt_id}/so-luong")
def cap_nhat_so_luong(kho_id: int, bt_id: int, data: CapNhatSoLuong, db: Session = Depends(get_db)):
    row = db.query(ViTriBienThe).filter(
        ViTriBienThe.ma_bien_the == bt_id, ViTriBienThe.ma_kho == kho_id
    ).first()
    if not row:
        raise HTTPException(status_code=404, detail="Biến thể không có trong kho này")
    row.so_luong = max(0, data.so_luong)
    _tinh_lai_ton_kho(bt_id, db)
    db.commit()
    return {"status": "ok", "so_luong": row.so_luong}


@router.delete("/kho-hang/{kho_id}/bien-the/{bt_id}")
def xoa_bien_the_khoi_kho(kho_id: int, bt_id: int, db: Session = Depends(get_db)):
    row = db.query(ViTriBienThe).filter(
        ViTriBienThe.ma_bien_the == bt_id, ViTriBienThe.ma_kho == kho_id
    ).first()
    if row:
        db.delete(row)
        _tinh_lai_ton_kho(bt_id, db)
        db.commit()
    return {"status": "ok"}


# ── Sửa ghi chú + ảnh đơn cũ (picker) ───────────────────────────────────────

@router.put("/don-hang/{don_id}/ghi-chu-picker")
def sua_ghi_chu_picker(don_id: int, data: CapNhatGhiChuPicker, db: Session = Depends(get_db)):
    don = db.query(DonHang).filter(DonHang.id == don_id, DonHang.status == "completed").first()
    if not don:
        raise HTTPException(status_code=404, detail="Đơn hàng không tồn tại")
    if don.delivered_by_id != data.picker_id:
        raise HTTPException(status_code=403, detail="Bạn không có quyền sửa đơn này")
    don.picker_note = data.ghi_chu.strip()
    db.commit()
    return {"status": "ok"}


@router.post("/don-hang/{don_id}/them-anh")
async def them_anh_don(
    don_id: int,
    picker_id: int = Form(...),
    photo: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    don = db.query(DonHang).filter(DonHang.id == don_id, DonHang.status == "completed").first()
    if not don:
        raise HTTPException(status_code=404, detail="Đơn hàng không tồn tại")
    if don.delivered_by_id != picker_id and don.created_by_employee_id != picker_id:
        raise HTTPException(status_code=403, detail="Bạn không có quyền sửa đơn này")
    ten_file = (photo.filename or "proof.jpg").strip()
    ext = os.path.splitext(ten_file)[1].lower()
    if ext not in _EXTENSIONS_HOP_LE:
        raise HTTPException(status_code=400, detail="Ảnh phải là jpg/png/webp/heic")
    data_bytes = photo.file.read()
    if len(data_bytes) > _MAX_ANH_BYTES:
        raise HTTPException(status_code=400, detail=f"Ảnh vượt giới hạn {settings.MAX_DELIVERY_PHOTO_MB}MB")
    ten_an_toan = f"order_{don_id}_{now_vn().strftime('%Y%m%d%H%M%S')}_{uuid.uuid4().hex[:8]}{ext}"
    key = s3.upload_bytes(data_bytes, f"giao-hang/{ten_an_toan}", ext)
    current = parse_duong_dan_anh(don.delivery_photo_path)
    current.append(key)
    don.delivery_photo_path = json.dumps(current, ensure_ascii=False)
    db.commit()
    return {"status": "ok", "key": key, "url": s3.presigned_url(key)}


@router.delete("/don-hang/{don_id}/xoa-anh")
def xoa_anh_don(
    don_id: int,
    picker_id: int = Query(...),
    key: str = Query(...),
    db: Session = Depends(get_db),
):
    don = db.query(DonHang).filter(DonHang.id == don_id, DonHang.status == "completed").first()
    if not don:
        raise HTTPException(status_code=404, detail="Đơn hàng không tồn tại")
    if don.delivered_by_id != picker_id and don.created_by_employee_id != picker_id:
        raise HTTPException(status_code=403, detail="Bạn không có quyền sửa đơn này")
    current = parse_duong_dan_anh(don.delivery_photo_path)
    if key in current:
        current.remove(key)
    don.delivery_photo_path = json.dumps(current, ensure_ascii=False) if current else ""
    db.commit()
    return {"status": "ok", "remaining": len(current)}
