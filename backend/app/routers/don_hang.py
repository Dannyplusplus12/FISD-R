import json
import os
import threading
import uuid
from typing import List, Optional

import httpx
from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from sqlalchemy import desc
from sqlalchemy.orm import Session

from app import s3
from app.core.config import settings
from app.database import get_db, SessionLocal
from app.models import (
    BienThe, ChiTietDon, DonHang, DonHangPicker, KenhChat, KhachHang, KhuVuc,
    NhanVien, SoanKhoTrangThai, ThanhVienKenh, ViTriBienThe, KhoHang, SanPham,
)
from app.realtime import quan_ly_ket_noi
from app.schemas.don_hang import (
    CapNhatNgayDon, XacNhanGiaoItem, XacNhanLocalAnh,
    YeuCauGiaoHang, YeuCauNhanDon, YeuCauThanhToan, YeuCauThemPicker, YeuCauXacNhanGiao,
)
from app.utils import now_vn, now_vn_ts, parse_duong_dan_anh

router = APIRouter(tags=["Đơn hàng"])

_EXTENSIONS_ANH_HOP_LE = {".jpg", ".jpeg", ".png", ".webp", ".heic"}
_MAX_ANH_BYTES = settings.MAX_DELIVERY_PHOTO_MB * 1024 * 1024


def _luu_anh_giao_hang(don_id: int, file: UploadFile) -> str:
    ten_file = (file.filename or "proof.jpg").strip()
    ext = os.path.splitext(ten_file)[1].lower()
    if ext not in _EXTENSIONS_ANH_HOP_LE:
        raise HTTPException(status_code=400, detail="Ảnh giao hàng phải là jpg/png/webp/heic")
    data = file.file.read()
    if len(data) > _MAX_ANH_BYTES:
        raise HTTPException(status_code=400, detail=f"Ảnh vượt giới hạn {settings.MAX_DELIVERY_PHOTO_MB}MB")
    ten_an_toan = f"order_{don_id}_{now_vn().strftime('%Y%m%d%H%M%S')}_{uuid.uuid4().hex[:8]}{ext}"
    return s3.upload_bytes(data, f"giao-hang/{ten_an_toan}", ext)


def _lay_khu_vuc_mac_dinh(db: Session):
    kv = db.query(KhuVuc).order_by(KhuVuc.id).first()
    return kv.id if kv else None


def _la_picker_cua_don(don_id: int, nhan_vien_id: int, db: Session) -> bool:
    return db.query(DonHangPicker).filter(
        DonHangPicker.ma_don_hang == don_id, DonHangPicker.ma_nhan_vien == nhan_vien_id
    ).first() is not None


def _dam_bao_kenh_don_hang(don: DonHang, db: Session) -> KenhChat:
    """Lấy hoặc tạo kênh chat tự động gắn với đơn hàng, đảm bảo mọi picker hiện tại của đơn đều là thành viên."""
    kenh = db.query(KenhChat).filter(KenhChat.ma_don_hang == don.id, KenhChat.loai == "kenh_don_hang").first()
    if not kenh:
        kenh = KenhChat(
            ten=f"Đơn #{don.id}", loai="kenh_don_hang", ma_don_hang=don.id,
            ma_chu_kenh=don.assigned_picker_id, thoi_gian_tao=now_vn().strftime("%Y-%m-%d %H:%M"),
        )
        db.add(kenh)
        db.flush()
    pickers = db.query(DonHangPicker).filter(DonHangPicker.ma_don_hang == don.id).all()
    for p in pickers:
        da_co = db.query(ThanhVienKenh).filter(
            ThanhVienKenh.ma_kenh == kenh.id, ThanhVienKenh.ma_nhan_vien == p.ma_nhan_vien
        ).first()
        if not da_co:
            db.add(ThanhVienKenh(
                ma_kenh=kenh.id, ma_nhan_vien=p.ma_nhan_vien,
                thoi_gian_tham_gia=now_vn().strftime("%Y-%m-%d %H:%M"),
            ))
    return kenh


