from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.don_hang import DonHang
from app.models.khach_hang import KhachHang
from typing import Optional
from datetime import date

router = APIRouter(prefix="/bao-cao", tags=["bao_cao"])


def _loc_don_hang(
    db: Session,
    tu_ngay: Optional[date],
    den_ngay: Optional[date],
    khu_vuc_id: Optional[int],
) -> list:
    query = db.query(DonHang).filter(DonHang.status == "completed")
    if tu_ngay:
        query = query.filter(DonHang.created_at >= tu_ngay.strftime("%Y-%m-%d"))
    if den_ngay:
        query = query.filter(DonHang.created_at <= den_ngay.strftime("%Y-%m-%d") + " 23:59:59")
    if khu_vuc_id:
        kh_ids = {
            kh.id
            for kh in db.query(KhachHang).filter(KhachHang.area_id == khu_vuc_id).all()
        }
        if not kh_ids:
            return []
        query = query.filter(DonHang.customer_id.in_(kh_ids))
    return query.order_by(DonHang.created_at).all()


@router.get("")
def lay_bao_cao(
    tu_ngay: Optional[date] = Query(None),
    den_ngay: Optional[date] = Query(None),
    khu_vuc_id: Optional[int] = Query(None),
    db: Session = Depends(get_db),
):
    ds = _loc_don_hang(db, tu_ngay, den_ngay, khu_vuc_id)

    tong_doanh_thu = sum(d.total_amount or 0 for d in ds)
    so_don_hang = len(ds)
    san_pham_da_ban = sum(item.quantity for d in ds for item in d.chi_tiet)
    so_khach_hang = len({d.customer_id for d in ds if d.customer_id})

    # Group by day
    ngay_dict: dict = {}
    ngay_khach: dict = {}
    for d in ds:
        ngay = (d.created_at or "")[:10]
        if len(ngay) < 10:
            continue
        e = ngay_dict.setdefault(
            ngay, {"ngay": ngay, "doanh_thu": 0, "so_don": 0, "so_sp": 0, "so_khach": 0}
        )
        ngay_khach.setdefault(ngay, set())
        e["doanh_thu"] += d.total_amount or 0
        e["so_don"] += 1
        e["so_sp"] += sum(item.quantity for item in d.chi_tiet)
        if d.customer_id:
            ngay_khach[ngay].add(d.customer_id)
    for ngay, kh_set in ngay_khach.items():
        if ngay in ngay_dict:
            ngay_dict[ngay]["so_khach"] = len(kh_set)
    theo_ngay = sorted(ngay_dict.values(), key=lambda x: x["ngay"])

    # Best-selling products
    sp_dict: dict = {}
    for d in ds:
        for item in d.chi_tiet:
            e = sp_dict.setdefault(
                item.product_name, {"ten": item.product_name, "so_luong": 0, "doanh_thu": 0}
            )
            e["so_luong"] += item.quantity
            e["doanh_thu"] += item.quantity * (item.price or 0)
    san_pham_ban_chay = sorted(sp_dict.values(), key=lambda x: x["so_luong"], reverse=True)

    # Top customers by spending
    kh_dict: dict = {}
    for d in ds:
        ten = d.customer_name or "Khách lẻ"
        e = kh_dict.setdefault(ten, {"ten": ten, "so_don": 0, "tong_chi": 0})
        e["so_don"] += 1
        e["tong_chi"] += d.total_amount or 0
    khach_mua_nhieu = sorted(kh_dict.values(), key=lambda x: x["tong_chi"], reverse=True)

    return {
        "tong_doanh_thu": tong_doanh_thu,
        "so_don_hang": so_don_hang,
        "san_pham_da_ban": san_pham_da_ban,
        "so_khach_hang": so_khach_hang,
        "theo_ngay": theo_ngay,
        "san_pham_ban_chay": san_pham_ban_chay,
        "khach_mua_nhieu": khach_mua_nhieu,
    }


@router.get("/don-hang-ngay")
def don_hang_ngay(
    ngay: date = Query(...),
    khu_vuc_id: Optional[int] = Query(None),
    db: Session = Depends(get_db),
):
    ds = _loc_don_hang(db, ngay, ngay, khu_vuc_id)
    result = []
    for d in ds:
        raw = d.created_at or ""
        tg = raw[11:19] if len(raw) >= 19 else ""
        ma = "HD" + raw.replace("-", "").replace(" ", "").replace(":", "")[:14]
        result.append({
            "id": d.id,
            "ma_hoa_don": ma,
            "ten_khach_hang": d.customer_name or "Khách lẻ",
            "thoi_gian": tg,
            "tong_tien": d.total_amount or 0,
            "san_pham": [
                {
                    "ten": item.product_name,
                    "so_luong": item.quantity,
                    "don_gia": item.price or 0,
                    "thanh_tien": item.quantity * (item.price or 0),
                }
                for item in sorted(d.chi_tiet, key=lambda x: x.id)
            ],
        })
    return {"ngay": ngay.strftime("%Y-%m-%d"), "don_hangs": result}
