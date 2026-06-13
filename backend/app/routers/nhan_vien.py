import random
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import desc, func
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import NhanVien, DonHang, LichSuNo, KhachHang
from app.schemas.nhan_vien import TaoNhanVien, CapNhatNhanVien, DangNhapPin
from app.utils import now_vn, period_start_vn, parse_duong_dan_anh, trang_thai_don_vi

router = APIRouter(prefix="/employees", tags=["Nhân viên"])
auth_router = APIRouter(prefix="/auth", tags=["Auth"])

VAI_TRO_HOP_LE = {"orderer", "picker", "manager"}


def _serialize_nhan_vien(nv: NhanVien, so_don_giao: int = 0) -> dict:
    lan_giao_cuoi = ""
    if getattr(nv, "don_hang_giao", None):
        ngay_giao = [str(o.delivered_at) for o in nv.don_hang_giao if getattr(o, "delivered_at", None)]
        if ngay_giao:
            lan_giao_cuoi = max(ngay_giao)
    return {
        "id": nv.id,
        "name": nv.name,
        "phone": nv.phone,
        "email": (getattr(nv, "email", "") or ""),
        "address": (getattr(nv, "address", "") or ""),
        "notes": (getattr(nv, "notes", "") or ""),
        "role": nv.role,
        "pin": nv.pin,
        "is_active": int(getattr(nv, "is_active", 1) or 0),
        "created_at": nv.created_at if isinstance(nv.created_at, str) else (nv.created_at.strftime("%Y-%m-%d %H:%M") if nv.created_at else ""),
        "delivered_count": int(so_don_giao or 0),
        "last_delivered_at": lan_giao_cuoi,
    }


def _serialize_don_hang(don: DonHang) -> dict:
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
    duong_dan_anh = parse_duong_dan_anh(don.delivery_photo_path)
    created_at_str = don.created_at if isinstance(don.created_at, str) else (don.created_at.strftime("%Y-%m-%d %H:%M") if don.created_at else "")
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
        "assigned_at": don.assigned_at or "",
        "delivered_by_id": don.delivered_by_id,
        "delivered_by_name": (don.nguoi_giao.name if getattr(don, "nguoi_giao", None) else ""),
        "delivered_at": delivered_at_str,
        "delivery_photo_path": (don.delivery_photo_path or ""),
        "delivery_photo_paths": duong_dan_anh,
        "items": chi_tiet,
    }


def _sinh_pin_duy_nhat(db: Session) -> str:
    for _ in range(50):
        pin = f"{random.randint(0, 9999):04d}"
        if not db.query(NhanVien).filter(NhanVien.pin == pin).first():
            return pin
    raise HTTPException(status_code=500, detail="Không tạo được PIN duy nhất")


def _chuan_hoa_pin(pin_raw: str) -> str:
    pin = (pin_raw or "").strip()
    if not pin:
        raise HTTPException(status_code=400, detail="PIN không được để trống")
    if not pin.isdigit():
        raise HTTPException(status_code=400, detail="PIN chỉ được chứa chữ số")
    if not (4 <= len(pin) <= 8):
        raise HTTPException(status_code=400, detail="PIN phải có 4-8 chữ số")
    return pin


@auth_router.post("/pin-login")
def dang_nhap_pin(data: DangNhapPin, db: Session = Depends(get_db)):
    vai_tro = data.requested_role.strip().lower()
    if vai_tro not in VAI_TRO_HOP_LE:
        raise HTTPException(status_code=400, detail="Vai trò không hợp lệ")
    nv = db.query(NhanVien).filter(NhanVien.pin == data.pin.strip()).first()
    if not nv:
        raise HTTPException(status_code=401, detail="PIN không đúng")
    if int(getattr(nv, "is_active", 1) or 0) != 1:
        raise HTTPException(status_code=403, detail="Tài khoản đang bị khóa")
    if nv.role != vai_tro:
        raise HTTPException(status_code=403, detail="PIN không thuộc vai trò này")
    return {"id": nv.id, "name": nv.name, "phone": nv.phone, "role": nv.role}