def _them_nguoi_vao_don_va_kenh(don_id: int, picker_id: int, nguoi_them_id: int, db: Session) -> dict:
    don = db.query(DonHang).filter(DonHang.id == don_id).first()
    if not don:
        raise HTTPException(status_code=404, detail="Đơn hàng không tồn tại")
    if don.status != "assigned":
        raise HTTPException(status_code=400, detail="Chỉ thêm picker cho đơn đang giao")
    if not _la_picker_cua_don(don_id, nguoi_them_id, db):
        nguoi_them = db.query(NhanVien).filter(NhanVien.id == nguoi_them_id).first()
        if not nguoi_them or nguoi_them.role != "manager":
            raise HTTPException(status_code=403, detail="Chỉ picker của đơn hoặc quản lý mới được thêm người")
    picker = db.query(NhanVien).filter(NhanVien.id == picker_id).first()
    if not picker or picker.role not in ("picker", "manager"):
        raise HTTPException(status_code=400, detail="Picker không hợp lệ")
    if _la_picker_cua_don(don_id, picker_id, db):
        raise HTTPException(status_code=400, detail="Người này đã ở trong đơn")
    db.add(DonHangPicker(
        ma_don_hang=don_id, ma_nhan_vien=picker_id, la_nguoi_nhan_dau=0,
        thoi_gian_them=now_vn().strftime("%Y-%m-%d %H:%M"),
    ))
    db.flush()
    kenh = _dam_bao_kenh_don_hang(don, db)
    db.commit()

    thanh_vien_ids = [tv.ma_nhan_vien for tv in db.query(ThanhVienKenh).filter(ThanhVienKenh.ma_kenh == kenh.id).all()]
    quan_ly_ket_noi.broadcast_sync(thanh_vien_ids, {
        "type": "order_picker_added",
        "data": {"don_id": don_id, "picker_id": picker_id, "picker_name": picker.name, "kenh_id": kenh.id},
    })
    return {"status": "ok", "kenh_id": kenh.id, "picker_id": picker_id, "picker_name": picker.name}


def _serialize_don(don: DonHang) -> dict:
    chi_tiet, tong_sl = [], 0
    for ct in (don.chi_tiet or []):
        sl = int(ct.quantity or 0)
        tong_sl += sl
        chi_tiet.append({
            "order_item_id": ct.id, "product_name": ct.product_name,
            "variant_id": ct.variant_id, "variant_info": ct.variant_info,
            "quantity": sl, "price": int(ct.price or 0),
            "current_stock": None, "enough_stock": True,
        })
    raw_paths = parse_duong_dan_anh(don.delivery_photo_path)
    anh_paths = [
        url for url in (
            s3.presigned_url(p) for p in raw_paths
            if p and not p.startswith("/") and not p.startswith("local://")
        ) if url
    ]
    created_at_str = don.created_at if isinstance(don.created_at, str) else (don.created_at.strftime("%Y-%m-%d %H:%M") if don.created_at else "")
    assigned_at_str = don.assigned_at if isinstance(don.assigned_at, str) else (don.assigned_at.strftime("%Y-%m-%d %H:%M") if don.assigned_at else "")
    delivered_at_str = don.delivered_at if isinstance(don.delivered_at, str) else (don.delivered_at.strftime("%Y-%m-%d %H:%M") if don.delivered_at else "")
    return {
        "id": don.id,
        "created_at": created_at_str,
        "customer_name": don.customer_name or "Khách lẻ",
        "customer_id": don.customer_id,
        "total_amount": int(don.total_amount or 0),
        "total_qty": tong_sl,
        "status": don.status,
        "picker_note": (don.picker_note or ""),
        "created_by_employee_id": don.created_by_employee_id,
        "created_by_employee_name": (don.nguoi_tao.name if getattr(don, "nguoi_tao", None) else ""),
        "assigned_picker_id": don.assigned_picker_id,
        "assigned_picker_name": (don.picker.name if getattr(don, "picker", None) else ""),
        "assigned_at": assigned_at_str,
        "delivered_by_id": don.delivered_by_id,
        "delivered_by_name": (don.nguoi_giao.name if getattr(don, "nguoi_giao", None) else ""),
        "delivered_at": delivered_at_str,
        "delivery_photo_path": (don.delivery_photo_path or ""),
        "delivery_photo_paths": anh_paths,
        "items": chi_tiet,
        "pickers": [
            {"id": p.ma_nhan_vien, "name": (p.nhan_vien.name if p.nhan_vien else ""), "la_chinh": bool(p.la_nguoi_nhan_dau)}
            for p in (don.pickers or [])
        ],
    }


