from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import desc, func
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import KhuVuc, KhachHang, LichSuNo, DonHang, ChiTietDon, BienThe
from app.schemas.khach_hang import TaoKhuVuc, CapNhatKhuVuc, TaoKhachHang, CapNhatKhachHang, TaoLichSuNo, CapNhatLichSuNo
from app.utils import now_vn, now_vn_ts, parse_duong_dan_anh


def _lay_khu_vuc_mac_dinh(db: Session):
    kv = db.query(KhuVuc).order_by(KhuVuc.id).first()
    return kv.id if kv else None


# ─── Khu vực ───────────────────────────────────────────────────────────────────

khu_vuc_router = APIRouter(prefix="/areas", tags=["Khu vực"])


@khu_vuc_router.get("")
def lay_danh_sach_khu_vuc(db: Session = Depends(get_db)):
    khu_vuc = db.query(KhuVuc).order_by(KhuVuc.id).all()
    ket_qua = []
    for kv in khu_vuc:
        khach = db.query(KhachHang).filter(KhachHang.area_id == kv.id).all()
        ket_qua.append({
            "id": kv.id, "name": kv.name,
            "customer_count": len(khach),
            "total_debt": sum(int(kh.debt or 0) for kh in khach),
        })
    return ket_qua


@khu_vuc_router.post("")
def tao_khu_vuc(data: TaoKhuVuc, db: Session = Depends(get_db)):
    ten = data.name.strip()
    if not ten:
        raise HTTPException(status_code=400, detail="Tên khu vực không hợp lệ")
    if db.query(KhuVuc).filter(func.lower(KhuVuc.name) == func.lower(ten)).first():
        raise HTTPException(status_code=400, detail="Khu vực đã tồn tại")
    kv = KhuVuc(name=ten)
    db.add(kv)
    db.commit()
    db.refresh(kv)
    return {"status": "created", "id": kv.id}


@khu_vuc_router.put("/{kv_id}")
def cap_nhat_khu_vuc(kv_id: int, data: CapNhatKhuVuc, db: Session = Depends(get_db)):
    kv = db.query(KhuVuc).filter(KhuVuc.id == kv_id).first()
    if not kv:
        raise HTTPException(status_code=404, detail="Khu vực không tồn tại")
    ten = data.name.strip()
    if not ten:
        raise HTTPException(status_code=400, detail="Tên khu vực không hợp lệ")
    if db.query(KhuVuc).filter(func.lower(KhuVuc.name) == func.lower(ten), KhuVuc.id != kv_id).first():
        raise HTTPException(status_code=400, detail="Tên khu vực đã tồn tại")
    kv.name = ten
    db.commit()
    return {"status": "updated"}


@khu_vuc_router.delete("/{kv_id}")
def xoa_khu_vuc(kv_id: int, db: Session = Depends(get_db)):
    kv = db.query(KhuVuc).filter(KhuVuc.id == kv_id).first()
    if not kv:
        raise HTTPException(status_code=404, detail="Khu vực không tồn tại")
    du_phong = db.query(KhuVuc).filter(KhuVuc.id != kv_id).order_by(KhuVuc.id).first()
    if not du_phong:
        raise HTTPException(status_code=400, detail="Không thể xóa khu vực duy nhất")
    db.query(KhachHang).filter(KhachHang.area_id == kv_id).update({KhachHang.area_id: du_phong.id})
    db.delete(kv)
    db.commit()
    return {"status": "deleted", "moved_to_area_id": du_phong.id}


# ─── Khách hàng ────────────────────────────────────────────────────────────────

khach_hang_router = APIRouter(prefix="/customers", tags=["Khách hàng"])


@khach_hang_router.get("")
def lay_danh_sach_khach(db: Session = Depends(get_db)):
    khach = db.query(KhachHang).order_by(desc(KhachHang.id)).all()
    return [{
        "id": kh.id, "name": kh.name, "phone": kh.phone, "debt": kh.debt,
        "area_id": kh.area_id, "area_name": (kh.khu_vuc.name if kh.khu_vuc else ""),
    } for kh in khach]


@khach_hang_router.post("")
def tao_khach_hang(data: TaoKhachHang, db: Session = Depends(get_db)):
    try:
        if db.query(KhachHang).filter(KhachHang.name == data.name).first():
            raise HTTPException(status_code=400, detail="Tên đã tồn tại!")
        if not db.query(KhuVuc).filter(KhuVuc.id == data.area_id).first():
            raise HTTPException(status_code=400, detail="Khu vực không tồn tại")
        kh = KhachHang(name=data.name, phone=data.phone, debt=data.debt, area_id=data.area_id)
        db.add(kh)
        db.flush()
        if data.debt != 0:
            db.add(LichSuNo(customer_id=kh.id, change_amount=data.debt, new_balance=data.debt,
                            note="Khởi tạo thủ công", created_at=now_vn().strftime("%Y-%m-%d %H:%M"), created_ts=now_vn_ts()))
        db.commit()
        db.refresh(kh)
        return {"status": "created", "id": kh.id}
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


