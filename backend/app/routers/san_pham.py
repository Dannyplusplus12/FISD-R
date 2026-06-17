import os
import uuid
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy import desc
from sqlalchemy.orm import Session

from app import s3
from app.database import get_db
from app.models import SanPham, BienThe, ChiTietDon
from app.schemas.san_pham import TaoSanPham, CapNhatSanPham
from app.utils import now_vn
from app.core.config import settings

router = APIRouter(prefix="/san-pham", tags=["Sản phẩm"])

_EXTENSIONS_HOP_LE = {".jpg", ".jpeg", ".png", ".webp", ".heic", ".bmp"}
_MAX_ANH_BYTES = settings.MAX_DELIVERY_PHOTO_MB * 1024 * 1024


def _upload_anh_s3(file: UploadFile) -> str:
    ten_file = (file.filename or "product.jpg").strip()
    ext = os.path.splitext(ten_file)[1].lower()
    if ext not in _EXTENSIONS_HOP_LE:
        raise HTTPException(status_code=400, detail="Ảnh phải là jpg/png/webp/heic/bmp")
    data = file.file.read()
    if len(data) > _MAX_ANH_BYTES:
        raise HTTPException(status_code=400, detail=f"Ảnh vượt giới hạn {settings.MAX_DELIVERY_PHOTO_MB}MB")
    ten_an_toan = f"product_{now_vn().strftime('%Y%m%d%H%M%S')}_{uuid.uuid4().hex[:8]}{ext}"
    return s3.upload_bytes(data, f"san-pham/{ten_an_toan}", ext)


def _la_s3_key(duong_dan: str) -> bool:
    return bool(duong_dan) and not duong_dan.startswith("/") and not duong_dan.startswith("http")


@router.get("")
def lay_danh_sach(search: str = "", db: Session = Depends(get_db)):
    query = db.query(SanPham)
    if search:
        tu_khoa = f"%{search}%"
        query = query.filter((SanPham.name.ilike(tu_khoa)) | (SanPham.code.ilike(tu_khoa)))
    san_pham = query.order_by(desc(SanPham.id)).all()
    ket_qua = []
    for sp in san_pham:
        gia_list = [bt.price for bt in sp.variants]
        khoang_gia = "Hết hàng"
        if gia_list:
            mn, mx = min(gia_list), max(gia_list)
            khoang_gia = f"{mn:,} - {mx:,}" if mn != mx else f"{mn:,}"
        key = sp.image_path or ""
        ket_qua.append({
            "id": sp.id, "code": sp.code or sp.name, "name": sp.name,
            "image_key": key if _la_s3_key(key) else "",
            "image": s3.presigned_url(key) if _la_s3_key(key) else "",
            "price_range": khoang_gia,
            "variants": [
                {"id": bt.id, "color": bt.color, "size": bt.size, "price": bt.price, "stock": bt.stock}
                for bt in sp.variants
            ],
        })
    return ket_qua


@router.post("")
def tao_san_pham(data: TaoSanPham, db: Session = Depends(get_db)):
    ma = (data.code or "").strip() or data.name
    sp = SanPham(code=ma, name=data.name, description=data.description, image_path=data.image_path)
    db.add(sp)
    db.commit()
    db.refresh(sp)
    for bt in data.variants:
        db.add(BienThe(product_id=sp.id, color=bt.color, size=bt.size, price=bt.price, stock=bt.stock))
    db.commit()
    return {"status": "ok"}


@router.put("/{sp_id}")
def cap_nhat_san_pham(sp_id: int, data: CapNhatSanPham, db: Session = Depends(get_db)):
    sp = db.query(SanPham).filter(SanPham.id == sp_id).first()
    if not sp:
        raise HTTPException(status_code=404)
    sp.code = (data.code or "").strip() or data.name
    sp.name = data.name
    sp.image_path = data.image_path
    bien_the_hien_tai = {bt.id: bt for bt in sp.variants}
    id_hien_tai = set(bien_the_hien_tai.keys())
    id_moi = {bt.id for bt in data.variants if bt.id is not None}
    for xoa_id in id_hien_tai - id_moi:
        db.delete(bien_the_hien_tai[xoa_id])
    for bt_data in data.variants:
        if bt_data.id and bt_data.id in id_hien_tai:
            bt = bien_the_hien_tai[bt_data.id]
            bt.color, bt.size, bt.price, bt.stock = bt_data.color, bt_data.size, bt_data.price, bt_data.stock
        else:
            db.add(BienThe(product_id=sp.id, color=bt_data.color, size=bt_data.size, price=bt_data.price, stock=bt_data.stock))
    db.commit()
    return {"status": "updated"}


@router.delete("/{sp_id}")
def xoa_san_pham(sp_id: int, db: Session = Depends(get_db)):
    sp = db.query(SanPham).filter(SanPham.id == sp_id).first()
    if not sp:
        raise HTTPException(status_code=404, detail="Sản phẩm không tồn tại")
    bien_thes = db.query(BienThe).filter(BienThe.product_id == sp_id).all()
    variant_ids = [bt.id for bt in bien_thes if bt.id is not None]
    if variant_ids:
        db.query(ChiTietDon).filter(ChiTietDon.variant_id.in_(variant_ids)).delete(synchronize_session=False)
    db.query(BienThe).filter(BienThe.product_id == sp_id).delete(synchronize_session=False)
    db.delete(sp)
    db.commit()
    return {"status": "deleted"}


# Ảnh sản phẩm
anh_router = APIRouter(tags=["Sản phẩm"])


@anh_router.post("/anh-san-pham/upload")
def upload_anh(file: UploadFile = File(...)):
    return {"path": _upload_anh_s3(file)}
