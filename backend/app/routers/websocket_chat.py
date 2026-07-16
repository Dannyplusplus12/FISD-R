import json

from fastapi import APIRouter, Query, WebSocket, WebSocketDisconnect

from app.realtime import quan_ly_ket_noi

router = APIRouter(tags=["Realtime"])


@router.websocket("/ws/realtime")
async def websocket_realtime(websocket: WebSocket, nhan_vien_id: int = Query(...)):
    await quan_ly_ket_noi.ket_noi(nhan_vien_id, websocket)
    try:
        while True:
            raw = await websocket.receive_text()
            try:
                msg = json.loads(raw)
            except Exception:
                continue
            loai = msg.get("type", "")
            data = msg.get("data", {}) or {}
            # Tín hiệu WebRTC (offer/answer/ice/call start-join-leave/screen-share): backend chỉ relay
            # theo target_ids/target_id, không xử lý media.
            if loai.startswith("rtc_"):
                targets = data.get("target_ids") or ([data["target_id"]] if data.get("target_id") else [])
                if targets:
                    await quan_ly_ket_noi.broadcast(
                        targets, {"type": loai, "data": {**data, "from_id": nhan_vien_id}}
                    )
    except WebSocketDisconnect:
        pass
    finally:
        quan_ly_ket_noi.ngat_ket_noi(nhan_vien_id, websocket)
