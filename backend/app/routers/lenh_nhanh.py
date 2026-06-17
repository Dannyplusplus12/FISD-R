import re
import unicodedata
from typing import List, Optional

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session, joinedload

from app.database import get_db
from app.models import BienThe, KhachHang, SanPham

router = APIRouter(tags=["Lệnh nhanh"])

_TU_TIEP_HEAD = {"chi", "anh", "em", "ba", "ong", "co", "chu", "ban"}
_TU_DON_VI = {"doi", "cai", "chiec", "hop", "bo", "bich", "goi", "tui", "kien"}
_TU_BO_QUA = {"tao", "dat", "them", "mua", "gom", "lenh", "nhanh", "don", "hang", "cho"}


def _bo_dau(text: str) -> str:
    nfkd = unicodedata.normalize("NFKD", text.lower().strip())
    ascii_text = "".join(c for c in nfkd if not unicodedata.combining(c))
    return re.sub(r"\s+", " ", ascii_text).strip()


def _tim_khach(lenh_chuan: str, khach_hangs: list):
    """Trả về (ten_khach, khach_hang_id, lenh_con_lai)"""
    # Khớp tên đầy đủ trong DB (dài nhất trước)
    for kh in sorted(khach_hangs, key=lambda k: len(k.name), reverse=True):
        kh_chuan = _bo_dau(kh.name)
        if len(kh_chuan) >= 2 and kh_chuan in lenh_chuan:
            return kh.name, kh.id, lenh_chuan.replace(kh_chuan, " ")

    # Thử "chị/anh X" patterns
    for title in _TU_TIEP_HEAD:
        m = re.search(rf"\b{re.escape(title)}\s+([a-z]+)", lenh_chuan)
        if m:
            ten_raw = m.group(1)
            for kh in khach_hangs:
                parts = _bo_dau(kh.name).split()
                if ten_raw in parts:
                    return kh.name, kh.id, lenh_chuan.replace(m.group(0), " ")
            # Không có trong DB — dùng tên từ lệnh
            ten_hien = title.capitalize() + " " + ten_raw.capitalize()
            return ten_hien, None, lenh_chuan.replace(m.group(0), " ")

    return "Khách lẻ", None, lenh_chuan


def _tim_san_pham(candidate: str, sp_map: dict):
    if candidate in sp_map:
        return sp_map[candidate]
    for key, sp in sp_map.items():
        if candidate in key or key in candidate:
            return sp
    # Khớp theo từng từ
    cand_words = set(candidate.split())
    for key, sp in sp_map.items():
        key_words = set(key.split())
        if cand_words & key_words:
            return sp
    return None


class YeuCauLenhNhanh(BaseModel):
    lenh: str


class MatHangXemTruoc(BaseModel):
    bien_the_id: int
    ten_san_pham: str
    mau_sac: str
    kich_co: str
    don_gia: int
    so_luong: int
    thanh_tien: int


class KetQuaLenhNhanh(BaseModel):
    ten_khach: str
    khach_hang_id: Optional[int] = None
    gio: List[MatHangXemTruoc]
    canh_bao: List[str]
    tong_tien: int


@router.post("/lenh-nhanh", response_model=KetQuaLenhNhanh)
def phan_tich_lenh_nhanh(yeu_cau: YeuCauLenhNhanh, db: Session = Depends(get_db)):
    san_phams = db.query(SanPham).options(joinedload(SanPham.variants)).all()
    khach_hangs = db.query(KhachHang).all()

    lenh_chuan = _bo_dau(yeu_cau.lenh)
    canh_bao: List[str] = []

    sp_map = {_bo_dau(sp.name): sp for sp in san_phams}

    ten_khach, khach_hang_id, lenh_con = _tim_khach(lenh_chuan, khach_hangs)

    tokens = [t for t in lenh_con.split() if t not in _TU_BO_QUA]

    gio: List[MatHangXemTruoc] = []
    i = 0

    while i < len(tokens):
        t = tokens[i]

        if not re.match(r"^\d+$", t):
            i += 1
            continue

        so_luong = int(t)
        i += 1

        # Bỏ qua đơn vị đếm
        if i < len(tokens) and tokens[i] in _TU_DON_VI:
            i += 1

        # Tìm sản phẩm (thử combo 1-4 token)
        san_pham_found = None
        tokens_used = 0
        for n in range(min(4, len(tokens) - i), 0, -1):
            candidate = " ".join(tokens[i : i + n])
            sp = _tim_san_pham(candidate, sp_map)
            if sp:
                san_pham_found = sp
                tokens_used = n
                break

        if not san_pham_found:
            if i < len(tokens):
                canh_bao.append(f"Không nhận ra sản phẩm: '{tokens[i]}'")
                i += 1
            continue

        i += tokens_used

        mau_chuan_map = {_bo_dau(v.color): v.color for v in san_pham_found.variants if v.color}
        kc_chuan_map = {_bo_dau(v.size): v.size for v in san_pham_found.variants if v.size}

        mau_chuan = ""
        kc_chuan = ""

        # Tiêu thụ các token màu/size tiếp theo
        while i < len(tokens):
            tok = tokens[i]
            if tok in mau_chuan_map and not mau_chuan:
                mau_chuan = tok
                i += 1
            elif tok in kc_chuan_map and not kc_chuan:
                kc_chuan = tok
                i += 1
            else:
                break

        # Tìm biến thể khớp
        bien_the = None
        for v in san_pham_found.variants:
            mau_ok = not mau_chuan or _bo_dau(v.color) == mau_chuan
            kc_ok = not kc_chuan or _bo_dau(v.size) == kc_chuan
            if mau_ok and kc_ok:
                bien_the = v
                break

        if bien_the:
            gio.append(
                MatHangXemTruoc(
                    bien_the_id=bien_the.id,
                    ten_san_pham=san_pham_found.name,
                    mau_sac=bien_the.color,
                    kich_co=bien_the.size,
                    don_gia=int(bien_the.price or 0),
                    so_luong=so_luong,
                    thanh_tien=int(bien_the.price or 0) * so_luong,
                )
            )
        else:
            mau_hien = mau_chuan_map.get(mau_chuan, mau_chuan) or "bất kỳ"
            kc_hien = kc_chuan_map.get(kc_chuan, kc_chuan) or "bất kỳ"
            canh_bao.append(
                f"'{san_pham_found.name}' không có biến thể màu={mau_hien}, size={kc_hien}"
            )

    if not gio:
        canh_bao.append("Không tìm thấy sản phẩm nào trong lệnh này")

    return KetQuaLenhNhanh(
        ten_khach=ten_khach,
        khach_hang_id=khach_hang_id,
        gio=gio,
        canh_bao=canh_bao,
        tong_tien=sum(m.thanh_tien for m in gio),
    )