def _gui_anh_telegram_async(don_id: int, s3_keys: list, caption: str):
    try:
        token = settings.TELEGRAM_BOT_TOKEN
        chat_id = settings.TELEGRAM_CHAT_ID
        if not token or not chat_id or not s3_keys:
            return
        db = SessionLocal()
        try:
            with httpx.Client(timeout=60) as client:
                if len(s3_keys) == 1:
                    data = s3.download_bytes(s3_keys[0])
                    r = client.post(
                        f"https://api.telegram.org/bot{token}/sendPhoto",
                        files={"photo": ("photo.jpg", data, "image/jpeg")},
                        data={"chat_id": chat_id, "caption": caption},
                    )
                    if r.status_code == 200:
                        result = r.json().get("result") or {}
                        don = db.query(DonHang).filter(DonHang.id == don_id).first()
                        if don and result:
                            photos = result.get("photo") or []
                            if photos:
                                don.telegram_file_id = photos[-1].get("file_id", "")
                            don.telegram_message_id = str(result.get("message_id") or "")
                            db.commit()
                else:
                    files, media = {}, []
                    for i, key in enumerate(s3_keys):
                        field = f"file{i}"
                        files[field] = (f"photo{i}.jpg", s3.download_bytes(key), "image/jpeg")
                        item = {"type": "photo", "media": f"attach://{field}"}
                        if i == 0 and caption:
                            item["caption"] = caption
                        media.append(item)
                    client.post(
                        f"https://api.telegram.org/bot{token}/sendMediaGroup",
                        files=files,
                        data={"chat_id": chat_id, "media": json.dumps(media, ensure_ascii=False)},
                    )
        finally:
            db.close()
    except Exception as e:
        print("Warning: telegram backup failed:", e)


def _xoa_don_voi_logic(don: DonHang, db: Session):
    if don.status in ("completed", "approved", "assigned"):
        for ct in don.chi_tiet:
            if ct.variant_id:
                bt = db.query(BienThe).filter(BienThe.id == ct.variant_id).first()
                if bt:
                    bt.stock = (bt.stock or 0) + (ct.quantity or 0)
        if don.status == "completed" and don.customer_id:
            kh = db.query(KhachHang).filter(KhachHang.id == don.customer_id).first()
            if kh and don.total_amount:
                kh.debt = (kh.debt or 0) - int(don.total_amount or 0)
    db.query(ChiTietDon).filter(ChiTietDon.order_id == don.id).delete()
    db.delete(don)


# ─── Endpoints ─────────────────────────────────────────────────────────────────

@router.get("/don-hang")
def lay_don_hang(page: int = 1, limit: int = 20, db: Session = Depends(get_db)):
    try:
        skip = (page - 1) * limit
        tong = db.query(DonHang).filter(DonHang.status == "completed").count()
        don_hang = db.query(DonHang).filter(DonHang.status == "completed").order_by(desc(DonHang.id)).offset(skip).limit(limit).all()
        ket_qua = []
        for don in don_hang:
            chi_tiet, tong_sl = [], 0
            for ct in (don.chi_tiet or []):
                sl = int(ct.quantity or 0)
                tong_sl += sl
                chi_tiet.append({"order_item_id": ct.id, "product_name": ct.product_name, "variant_id": ct.variant_id, "variant_info": ct.variant_info, "quantity": sl, "price": int(ct.price or 0)})
            created_at_str = don.created_at if isinstance(don.created_at, str) else (don.created_at.strftime("%Y-%m-%d %H:%M") if don.created_at else "")
            ket_qua.append({"id": don.id, "created_at": created_at_str, "customer_name": don.customer_name or "Khách lẻ", "total_amount": int(don.total_amount or 0), "total_qty": tong_sl, "picker_note": (don.picker_note or ""), "status": don.status, "items": chi_tiet})
        return {"data": ket_qua, "total": tong, "page": page, "limit": limit}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi tải hóa đơn: {e}")


