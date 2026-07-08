from typing import Optional
from pydantic import BaseModel


class TaoNhanVien(BaseModel):
    name: str
    phone: str = ""
    email: str = ""
    address: str = ""
    notes: str = ""
    role: str = "orderer"


class CapNhatNhanVien(BaseModel):
    name: str
    phone: str = ""
    email: str = ""
    address: str = ""
    notes: str = ""
    role: str = "orderer"
    pin: Optional[str] = None
    is_active: int = 1


class DangNhapPin(BaseModel):
    pin: str
    requested_role: str = ""


class DangKyDangNhap(BaseModel):
    ten: str = ""
    so_dien_thoai: str
    pin: str
