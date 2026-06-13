from typing import List, Optional
from pydantic import BaseModel


class BienTheInput(BaseModel):
    id: Optional[int] = None
    color: str = ""
    size: str = ""
    price: int = 0
    stock: int = 0


class TaoSanPham(BaseModel):
    code: str = ""
    name: str
    description: str = ""
    image_path: str = ""
    variants: List[BienTheInput] = []


class CapNhatSanPham(BaseModel):
    code: str = ""
    name: str
    image_path: str = ""
    variants: List[BienTheInput] = []
