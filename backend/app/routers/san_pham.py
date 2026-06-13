import os
import uuid
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from fastapi.responses import FileResponse
from sqlalchemy import desc
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import SanPham, BienThe
from app.schemas.san_pham import TaoSanPham, CapNhatSanPham
from app.utils import now_vn
from app.core.config import settings

router = APIRouter(prefix="/san-pham", tags=["Sản phẩm"])

_EXTENSIONS_HOP_LE = {".jpg", ".jpeg", ".png", ".webp", ".heic", ".bmp"}
_MAX_ANH_BYTES = settings.MAX_DELIVERY_PHOTO_MB * 1024 * 1024


def _thu_muc_upload() -> str:
    thu_muc = settings.DELIVERY_UPLOAD_DIR or "/tmp/delivery_proofs"
    os.makedirs(thu_muc, exist_ok=True)
    return thu_muc


def _luu_anh_san_pham(file: UploadFile) -> str:
    ten_file = (file.filename or "product.jpg").strip()
    ext = os.path.splitext(ten_file)[1].lower()
    if ext not in _EXTENSIONS_HOP_LE:
        raise HTTPException(status_code=400, detail="Ảnh phải là jpg/png/webp/heic/bmp")
    ten_an_toan = f"product_{now_vn().strftime('%Y%m%d%H%M%S')}_{uuid.uuid4().hex[:8]}{ext}"
    duong_dan = os.path.join(_thu_muc_upload(), ten_an_toan)
    with open(duong_dan, "wb") as f:
        while True:
            chunk = file.file.read(1024 * 1024)
            if not chunk:
                break
            f.write(chunk)
    return f"/anh-san-pham/{ten_an_toan}"


@router.get("")
def lay_danh_sach(search: str = "", db: Session = Depends(get_db)):
    query = db.query(SanPham)
    if search:
        s = f"%{search}%"
        query = query.filter((SanPham.name.ilike(s)) | (SanPham.code.ilike(s)))
    san_pham = query.order_by(desc(SanPham.id)).all()
    ket_qua = []
    for sp in san_pham:
        gia_list = [bt.price for bt in sp.variants]
        khoang_gia = "Hết hàng"
        if gia_list:
            mn, mx = min(gia_list), max(gia_list)
            khoang_gia = f"{mn:,} - {mx:,}" if mn != mx else f"{mn:,}"
        ket_qua.append({
            "id": sp.id, "code": sp.code or sp.name, "name": sp.name,
            "image": sp.image_path, "price_range": khoang_gia,
            "variants": [{"id": bt.id, "color": bt.color, "size": bt.size, "price": bt.price, "stock": bt.stock} for bt in sp.variants],
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
    if sp:
        db.query(BienThe).filter(BienThe.product_id == sp_id).delete()
        db.delete(sp)
        db.commit()
    return {"status": "deleted"}


# Ảnh sản phẩm (đặt ngoài prefix /products)
anh_router = APIRouter(tags=["Sản phẩm"])


@anh_router.post("/anh-san-pham/upload")
def upload_anh(file: UploadFile = File(...)):
    return {"path": _luu_anh_san_pham(file)}


@anh_router.get("/anh-san-pham/{ten_file}")
def lay_anh(ten_file: str):
    ten_an_toan = os.path.basename(ten_file)
    if ten_an_toan != ten_file:
        raise HTTPException(status_code=400, detail="Tên file không hợp lệ")
    abs_path = os.path.join(_thu_muc_upload(), ten_an_toan)
    if not os.path.exists(abs_path):
        raise HTTPException(status_code=404, detail="Không tìm thấy ảnh")
    return FileResponse(abs_path)
