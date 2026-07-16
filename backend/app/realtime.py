import asyncio
from typing import Dict, List, Optional, Set

from fastapi import WebSocket


class QuanLyKetNoi:
    """Quản lý kết nối WebSocket realtime — dùng chung cho chat, soạn kho, tín hiệu WebRTC.

    Chỉ chạy in-process (1 instance Railway) — nếu scale nhiều instance sau này
    cần thay bằng Redis pub/sub.
    """

    def __init__(self):
        self.active: Dict[int, Set[WebSocket]] = {}
        self.loop: Optional[asyncio.AbstractEventLoop] = None

    def dat_loop(self, loop: asyncio.AbstractEventLoop):
        self.loop = loop

    async def ket_noi(self, nhan_vien_id: int, ws: WebSocket):
        await ws.accept()
        self.active.setdefault(nhan_vien_id, set()).add(ws)

    def ngat_ket_noi(self, nhan_vien_id: int, ws: WebSocket):
        conns = self.active.get(nhan_vien_id)
        if conns:
            conns.discard(ws)
            if not conns:
                self.active.pop(nhan_vien_id, None)

    async def _gui_toi(self, nhan_vien_id: int, message: dict):
        for ws in list(self.active.get(nhan_vien_id, [])):
            try:
                await ws.send_json(message)
            except Exception:
                pass

    async def broadcast(self, nhan_vien_ids: List[int], message: dict):
        for nv_id in nhan_vien_ids:
            await self._gui_toi(nv_id, message)

    def broadcast_sync(self, nhan_vien_ids: List[int], message: dict):
        """Gọi an toàn từ route sync (def thường, chạy trong threadpool) — schedule lên event loop chính."""
        if not self.loop or not nhan_vien_ids:
            return
        asyncio.run_coroutine_threadsafe(self.broadcast(nhan_vien_ids, message), self.loop)


quan_ly_ket_noi = QuanLyKetNoi()