@router.get("")
def lay_danh_sach(db: Session = Depends(get_db)):
    nhan_vien = db.query(NhanVien).order_by(desc(NhanVien.id)).all()
    thong_ke = dict(
        db.query(DonHang.delivered_by_id, func.count(DonHang.id))
        .filter(DonHang.delivered_by_id.isnot(None), DonHang.status == "completed")
        .group_by(DonHang.delivered_by_id)
        .all()
    )
    return [_serialize_nhan_vien(nv, so_don_giao=thong_ke.get(nv.id, 0)) for nv in nhan_vien]


@router.post("")
def tao_nhan_vien(data: TaoNhanVien, db: Session = Depends(get_db)):
    vai_tro = data.role.strip().lower()
    if vai_tro not in VAI_TRO_HOP_LE:
        raise HTTPException(status_code=400, detail="Vai trò không hợp lệ")
    pin = _sinh_pin_duy_nhat(db)
    nv = NhanVien(name=data.name.strip(), phone=data.phone.strip(), email=data.email.strip(),
                  address=data.address.strip(), notes=data.notes.strip(), role=vai_tro, pin=pin, is_active=1,
                  created_at=now_vn().strftime("%Y-%m-%d %H:%M"))
    db.add(nv)
    db.commit()
    db.refresh(nv)
    return {"status": "created", "id": nv.id, "pin": nv.pin, "employee": _serialize_nhan_vien(nv)}


@router.put("/{nv_id}")
def cap_nhat_nhan_vien(nv_id: int, data: CapNhatNhanVien, db: Session = Depends(get_db)):
    nv = db.query(NhanVien).filter(NhanVien.id == nv_id).first()
    if not nv:
        raise HTTPException(status_code=404, detail="Nhân viên không tồn tại")
    vai_tro = data.role.strip().lower()
    if vai_tro not in VAI_TRO_HOP_LE:
        raise HTTPException(status_code=400, detail="Vai trò không hợp lệ")
    nv.name = data.name.strip()
    nv.phone = data.phone.strip()
    nv.email = data.email.strip()
    nv.address = data.address.strip()
    nv.notes = data.notes.strip()
    nv.role = vai_tro
    nv.is_active = 1 if int(data.is_active or 0) == 1 else 0
    if data.pin is not None:
        pin_moi = _chuan_hoa_pin(data.pin)
        if db.query(NhanVien).filter(NhanVien.pin == pin_moi, NhanVien.id != nv_id).first():
            raise HTTPException(status_code=400, detail="PIN đã tồn tại")
        nv.pin = pin_moi
    db.commit()
    db.refresh(nv)
    return {"status": "updated", "employee": _serialize_nhan_vien(nv)}


@router.delete("/{nv_id}")
def xoa_nhan_vien(nv_id: int, db: Session = Depends(get_db)):
    nv = db.query(NhanVien).filter(NhanVien.id == nv_id).first()
    if not nv:
        raise HTTPException(status_code=404, detail="Nhân viên không tồn tại")
    db.delete(nv)
    db.commit()
    return {"status": "deleted"}


@router.get("/{nv_id}/deliveries")
def lich_su_giao_hang(nv_id: int, q: str = "", days: int = 0, limit: int = 200, db: Session = Depends(get_db)):
    nv = db.query(NhanVien).filter(NhanVien.id == nv_id).first()
    if not nv:
        raise HTTPException(status_code=404, detail="Nhân viên không tồn tại")
    gioi_han = min(max(limit, 1), 500)
    query = db.query(DonHang).filter(DonHang.delivered_by_id == nv_id, DonHang.status == "completed")
    tu_khoa = q.strip()
    if tu_khoa:
        if tu_khoa.isdigit():
            query = query.filter((DonHang.id == int(tu_khoa)) | (DonHang.customer_name.ilike(f"%{tu_khoa}%")))
        else:
            query = query.filter(DonHang.customer_name.ilike(f"%{tu_khoa}%"))
    if days > 0:
        bat_dau = period_start_vn(days)
        query = query.filter(DonHang.delivered_at.isnot(None), DonHang.delivered_at >= bat_dau.strftime("%Y-%m-%d"))
    don_hang = query.order_by(desc(DonHang.id)).limit(gioi_han).all()
    return {"employee": _serialize_nhan_vien(nv), "data": [_serialize_don_hang(d) for d in don_hang], "count": len(don_hang)}


