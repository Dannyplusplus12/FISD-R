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

_PROMPT = """\
Bạn là AI trợ lý bán hàng. Nhân viên nói lệnh tự nhiên, bạn trích xuất thông tin đặt hàng.

Catalog sản phẩm hiện có:
{catalog}

Lệnh nhân viên: "{lenh}"

Quy tắc QUAN TRỌNG:
- LUÔN trả về JSON dù thông tin mơ hồ hay thiếu — đừng bao giờ báo lỗi
- Nếu chỉ nói màu/size mà không nói tên SP → đoán SP trong catalog có màu/size đó
- Nếu nhiều SP cùng màu → chọn SP đầu tiên trong catalog
- Nếu không rõ số lượng → mặc định sl=1
- Nếu không rõ khách → "Khách lẻ"
- "đôi" / "cái" / "chiếc" chỉ là đơn vị đếm, không phải tên SP
- Tên SP trong JSON phải khớp với tên trong catalog (viết đúng như catalog)

Chỉ trả về JSON thuần (không markdown, không giải thích):
{{"khach": "tên khách", "items": [{{"sp": "tên SP đúng trong catalog", "mau": "màu hoặc null", "size": "size hoặc null", "sl": số}}]}}"""


def _bo_dau(text: str) -> str:
    nfkd = unicodedata.normalize("NFKD", text.lower().strip())
    ascii_text = "".join(c for c in nfkd if not unicodedata.combining(c))
    return re.sub(r"\s+", " ", ascii_text).strip()


def _xay_catalog(san_phams: list) -> str:
    """Tạo string catalog gọn để nhét vào prompt."""
    lines = []
    for sp in san_phams[:40]:  # giới hạn 40 SP để prompt không quá dài
        maus = sorted(set(v.color for v in sp.variants if v.color))
        sizes = sorted(set(v.size for v in sp.variants if v.size))
        parts = []
        if maus:
            parts.append("màu: " + "/".join(maus))
        if sizes:
            parts.append("size: " + "/".join(sizes))
        detail = f" ({', '.join(parts)})" if parts else ""
        lines.append(f"- {sp.name}{detail}")
    return "\n".join(lines)


def _goi_groq(lenh: str, catalog: str) -> dict:
    api_key = getattr(settings, "GROQ_API_KEY", "") or ""
    if not api_key:
        raise HTTPException(status_code=503, detail="GROQ_API_KEY chưa được cấu hình")
    prompt = _PROMPT.format(lenh=lenh, catalog=catalog)
    with httpx.Client(timeout=25) as client:
        r = client.post(
            _GROQ_URL,
            headers={"Authorization": f"Bearer {api_key}"},
            json={
                "model": _GROQ_MODEL,
                "messages": [{"role": "user", "content": prompt}],
                "temperature": 0.0,
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
    parts = [p for p in ten_chuan.split() if p not in _TU_TIEP_HEAD]
    ten_bo_tiep = " ".join(parts)
    if ten_bo_tiep:
        for kh in sorted(khach_hangs, key=lambda k: len(k.name), reverse=True):
            kh_chuan = _bo_dau(kh.name)
            if kh_chuan == ten_bo_tiep or ten_bo_tiep in kh_chuan or kh_chuan in ten_bo_tiep:
                return kh.name, kh.id
    return ten_raw if ten_raw and ten_raw != "Khách lẻ" else "Khách lẻ", None


def _tim_san_pham(candidate: str, sp_map: dict):
    if not candidate:
        return None
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


def _tim_bien_the(sp, mau_chuan: str, kc_chuan: str):
    """Tìm biến thể khớp nhất, ưu tiên khớp cả màu+size, rồi màu, rồi size."""
    matches_ca_hai = [
        v for v in sp.variants
        if (not mau_chuan or _bo_dau(v.color) == mau_chuan)
        and (not kc_chuan or _bo_dau(v.size) == kc_chuan)
    ]
    if matches_ca_hai:
        return matches_ca_hai[0]
    if mau_chuan:
        matches_mau = [v for v in sp.variants if _bo_dau(v.color) == mau_chuan]
        if matches_mau:
            return matches_mau[0]
    if kc_chuan:
        matches_kc = [v for v in sp.variants if _bo_dau(v.size) == kc_chuan]
        if matches_kc:
            return matches_kc[0]
    return sp.variants[0] if sp.variants else None


def _tim_sp_theo_mau_size(mau_chuan: str, kc_chuan: str, san_phams: list):
    """Fallback: khi không rõ SP, tìm qua màu/size trong toàn bộ catalog."""
    if not mau_chuan and not kc_chuan:
        return None, None
    for sp in san_phams:
        bt = _tim_bien_the(sp, mau_chuan, kc_chuan)
        if bt:
            return sp, bt
    return None, None


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


def _xu_ly_items(items: list, san_phams: list, sp_map: dict) -> tuple[List[MatHangXemTruoc], List[str]]:
    gio: List[MatHangXemTruoc] = []
    canh_bao: List[str] = []

    for item in items:
        ten_sp_raw = str(item.get("sp") or "").strip()
        mau_chuan = _bo_dau(str(item["mau"])) if item.get("mau") else ""
        kc_chuan = _bo_dau(str(item["size"])) if item.get("size") else ""
        so_luong = max(1, int(item.get("sl") or 1))

        sp = _tim_san_pham(_bo_dau(ten_sp_raw), sp_map) if ten_sp_raw else None

        # Fallback: tìm qua màu/size nếu không có tên SP
        if sp is None:
            sp, bien_the = _tim_sp_theo_mau_size(mau_chuan, kc_chuan, san_phams)
        else:
            bien_the = _tim_bien_the(sp, mau_chuan, kc_chuan)

        if sp is None or bien_the is None:
            # Vẫn không ra — bỏ qua lặng lẽ, không báo lỗi to
            if ten_sp_raw:
                canh_bao.append(f"Không tìm được '{ten_sp_raw}' — bỏ qua")
            continue

        gio.append(MatHangXemTruoc(
            bien_the_id=bien_the.id,
            ten_san_pham=sp.name,
            mau_sac=bien_the.color,
            kich_co=bien_the.size,
            don_gia=int(bien_the.price or 0),
            so_luong=so_luong,
            thanh_tien=int(bien_the.price or 0) * so_luong,
        ))

    return gio, canh_bao


@router.post("/lenh-nhanh", response_model=KetQuaLenhNhanh)
def phan_tich_lenh_nhanh(yeu_cau: YeuCauLenhNhanh, db: Session = Depends(get_db)):
    san_phams = db.query(SanPham).options(joinedload(SanPham.variants)).all()
    khach_hangs = db.query(KhachHang).all()

    catalog = _xay_catalog(san_phams)
    sp_map = {_bo_dau(sp.name): sp for sp in san_phams}

    parsed = _goi_groq(yeu_cau.lenh, catalog)

    ten_khach, khach_hang_id = _tim_khach_theo_ten(
        str(parsed.get("khach") or "Khách lẻ"), khach_hangs
    )

    gio, canh_bao = _xu_ly_items(
        parsed.get("items") or [], san_phams, sp_map
    )

    if not gio:
        canh_bao.append("Không tìm được sản phẩm — hãy kiểm tra lại lệnh")

    return KetQuaLenhNhanh(
        ten_khach=ten_khach,
        khach_hang_id=khach_hang_id,
        gio=gio,
        canh_bao=canh_bao,
        tong_tien=sum(m.thanh_tien for m in gio),
    )
