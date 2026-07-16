from typing import List
from pydantic import BaseModel


class TaoKenh(BaseModel):
    ten: str
    thanh_vien_ids: List[int] = []
    chu_kenh_id: int


class ThemThanhVien(BaseModel):
    nhan_vien_id: int
    nguoi_them_id: int