@router.get("/{nv_id}/activities")
def lich_su_hoat_dong(nv_id: int, q: str = "", days: int = 0, limit: int = 300, db: Session = Depends(get_db)):
    nv = db.query(NhanVien).filter(NhanVien.id == nv_id).first()
    if not nv:
        raise HTTPException(status_code=404, detail="Nhân viên không tồn tại")
    gioi_han = min(max(limit, 1), 1000)
    tu_khoa = q.strip().lower()

    qr_don = db.query(DonHang).filter(DonHang.created_by_employee_id == nv_id)
    if days > 0:
        bat_dau = period_start_vn(days).strftime("%Y-%m-%d")
        qr_don = qr_don.filter(DonHang.created_at >= bat_dau)
    if tu_khoa:
        if tu_khoa.isdigit():
            qr_don = qr_don.filter((DonHang.id == int(tu_khoa)) | (DonHang.customer_name.ilike(f"%{tu_khoa}%")))
        else:
            qr_don = qr_don.filter(DonHang.customer_name.ilike(f"%{tu_khoa}%"))
    danh_sach_don = qr_don.order_by(desc(DonHang.created_ts), desc(DonHang.id)).limit(gioi_han).all()

    qr_no = db.query(LichSuNo, KhachHang.name).outerjoin(KhachHang, KhachHang.id == LichSuNo.customer_id).filter(LichSuNo.actor_employee_id == nv_id)
    if tu_khoa:
        qr_no = qr_no.filter((KhachHang.name.ilike(f"%{tu_khoa}%")) | (LichSuNo.note.ilike(f"%{tu_khoa}%")))
    danh_sach_no = qr_no.order_by(desc(LichSuNo.created_ts), desc(LichSuNo.id)).limit(gioi_han).all()

    hoat_dong = []
    for don in danh_sach_don:
        ts = int(don.created_ts or 0)
        hoat_dong.append({
            "type": "ORDER", "sort_ts": ts,
            "date": don.created_at if isinstance(don.created_at, str) else (don.created_at.strftime("%Y-%m-%d %H:%M") if don.created_at else ""),
            "title": f"Đơn #{don.id} • {don.customer_name or 'Khách lẻ'}",
            "subtitle": f"{trang_thai_don_vi(don.status)} • SL {sum((ct.quantity or 0) for ct in (don.chi_tiet or []))}",
            "amount": int(don.total_amount or 0),
            "order": _serialize_don_hang(don),
        })
    for row in danh_sach_no:
        log, ten_khach = row
        ts = int(log.created_ts or 0)
        thay_doi = int(log.change_amount or 0)
        hoat_dong.append({
            "type": "DEBT_LOG", "sort_ts": ts,
            "date": log.created_at or "",
            "title": ("Thu tiền" if thay_doi < 0 else "Điều chỉnh công nợ") + f" • {ten_khach or 'Khách'}",
            "subtitle": (log.note or "").strip(),
            "amount": thay_doi,
            "log_id": log.id, "customer_id": log.customer_id,
        })

    hoat_dong.sort(key=lambda x: int(x.get("sort_ts") or 0), reverse=True)
    return {"employee": _serialize_nhan_vien(nv), "data": hoat_dong[:gioi_han], "count": len(hoat_dong[:gioi_han])}
