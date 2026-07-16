from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import ChiTietDon, DonHang, DonHangPicker, SoanKhoTrangThai, ViTriBienThe
from app.realtime import quan_ly_ket_noi
from app.routers.don_hang import _la_picker_cua_don
from app.routers.kho_hang import _tinh_lai_ton_kho
from app.utils import now_vn

router = APIRouter(tags=["Soạn kho"])


class CapNhatMucSoan(BaseModel):
    ma_kho: Optional[int] = None
    so_luong_chon: int = 0
    nhan_vien_id: int


@router.put("/don-hang/{don_id}/soan/muc/{order_item_id}")
def cap_nhat_muc_soan(don_id: int, order_item_id: int, data: CapNhatMucSoan, db: Session = Depends(get_db)):
    try:
        don = db.query(DonHang).filter(DonHang.id == don_id).first()
        if not don:
            raise HTTPException(status_code=404, detail="Đơn hàng không tồn tại")
        if not _la_picker_cua_don(don_id, data.nhan_vien_id, db):
            raise HTTPException(status_code=403, detail="Bạn không phải picker của đơn này")
        ct = db.query(ChiTietDon).filter(ChiTietDon.id == order_item_id, ChiTietDon.order_id == don_id).first()
        if not ct:
            raise HTTPException(status_code=404, detail="Mặt hàng không tồn tại")

        trang_thai = db.query(SoanKhoTrangThai).filter(SoanKhoTrangThai.ma_chi_tiet_don == order_item_id).first()

        # Hoàn lại số lượng đã trừ ở kho cũ (nếu có) trước khi áp dụng lựa chọn mới
        if trang_thai and trang_thai.ma_kho and trang_thai.so_luong_chon:
            row_cu = db.query(ViTriBienThe).filter(
                ViTriBienThe.ma_kho == trang_thai.ma_kho, ViTriBienThe.ma_bien_the == ct.variant_id
            ).first()
            if row_cu:
                row_cu.so_luong = int(row_cu.so_luong or 0) + int(trang_thai.so_luong_chon)
                _tinh_lai_ton_kho(ct.variant_id, db)

        if data.ma_kho and data.so_luong_chon > 0:
            row_moi = db.query(ViTriBienThe).filter(
                ViTriBienThe.ma_kho == data.ma_kho, ViTriBienThe.ma_bien_the == ct.variant_id
            ).first()
            if not row_moi or int(row_moi.so_luong or 0) < data.so_luong_chon:
                raise HTTPException(status_code=400, detail="Kho không đủ số lượng")
            row_moi.so_luong = int(row_moi.so_luong or 0) - data.so_luong_chon
            _tinh_lai_ton_kho(ct.variant_id, db)

        if not trang_thai:
            trang_thai = SoanKhoTrangThai(ma_don_hang=don_id, ma_chi_tiet_don=order_item_id)
            db.add(trang_thai)
        trang_thai.ma_kho = data.ma_kho
        trang_thai.so_luong_chon = data.so_luong_chon
        trang_thai.cap_nhat_boi = data.nhan_vien_id
        trang_thai.thoi_gian_cap_nhat = now_vn().strftime("%Y-%m-%d %H:%M")
        db.commit()

        nguoi_nhan = [p.ma_nhan_vien for p in db.query(DonHangPicker).filter(DonHangPicker.ma_don_hang == don_id).all()]
        quan_ly_ket_noi.broadcast_sync(nguoi_nhan, {
            "type": "soan_kho_update",
            "data": {
                "don_id": don_id, "order_item_id": order_item_id, "ma_kho": data.ma_kho,
                "so_luong_chon": data.so_luong_chon, "cap_nhat_boi": data.nhan_vien_id,
            },
        })
        return {"status": "ok"}
    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))