@khach_hang_router.put("/{kh_id}")
def cap_nhat_khach_hang(kh_id: int, data: CapNhatKhachHang, db: Session = Depends(get_db)):
    kh = db.query(KhachHang).filter(KhachHang.id == kh_id).first()
    if not kh:
        raise HTTPException(status_code=404)
    if not db.query(KhuVuc).filter(KhuVuc.id == data.area_id).first():
        raise HTTPException(status_code=400, detail="Khu vực không tồn tại")
    chenh_lech = data.debt - kh.debt
    kh.name, kh.phone, kh.debt, kh.area_id = data.name, data.phone, data.debt, data.area_id
    if chenh_lech != 0:
        db.add(LichSuNo(customer_id=kh.id, change_amount=chenh_lech, new_balance=kh.debt,
                        note="Điều chỉnh thủ công", created_at=now_vn().strftime("%Y-%m-%d %H:%M"), created_ts=now_vn_ts()))
    db.commit()
    return {"status": "ok"}


@khach_hang_router.delete("/{kh_id}")
def xoa_khach_hang(kh_id: int, db: Session = Depends(get_db)):
    kh = db.query(KhachHang).filter(KhachHang.id == kh_id).first()
    if not kh:
        raise HTTPException(status_code=404, detail="Khách hàng không tồn tại")
    try:
        for don in db.query(DonHang).filter(DonHang.customer_id == kh_id).all():
            _xoa_don_voi_logic(don, db)
        db.delete(kh)
        db.commit()
        return {"detail": "Đã xóa khách hàng và toàn bộ đơn hàng liên quan"}
    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


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


@khach_hang_router.get("/{kh_id}/history")
def lich_su_khach_hang(kh_id: int, db: Session = Depends(get_db)):
    lich_su = []
    for don in db.query(DonHang).filter(DonHang.customer_id == kh_id).all():
        ts = int(don.created_ts or 0)
        ct_list = [{"product_name": ct.product_name, "variant_id": ct.variant_id, "variant_info": ct.variant_info, "quantity": ct.quantity, "price": ct.price} for ct in don.chi_tiet]
        date_str = don.created_at if isinstance(don.created_at, str) else (don.created_at.strftime("%Y-%m-%d %H:%M") if don.created_at else "")
        lich_su.append({
            "type": "ORDER", "date": date_str, "sort_ts": ts,
            "desc": f"Xuất đơn hàng #{don.id}", "amount": don.total_amount,
            "data": {"id": don.id, "customer_name": don.customer_name, "date": date_str, "total_money": don.total_amount, "total_qty": sum(ct.quantity for ct in don.chi_tiet), "delivery_photo_paths": parse_duong_dan_anh(don.delivery_photo_path), "items": ct_list},
        })
    for log in db.query(LichSuNo).filter(LichSuNo.customer_id == kh_id).all():
        ts = int(log.created_ts or 0)
        lich_su.append({
            "type": "LOG", "date": (log.created_at or ""), "sort_ts": ts,
            "desc": log.note, "amount": log.change_amount, "data": None, "log_id": log.id,
        })
    return sorted(lich_su, key=lambda x: x["sort_ts"], reverse=True)


@khach_hang_router.post("/{kh_id}/history")
def tao_lich_su_no(kh_id: int, data: TaoLichSuNo, db: Session = Depends(get_db)):
    kh = db.query(KhachHang).filter(KhachHang.id == kh_id).first()
    if not kh:
        raise HTTPException(status_code=404, detail="Khách hàng không tồn tại")
    try:
        hien_tai = now_vn()
        ngay_hien_thi = hien_tai.strftime("%Y-%m-%d %H:%M")
        if data.created_at:
            try:
                datetime.strptime(data.created_at, "%Y-%m-%d %H:%M")
                ngay_hien_thi = data.created_at
            except Exception:
                pass
        kh.debt += data.change_amount
        db.add(LichSuNo(customer_id=kh.id, actor_employee_id=data.actor_employee_id,
                        change_amount=data.change_amount, new_balance=kh.debt, note=data.note,
                        created_at=ngay_hien_thi, created_ts=int(hien_tai.timestamp() * 1000)))
        db.commit()
        return {"status": "created"}
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


@khach_hang_router.put("/{kh_id}/history/{log_id}")
def cap_nhat_lich_su_no(kh_id: int, log_id: int, data: CapNhatLichSuNo, db: Session = Depends(get_db)):
    kh = db.query(KhachHang).filter(KhachHang.id == kh_id).first()
    if not kh:
        raise HTTPException(status_code=404)
    log = db.query(LichSuNo).filter(LichSuNo.id == log_id, LichSuNo.customer_id == kh_id).first()
    if not log:
        raise HTTPException(status_code=404, detail="Log không tồn tại")
    try:
        chenh_lech = data.change_amount - log.change_amount
        kh.debt += chenh_lech
        log.change_amount, log.note, log.new_balance = data.change_amount, data.note, kh.debt
        if data.created_at:
            try:
                datetime.strptime(data.created_at, "%Y-%m-%d %H:%M")
                log.created_at = data.created_at
            except Exception:
                pass
        db.commit()
        return {"status": "updated"}
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


@khach_hang_router.delete("/{kh_id}/history/{log_id}")
def xoa_lich_su_no(kh_id: int, log_id: int, db: Session = Depends(get_db)):
    kh = db.query(KhachHang).filter(KhachHang.id == kh_id).first()
    if not kh:
        raise HTTPException(status_code=404)
    log = db.query(LichSuNo).filter(LichSuNo.id == log_id, LichSuNo.customer_id == kh_id).first()
    if not log:
        raise HTTPException(status_code=404, detail="Log không tồn tại")
    try:
        kh.debt -= log.change_amount
        db.delete(log)
        db.commit()
        return {"status": "deleted"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))
