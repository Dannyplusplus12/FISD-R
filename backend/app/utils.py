import json
import os
from datetime import datetime, timezone, timedelta

_VN = timezone(timedelta(hours=7))


def now_vn() -> datetime:
    """Current time in Vietnam (UTC+7)."""
    return datetime.now(_VN)


def now_vn_ts() -> int:
    """Current Vietnam time as milliseconds timestamp."""
    return int(now_vn().timestamp() * 1000)


def period_start_vn(so_ngay: int) -> datetime:
    """Start of an N-day window ending now (Vietnam time)."""
    return now_vn() - timedelta(days=so_ngay)


def parse_duong_dan_anh(raw) -> list[str]:
    """Normalise delivery photo paths — always returns a list of strings."""
    if isinstance(raw, list):
        return [str(p) for p in raw if str(p).strip()]
    if not raw:
        return []
    s = str(raw).strip()
    if s.startswith("["):
        try:
            decoded = json.loads(s)
            if isinstance(decoded, list):
                return [str(p) for p in decoded if str(p).strip()]
        except Exception:
            pass
    if "|" in s:
        return [p.strip() for p in s.split("|") if p.strip()]
    return [s] if s else []


def trang_thai_don_vi(trang_thai: str) -> str:
    """Human-readable Vietnamese label for an order status."""
    return {
        "pending": "Chờ duyệt",
        "approved": "Đã duyệt",
        "assigned": "Đang giao",
        "completed": "Hoàn thành",
    }.get(trang_thai, trang_thai)


def safe_basename(ten_file: str) -> str:
    """Return just the filename — strip any directory components to prevent path traversal."""
    return os.path.basename(ten_file.replace("\\", "/"))
