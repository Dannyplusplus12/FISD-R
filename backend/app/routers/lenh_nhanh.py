import json
import re
import unicodedata
from typing import List, Optional

import httpx
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session, joinedload

from app.core.config import settings
from app.database import get_db
from app.models import KhachHang, SanPham

router = APIRouter(tags=["Lệnh nhanh"])

_TU_TIEP_HEAD = {"chi", "anh", "em", "ba", "ong", "co", "chu", "ban"}
_GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"
_GROQ_MODEL = "llama-3.1-8b-instant"
_PROMPT = (
    "Trích xuất thông tin đặt hàng từ lệnh sau. "
    "Chỉ trả về JSON thuần, không giải thích, không markdown.\n\n"
    'Lệnh: "{lenh}"\n\n'
    'Format: {{"khach": "tên khách giữ nguyên hoặc Khách lẻ", '
    '"items": [{{"sp": "tên sản phẩm", "mau": "màu hoặc null", '
    '"size": "kích cỡ hoặc null", "sl": số_lượng}}]}}'
)


def _bo_dau(text: str) -> str:
    nfkd = unicodedata.normalize("NFKD", text.lower().strip())
    ascii_text = "".join(c for c in nfkd if not unicodedata.combining(c))
    return re.sub(r"\s+", " ", ascii_text).strip()


def _goi_groq(lenh: str) -> dict:
    api_key = getattr(settings, "GROQ_API_KEY", "") or ""
    if not api_key:
        raise HTTPException(status_code=503, detail="GROQ_API_KEY chưa được cấu hình")
    prompt = _PROMPT.replace("{lenh}", lenh)
    with httpx.Client(timeout=20) as client:
        r = client.post(
            _GROQ_URL,
            headers={"Authorization": f"Bearer {api_key}"},
            json={
                "model": _GROQ_MODEL,
                "messages": [{"role": "user", "content": prompt}],
                "temperature": 0.1,
            },
        )
        r.raise_for_status()
    raw = r.json()["choices"][0]["message"]["content"].strip()
    raw = re.sub(r"^```json\s*|^```\s*|```$", "", raw, flags=re.MULTILINE).strip()
    return json.loads(raw)


def _tim_khach_theo_ten(ten_raw: str, khach_hangs: list):
    ten_chuan = _bo_dau(ten_raw)
    for kh in sorted(khach_hangs, key=lambda k: len(k.name), reverse=True):
        if _bo_dau(kh.name) == ten_chuan:
            return kh.name, kh.id
    # Bỏ tiếp đầu ngữ
    parts = [p for p in ten_chuan.split() if p not in _TU_TIEP_HEAD]
    ten_bo_tiep = " ".join(parts)
    if ten_bo_tiep:
        for kh in sorted(khach_hangs, key=lambda k: len(k.name), reverse=True):
            kh_chuan = _bo_dau(kh.name)
            if kh_chuan == ten_bo_tiep or ten_bo_tiep in kh_chuan or kh_chuan in ten_bo_tiep:
                return kh.name, kh.id
    return ten_raw if ten_raw and ten_raw != "Khách lẻ" else "Khách lẻ", None


def _tim_san_pham(candidate: str, sp_map: dict):
    if candidate in sp_map:
        return sp_map[candidate]
    for key, sp in sp_map.items():
        if candidate in key or key in candidate:
            return sp
    cand_words = set(candidate.split())
    for key, sp in sp_map.items():
        if cand_words & set(key.split()):
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


def _tim_gio(items: list, san_phams: list, canh_bao: list) -> List[MatHangXemTruoc]:
    sp_map = {_bo_dau(sp.name): sp for sp in san_phams}
    gio: List[MatHangXemTruoc] = []
    for item in items:
        sp = _tim_san_pham(_bo_dau(str(item.get("sp", ""))), sp_map)
        if not sp:
            canh_bao.append(f"Không tìm thấy sản phẩm: '{item.get('sp')}'")
            continue
        mau_chuan = _bo_dau(str(item["mau"])) if item.get("mau") else ""
        kc_chuan = _bo_dau(str(item["size"])) if item.get("size") else ""
        bien_the = None
        for v in sp.variants:
            mau_ok = not mau_chuan or _bo_dau(v.color) == mau_chuan
            kc_ok = not kc_chuan or _bo_dau(v.size) == kc_chuan
            if mau_ok and kc_ok:
                bien_the = v
                break
        if bien_the:
            so_luong = int(item.get("sl", 1))
            gio.append(MatHangXemTruoc(
                bien_the_id=bien_the.id,
                ten_san_pham=sp.name,
                mau_sac=bien_the.color,
                kich_co=bien_the.size,
                don_gia=int(bien_the.price or 0),
                so_luong=so_luong,
                thanh_tien=int(bien_the.price or 0) * so_luong,
            ))
        else:
            canh_bao.append(
                f"'{sp.name}' không có biến thể màu={item.get('mau') or 'bất kỳ'}, "
                f"size={item.get('size') or 'bất kỳ'}"
            )
    return gio


@router.post("/lenh-nhanh", response_model=KetQuaLenhNhanh)
def phan_tich_lenh_nhanh(yeu_cau: YeuCauLenhNhanh, db: Session = Depends(get_db)):
    san_phams = db.query(SanPham).options(joinedload(SanPham.variants)).all()
    khach_hangs = db.query(KhachHang).all()
    canh_bao: List[str] = []

    parsed = _goi_groq(yeu_cau.lenh)
    ten_khach, khach_hang_id = _tim_khach_theo_ten(
        str(parsed.get("khach", "Khách lẻ")), khach_hangs
    )
    gio = _tim_gio(parsed.get("items", []), san_phams, canh_bao)

    if not gio:
        canh_bao.append("Không tìm thấy sản phẩm nào")

    return KetQuaLenhNhanh(
        ten_khach=ten_khach,
        khach_hang_id=khach_hang_id,
        gio=gio,
        canh_bao=canh_bao,
        tong_tien=sum(m.thanh_tien for m in gio),
    )