@router.delete("/don-hang/{don_id}")
def xoa_don(don_id: int, db: Session = Depends(get_db)):
    don = db.query(DonHang).filter(DonHang.id == don_id).first()
    if not don:
        raise HTTPException(status_code=404, detail="Hóa đơn không tồn tại")
    if don.status != "completed":
        raise HTTPException(status_code=400, detail="Chỉ có thể xóa đơn hàng đã hoàn thành")
    try:
        _xoa_don_voi_logic(don, db)
        db.commit()
        return {"detail": "Đã xóa hóa đơn và hoàn tác kho + công nợ"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/don-hang/{don_id}/ngay")
def cap_nhat_ngay_don(don_id: int, data: CapNhatNgayDon, db: Session = Depends(get_db)):
    don = db.query(DonHang).filter(DonHang.id == don_id).first()
    if not don:
        raise HTTPException(status_code=404, detail="Đơn hàng không tồn tại")
    try:
        don.created_at = data.created_at
        don.created_ts = now_vn_ts()
        db.commit()
        return {"status": "updated"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/don-hang/{don_id}/sua")
def sua_don_hang(don_id: int, data: YeuCauThanhToan, db: Session = Depends(get_db)):
    don = db.query(DonHang).filter(DonHang.id == don_id).first()
    if not don:
        raise HTTPException(status_code=404, detail="Không tìm thấy đơn hàng")
    if don.status not in ("pending",):
        raise HTTPException(status_code=400, detail="Chỉ có thể sửa đơn đang chờ duyệt")
    try:
        from sqlalchemy import func as sqla_func
        ten_khach = data.customer_name.strip() or "Khách lẻ"
        khach = None
        if ten_khach != "Khách lẻ":
            khach = db.query(KhachHang).filter(
                sqla_func.lower(KhachHang.name) == sqla_func.lower(ten_khach)
            ).first()
        don.customer_name = khach.name if khach else ten_khach
        don.customer_id = khach.id if khach else None
        # Xóa items cũ và thay bằng items mới
        db.query(ChiTietDon).filter(ChiTietDon.order_id == don_id).delete()
        tong = 0
        for item in data.cart:
            tong += int(item.quantity) * int(item.price)
            db.add(ChiTietDon(
                order_id=don_id,
                product_name=item.product_name,
                variant_id=item.variant_id,
                variant_info=f"{item.color}-{item.size}",
                quantity=item.quantity,
                price=item.price,
            ))
        don.total_amount = tong
        db.commit()
        return {"status": "success", "order_id": don_id}
    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/thanh-toan")
def thanh_toan_truc_tiep(data: YeuCauThanhToan, db: Session = Depends(get_db)):
    try:
        from sqlalchemy import func as sqla_func
        tong = sum(item.quantity * item.price for item in data.cart)
        for item in data.cart:
            bt = db.query(BienThe).filter(BienThe.id == item.variant_id).first()
            if not bt or bt.stock < item.quantity:
                raise HTTPException(status_code=400, detail=f"SP {item.product_name} thiếu hàng")
            bt.stock -= item.quantity
        ten_khach = data.customer_name.strip()
        khach = None
        if ten_khach and ten_khach != "Khách lẻ":
            khach = db.query(KhachHang).filter(sqla_func.lower(KhachHang.name) == sqla_func.lower(ten_khach)).first()
            if not khach:
                khach = KhachHang(name=ten_khach, phone=data.customer_phone, debt=0, area_id=_lay_khu_vuc_mac_dinh(db))
                db.add(khach)
                db.flush()
            khach.debt += tong
        don = DonHang(total_amount=tong, customer_name=khach.name if khach else "Khách lẻ",
                      customer_id=khach.id if khach else None, is_draft=0, status="completed",
                      created_by_employee_id=data.employee_id, created_at=now_vn().strftime("%Y-%m-%d %H:%M"), created_ts=now_vn_ts())
        db.add(don)
        db.flush()
        for item in data.cart:
            db.add(ChiTietDon(order_id=don.id, product_name=item.product_name, variant_id=item.variant_id,
                              variant_info=f"{item.color}-{item.size}", quantity=item.quantity, price=item.price))
        db.commit()
        return {"status": "success"}
    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/thanh-toan/nhap")
def thanh_toan_nhap(data: YeuCauThanhToan, db: Session = Depends(get_db)):
    try:
        from sqlalchemy import func as sqla_func
        tong = sum(item.quantity * item.price for item in data.cart)
        for item in data.cart:
            bt = db.query(BienThe).filter(BienThe.id == item.variant_id).first()
            if not bt or int(bt.stock or 0) < int(item.quantity or 0):
                raise HTTPException(status_code=400, detail=f"SP {item.product_name} thiếu hàng")
            bt.stock = int(bt.stock or 0) - int(item.quantity or 0)
        ten_khach = data.customer_name.strip()
        khach = None
        if ten_khach and ten_khach != "Khách lẻ":
            khach = db.query(KhachHang).filter(sqla_func.lower(KhachHang.name) == sqla_func.lower(ten_khach)).first()
            if not khach:
                khach = KhachHang(name=ten_khach, phone=data.customer_phone, debt=0, area_id=_lay_khu_vuc_mac_dinh(db))
                db.add(khach)
                db.flush()
        don = DonHang(total_amount=tong, customer_name=khach.name if khach else "Khách lẻ",
                      customer_id=khach.id if khach else None, is_draft=1, status="approved",
                      created_by_employee_id=data.employee_id, created_at=now_vn().strftime("%Y-%m-%d %H:%M"), created_ts=now_vn_ts())
        db.add(don)
        db.flush()
        for item in data.cart:
            db.add(ChiTietDon(order_id=don.id, product_name=item.product_name, variant_id=item.variant_id,
                              variant_info=f"{item.color}-{item.size}", quantity=item.quantity, price=item.price))
        db.commit()
        return {"status": "success", "order_id": don.id, "message": "Đơn hàng đã gửi đến picker"}
    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/thanh-toan/desktop")
def thanh_toan_desktop(data: YeuCauThanhToan, db: Session = Depends(get_db)):
    try:
        from sqlalchemy import func as sqla_func
        tong = sum(item.quantity * item.price for item in data.cart)
        for item in data.cart:
            bt = db.query(BienThe).filter(BienThe.id == item.variant_id).first()
            if not bt or int(bt.stock or 0) < int(item.quantity or 0):
                raise HTTPException(status_code=400, detail=f"SP {item.product_name} thiếu hàng")
            bt.stock = int(bt.stock or 0) - int(item.quantity or 0)
        ten_khach = data.customer_name.strip()
        khach = None
        if ten_khach and ten_khach != "Khách lẻ":
            khach = db.query(KhachHang).filter(sqla_func.lower(KhachHang.name) == sqla_func.lower(ten_khach)).first()
            if not khach:
                khach = KhachHang(name=ten_khach, phone=data.customer_phone, debt=0, area_id=_lay_khu_vuc_mac_dinh(db))
                db.add(khach)
                db.flush()
        don = DonHang(total_amount=tong, customer_name=khach.name if khach else "Khách lẻ",
                      customer_id=khach.id if khach else None, is_draft=1, status="approved",
                      created_at=now_vn().strftime("%Y-%m-%d %H:%M"), created_ts=now_vn_ts())
        db.add(don)
        db.flush()
        for item in data.cart:
            db.add(ChiTietDon(order_id=don.id, product_name=item.product_name, variant_id=item.variant_id,
                              variant_info=f"{item.color}-{item.size}", quantity=item.quantity, price=item.price))
        db.commit()
        return {"status": "success", "order_id": don.id, "message": "Đơn desktop đã gửi picker"}
    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/don-hang/cho-duyet")
def lay_don_cho_duyet(db: Session = Depends(get_db)):
    try:
        don_hang = db.query(DonHang).filter(DonHang.status == "pending").order_by(desc(DonHang.created_ts)).all()
        ket_qua = []
        for don in don_hang:
            chi_tiet, tong_sl, co_thieu = [], 0, False
            for ct in (don.chi_tiet or []):
                tong_sl += ct.quantity
                ton_kho, du_hang = None, True
                if ct.variant_id:
                    bt = db.query(BienThe).filter(BienThe.id == ct.variant_id).first()
                    ton_kho = int(bt.stock or 0) if bt else 0
                    du_hang = ton_kho >= int(ct.quantity or 0)
                    if not du_hang:
                        co_thieu = True
                chi_tiet.append({"order_item_id": ct.id, "product_name": ct.product_name, "variant_id": ct.variant_id, "variant_info": ct.variant_info, "quantity": ct.quantity, "price": ct.price, "current_stock": ton_kho, "enough_stock": du_hang})
            created_at_str = don.created_at if isinstance(don.created_at, str) else (don.created_at.strftime("%Y-%m-%d %H:%M") if don.created_at else "")
            ket_qua.append({"id": don.id, "created_at": created_at_str, "customer_name": don.customer_name or "Khách lẻ", "customer_id": don.customer_id, "total_amount": don.total_amount, "total_qty": tong_sl, "status": don.status, "picker_note": (don.picker_note or ""), "created_by_employee_id": don.created_by_employee_id, "created_by_employee_name": (don.nguoi_tao.name if getattr(don, "nguoi_tao", None) else ""), "has_stock_conflict": co_thieu, "items": chi_tiet})
        return {"data": ket_qua, "count": len(ket_qua)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/don-hang/{don_id}/duyet")
def duyet_don(don_id: int, db: Session = Depends(get_db)):
    try:
        don = db.query(DonHang).filter(DonHang.id == don_id).first()
        if not don:
            raise HTTPException(status_code=404, detail="Hóa đơn không tồn tại")
        if don.status != "pending":
            raise HTTPException(status_code=400, detail="Chỉ có thể duyệt đơn chờ duyệt")
        for ct in don.chi_tiet:
            if ct.variant_id:
                bt = db.query(BienThe).filter(BienThe.id == ct.variant_id).first()
                if not bt or int(bt.stock or 0) < int(ct.quantity or 0):
                    raise HTTPException(status_code=400, detail=f"SP {ct.product_name} thiếu hàng")
        for ct in don.chi_tiet:
            if ct.variant_id:
                bt = db.query(BienThe).filter(BienThe.id == ct.variant_id).first()
                bt.stock = int(bt.stock or 0) - int(ct.quantity or 0)
        don.status, don.is_draft = "approved", 1
        db.commit()
        return {"status": "success", "message": f"Đơn #{don_id} đã được duyệt"}
    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/don-hang/{don_id}/tu-choi")
def tu_choi_don(don_id: int, db: Session = Depends(get_db)):
    try:
        don = db.query(DonHang).filter(DonHang.id == don_id).first()
        if not don:
            raise HTTPException(status_code=404, detail="Hóa đơn không tồn tại")
        if don.status != "pending":
            raise HTTPException(status_code=400, detail="Chỉ có thể từ chối đơn chờ duyệt")
        db.query(ChiTietDon).filter(ChiTietDon.order_id == don_id).delete()
        db.delete(don)
        db.commit()
        return {"status": "success", "message": f"Đơn #{don_id} đã bị từ chối"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/don-hang/{don_id}/huy")
def huy_don(don_id: int, db: Session = Depends(get_db)):
    try:
        don = db.query(DonHang).filter(DonHang.id == don_id).first()
        if not don:
            raise HTTPException(status_code=404)
        if don.status not in ("pending", "approved", "assigned"):
            raise HTTPException(status_code=400, detail="Chỉ hủy đơn đang chờ/đã duyệt/đã nhận")
        db.query(ChiTietDon).filter(ChiTietDon.order_id == don_id).delete()
        db.delete(don)
        db.commit()
        return {"status": "success", "message": f"Đơn #{don_id} đã bị hủy"}
    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/don-hang/da-duyet")
def lay_don_da_duyet(db: Session = Depends(get_db)):
    try:
        don_hang = db.query(DonHang).filter(DonHang.status == "approved").order_by(desc(DonHang.created_ts)).all()
        return {"data": [_serialize_don(don) for don in don_hang], "count": len(don_hang)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/don-hang/{don_id}/nhan")
def nhan_don(don_id: int, data: YeuCauNhanDon, db: Session = Depends(get_db)):
    try:
        don = db.query(DonHang).filter(DonHang.id == don_id).first()
        if not don:
            raise HTTPException(status_code=404)
        if don.status != "approved":
            raise HTTPException(status_code=400, detail="Chỉ nhận đơn đã duyệt")
        picker = db.query(NhanVien).filter(NhanVien.id == data.picker_id).first()
        if not picker or picker.role not in ("picker", "manager"):
            raise HTTPException(status_code=400, detail="Picker không hợp lệ")
        don.status, don.assigned_picker_id, don.assigned_at = "assigned", picker.id, now_vn().strftime("%Y-%m-%d %H:%M")
        db.add(DonHangPicker(
            ma_don_hang=don.id, ma_nhan_vien=picker.id, la_nguoi_nhan_dau=1,
            thoi_gian_them=don.assigned_at,
        ))
        db.commit()
        return {"status": "success", "message": f"Đã nhận đơn #{don_id}"}
    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/don-hang/{don_id}/them-picker")
def them_picker(don_id: int, data: YeuCauThemPicker, db: Session = Depends(get_db)):
    try:
        ket_qua = _them_nguoi_vao_don_va_kenh(don_id, data.picker_id, data.nguoi_them_id, db)
        return ket_qua
    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/don-hang/{don_id}/pickers")
def lay_pickers_don(don_id: int, db: Session = Depends(get_db)):
    don = db.query(DonHang).filter(DonHang.id == don_id).first()
    if not don:
        raise HTTPException(status_code=404, detail="Đơn hàng không tồn tại")
    return [
        {"id": p.ma_nhan_vien, "name": (p.nhan_vien.name if p.nhan_vien else ""), "la_chinh": bool(p.la_nguoi_nhan_dau)}
        for p in don.pickers
    ]


@router.get("/don-hang/da-nhan")
def lay_don_da_nhan(picker_id: int, db: Session = Depends(get_db)):
    try:
        don_hang = db.query(DonHang).filter(DonHang.status == "assigned", DonHang.assigned_picker_id == picker_id).order_by(desc(DonHang.created_ts)).all()
        return {"data": [_serialize_don(don) for don in don_hang], "count": len(don_hang)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/don-hang/{don_id}/giao-kem-anh")
async def giao_hang_upload_anh(
    don_id: int,
    picker_id: int = Form(...),
    items_json: str = Form("[]"),
    picker_note: str = Form(""),
    photo: Optional[UploadFile] = File(None),
    photos: Optional[List[UploadFile]] = File(None),
    db: Session = Depends(get_db),
):
    try:
        raw_items = json.loads(items_json or "[]")
        if not isinstance(raw_items, list):
            raw_items = []
    except Exception:
        raise HTTPException(status_code=400, detail="Dữ liệu items không hợp lệ")

    items = [XacNhanGiaoItem(order_item_id=x.get("order_item_id"), variant_id=x.get("variant_id"), picked_qty=int(x.get("picked_qty") or 0)) for x in raw_items if isinstance(x, dict)]
    upload_files = [p for p in (photos or []) if p is not None] or ([photo] if photo else [])
    if not upload_files:
        raise HTTPException(status_code=400, detail="Thiếu ảnh xác nhận giao hàng")
    photo_paths = [_luu_anh_giao_hang(don_id, f) for f in upload_files]
    return _giao_hang_noi_bo(don_id, picker_id, photo_paths, items, db, picker_note)


def _xac_nhan_giao_logic(don: DonHang, items: Optional[List[XacNhanGiaoItem]], db: Session, ghi_chu: str = "") -> dict:
    yeu_cau_map = {ct.id: ct for ct in don.chi_tiet}
    da_giao_map = {}
    if items:
        for x in items:
            ct_target = None
            if x.order_item_id and x.order_item_id in yeu_cau_map:
                ct_target = yeu_cau_map[x.order_item_id]
            elif x.variant_id is not None:
                ct_target = next((ct for ct in don.chi_tiet if ct.variant_id == x.variant_id), None)
            if not ct_target:
                continue
            sl = max(0, min(int(x.picked_qty or 0), int(ct_target.quantity)))
            da_giao_map[ct_target.id] = sl
    for ct in don.chi_tiet:
        if ct.id not in da_giao_map:
            da_giao_map[ct.id] = int(ct.quantity or 0)

    tong_giao, thieu_hang = 0, []
    for ct in list(don.chi_tiet):
        sl_yc = int(ct.quantity or 0)
        sl_giao = int(da_giao_map.get(ct.id, 0))
        if sl_giao < sl_yc:
            thieu_hang.append(f"{ct.product_name} ({sl_giao}/{sl_yc})")
            if ct.variant_id:
                bt = db.query(BienThe).filter(BienThe.id == ct.variant_id).first()
                if bt:
                    bt.stock = int(bt.stock or 0) + (sl_yc - sl_giao)
        if sl_giao <= 0:
            db.delete(ct)
        else:
            ct.quantity = sl_giao
            tong_giao += int(ct.price or 0) * sl_giao

    if don.customer_id and tong_giao > 0:
        kh = db.query(KhachHang).filter(KhachHang.id == don.customer_id).first()
        if kh:
            kh.debt = int(kh.debt or 0) + tong_giao

    don.total_amount = tong_giao
    ghi_chu_thieu = ("Thiếu hàng: " + "; ".join(thieu_hang)) if thieu_hang else ""
    ghi_chu_manual = (ghi_chu or "").strip()
    if ghi_chu_thieu and ghi_chu_manual:
        don.picker_note = f"{ghi_chu_thieu} | {ghi_chu_manual}"
    elif ghi_chu_thieu:
        don.picker_note = ghi_chu_thieu
    else:
        don.picker_note = ghi_chu_manual
    don.status, don.is_draft = "completed", 0
    db.commit()
    return {"status": "success", "message": f"Đơn #{don.id} hoàn thành", "partial": len(thieu_hang) > 0, "picker_note": don.picker_note, "delivered_total": tong_giao}


def _giao_hang_noi_bo(don_id: int, picker_id: int, photo_keys: list, items: list, db: Session, ghi_chu: str = "") -> dict:
    if not photo_keys:
        raise HTTPException(status_code=400, detail="Bắt buộc chụp ảnh xác nhận giao hàng")

    picker = db.query(NhanVien).filter(NhanVien.id == picker_id).first()
    if not picker or picker.role not in ("picker", "manager"):
        raise HTTPException(status_code=400, detail="Picker không hợp lệ")
    don = db.query(DonHang).filter(DonHang.id == don_id).first()
    if not don:
        raise HTTPException(status_code=404)
    if don.status != "assigned":
        raise HTTPException(status_code=400, detail="Chỉ giao đơn đã nhận")
    if don.assigned_picker_id != picker.id:
        raise HTTPException(status_code=403, detail="Bạn không phải người đã nhận đơn này")

    ket_qua = _xac_nhan_giao_logic(don, items if items else None, db, ghi_chu)
    don.delivered_by_id, don.delivered_at = picker.id, now_vn().strftime("%Y-%m-%d %H:%M")
    don.delivery_photo_path = json.dumps(photo_keys, ensure_ascii=False) if len(photo_keys) > 1 else photo_keys[0]
    db.commit()

    chu_thich = f"Đơn #{don.id} • {don.customer_name or 'Khách lẻ'}\nPicker: {picker.name}\n{now_vn().strftime('%Y-%m-%d %H:%M')}"
    if don.picker_note:
        chu_thich += f"\nGhi chú: {don.picker_note}"
    threading.Thread(target=_gui_anh_telegram_async, args=(don.id, photo_keys, chu_thich), daemon=True).start()

    return ket_qua


@router.put("/don-hang/{don_id}/xac-nhan")
def xac_nhan_don(don_id: int, data: YeuCauXacNhanGiao, db: Session = Depends(get_db)):
    try:
        don = db.query(DonHang).filter(DonHang.id == don_id).first()
        if not don:
            raise HTTPException(status_code=404)
        if don.status not in ("assigned",):
            raise HTTPException(status_code=400, detail="Chỉ xác nhận đơn đã được nhận")
        if don.assigned_picker_id != data.picker_id:
            raise HTTPException(status_code=403, detail="Chỉ picker chính mới được xác nhận đơn")
        return _xac_nhan_giao_logic(don, data.items, db)
    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/don-hang/quan-ly")
def lay_don_quan_ly(limit: int = 200, db: Session = Depends(get_db)):
    try:
        don_hang = db.query(DonHang).order_by(desc(DonHang.created_ts)).limit(limit).all()
        return {"data": [_serialize_don(don) for don in don_hang], "count": len(don_hang)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/don-hang/{don_id}/soan")
def chi_tiet_soan_kho(don_id: int, db: Session = Depends(get_db)):
    don = db.query(DonHang).filter(DonHang.id == don_id, DonHang.status.in_(["approved", "assigned"])).first()
    if not don:
        raise HTTPException(status_code=404, detail="Đơn không tồn tại hoặc chưa ở trạng thái soạn")
    items = []
    for ct in don.chi_tiet:
        image, warehouses = "", []
        if ct.variant_id:
            bt = db.query(BienThe).filter(BienThe.id == ct.variant_id).first()
            if bt and getattr(bt, "san_pham", None):
                sp = bt.san_pham
                key = sp.image_path or ""
                from app.routers.san_pham import _la_s3_key
                from app import s3 as _s3
                image = _s3.presigned_url(key) if _la_s3_key(key) else ""
            rows = db.query(ViTriBienThe).filter(ViTriBienThe.ma_bien_the == ct.variant_id).all()
            if not rows and bt and getattr(bt, "san_pham", None):
                # Biến thể chưa được gán kho — tự đồng bộ từ các biến thể cùng sản phẩm
                sibling_ids = [v.id for v in bt.san_pham.variants if v.id != ct.variant_id]
                if sibling_ids:
                    kho_ids = {r[0] for r in db.query(ViTriBienThe.ma_kho).filter(
                        ViTriBienThe.ma_bien_the.in_(sibling_ids)).distinct().all()}
                    for kho_id in kho_ids:
                        db.add(ViTriBienThe(ma_bien_the=ct.variant_id, ma_kho=kho_id, so_luong=0))
                    if kho_ids:
                        db.commit()
                        rows = db.query(ViTriBienThe).filter(ViTriBienThe.ma_bien_the == ct.variant_id).all()
            for row in rows:
                if row.kho_hang:
                    warehouses.append({
                        "id": row.kho_hang.id,
                        "ten": row.kho_hang.ten,
                        "vi_tri": row.kho_hang.vi_tri or "",
                        "so_luong": int(row.so_luong or 0),
                    })
        trang_thai = db.query(SoanKhoTrangThai).filter(SoanKhoTrangThai.ma_chi_tiet_don == ct.id).first()
        items.append({
            "order_item_id": ct.id,
            "product_name": ct.product_name,
            "variant_id": ct.variant_id,
            "variant_info": ct.variant_info or "",
            "quantity": int(ct.quantity or 0),
            "price": int(ct.price or 0),
            "image": image,
            "warehouses": warehouses,
            "selected_kho_id": trang_thai.ma_kho if trang_thai else None,
            "selected_qty": int(trang_thai.so_luong_chon or 0) if trang_thai else 0,
            "updated_by": trang_thai.cap_nhat_boi if trang_thai else None,
        })
    return {
        "id": don.id, "customer_name": don.customer_name or "Khách lẻ", "items": items,
        "pickers": [
            {"id": p.ma_nhan_vien, "name": (p.nhan_vien.name if p.nhan_vien else ""), "la_chinh": bool(p.la_nguoi_nhan_dau)}
            for p in don.pickers
        ],
    }


@router.get("/don-hang/{don_id}/trang-thai")
def kiem_tra_trang_thai(don_id: int, db: Session = Depends(get_db)):
    don = db.query(DonHang).filter(DonHang.id == don_id).first()
    if not don:
        raise HTTPException(status_code=404, detail="Đơn hàng không tồn tại hoặc đã bị từ chối")
    return {"id": don_id, "status": don.status, "picker_note": (don.picker_note or "")}


# ─── Ảnh giao hàng ─────────────────────────────────────────────────────────────

anh_router = APIRouter(tags=["Ảnh giao hàng"])


@anh_router.post("/bang-chung-giao/xac-nhan-local")
def xac_nhan_anh_local(data: XacNhanLocalAnh, db: Session = Depends(get_db)):
    don = db.query(DonHang).filter(DonHang.id == data.order_id).first()
    if not don:
        raise HTTPException(status_code=404)
    current_paths = parse_duong_dan_anh(don.delivery_photo_path)
    return {"status": "ok", "order_id": don.id, "removed_remote_files": 0, "local_paths": current_paths}
