from typing import List, Optional
from pydantic import BaseModel


class MatHangGio(BaseModel):
    variant_id: int
    product_name: str = ""
    color: str = ""
    size: str = ""
    price: int
    quantity: int


class YeuCauThanhToan(BaseModel):
    customer_name: str = "Khách lẻ"
    customer_phone: str = ""
    employee_id: Optional[int] = None
    cart: List[MatHangGio]


class CapNhatNgayDon(BaseModel):
    created_at: str


class XacNhanGiaoItem(BaseModel):
    order_item_id: Optional[int] = None
    variant_id: Optional[int] = None
    picked_qty: int = 0


class YeuCauXacNhanGiao(BaseModel):
    items: Optional[List[XacNhanGiaoItem]] = None


class YeuCauNhanDon(BaseModel):
    picker_id: int


class YeuCauGiaoHang(BaseModel):
    picker_id: int
    picker_note: str = ""
    photo_path: str = ""
    items: Optional[List[XacNhanGiaoItem]] = None


class XacNhanLocalAnh(BaseModel):
    order_id: int
    local_file_names: Optional[List[str]] = None
