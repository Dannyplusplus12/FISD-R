import base64
import hashlib
import hmac
import time
from typing import List, Optional

from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, UploadFile
from sqlalchemy import desc
from sqlalchemy.orm import Session

from app import s3
from app.core.config import settings
from app.database import get_db
from app.models import DonHangPicker, KenhChat, NhanVien, TepDinhKem, ThanhVienKenh, TinNhan
from app.realtime import quan_ly_ket_noi
from app.schemas.chat import TaoKenh, ThemThanhVien
from app.utils import now_vn, now_vn_ts

router = APIRouter(tags=["Chat"])

_MAX_CHAT_BYTES = settings.MAX_CHAT_FILE_MB * 1024 * 1024


def _la_thanh_vien(kenh_id: int, nhan_vien_id: int, db: Session) -> bool:
    return db.query(ThanhVienKenh).filter(
        ThanhVienKenh.ma_kenh == kenh_id, ThanhVienKenh.ma_nhan_vien == nhan_vien_id
    ).first() is not None


def _thanh_vien_ids(kenh_id: int, db: Session) -> List[int]:
    return [tv.ma_nhan_vien for tv in db.query(ThanhVienKenh).filter(ThanhVienKenh.ma_kenh == kenh_id).all()]


def _serialize_kenh(kenh: KenhChat, db: Session) -> dict:
    return {
        "id": kenh.id,
        "ten": kenh.ten,
        "loai": kenh.loai,
        "ma_don_hang": kenh.ma_don_hang,
        "chu_kenh_id": kenh.ma_chu_kenh,
        "thanh_vien": [
            {"id": nv.id, "name": nv.name}
            for nv in db.query(NhanVien).join(ThanhVienKenh, ThanhVienKenh.ma_nhan_vien == NhanVien.id)
            .filter(ThanhVienKenh.ma_kenh == kenh.id).all()
        ],
    }


def _serialize_tin_nhan(tn: TinNhan, db: Session) -> dict:
    nguoi_gui = db.query(NhanVien).filter(NhanVien.id == tn.ma_nguoi_gui).first()
    return {
        "id": tn.id,
        "ma_kenh": tn.ma_kenh,
        "nguoi_gui_id": tn.ma_nguoi_gui,
        "ten_nguoi_gui": nguoi_gui.name if nguoi_gui else "",
        "noi_dung": tn.noi_dung or "",
        "loai_tin": tn.loai_tin,
        "thoi_gian_gui": tn.thoi_gian_gui,
        "tep_dinh_kem": [
            {
                "s3_key": t.s3_key, "ten_goc": t.ten_goc, "loai_mime": t.loai_mime,
                "url": s3.presigned_url(t.s3_key),
            }
            for t in tn.tep_dinh_kems
        ],
    }


@router.get("/kenh-chat")
def lay_danh_sach_kenh(nhan_vien_id: int, db: Session = Depends(get_db)):
    kenh_ids = [tv.ma_kenh for tv in db.query(ThanhVienKenh).filter(ThanhVienKenh.ma_nhan_vien == nhan_vien_id).all()]
    kenhs = db.query(KenhChat).filter(KenhChat.id.in_(kenh_ids)).order_by(desc(KenhChat.id)).all()
    return [_serialize_kenh(kenh, db) for kenh in kenhs]


@router.post("/kenh-chat")
def tao_kenh(data: TaoKenh, db: Session = Depends(get_db)):
    ten = data.ten.strip()
    if not ten:
        raise HTTPException(status_code=400, detail="Tên kênh không được để trống")
    chu = db.query(NhanVien).filter(NhanVien.id == data.chu_kenh_id).first()
    if not chu:
        raise HTTPException(status_code=404, detail="Người tạo kênh không tồn tại")
    kenh = KenhChat(
        ten=ten, loai="kenh_tu_do", ma_chu_kenh=data.chu_kenh_id,
        thoi_gian_tao=now_vn().strftime("%Y-%m-%d %H:%M"),
    )
    db.add(kenh)
    db.flush()
    thanh_vien_ids = set(data.thanh_vien_ids) | {data.chu_kenh_id}
    for nv_id in thanh_vien_ids:
        if db.query(NhanVien).filter(NhanVien.id == nv_id).first():
            db.add(ThanhVienKenh(ma_kenh=kenh.id, ma_nhan_vien=nv_id, thoi_gian_tham_gia=kenh.thoi_gian_tao))
    db.commit()
    ket_qua = _serialize_kenh(kenh, db)
    quan_ly_ket_noi.broadcast_sync(list(thanh_vien_ids), {"type": "channel_create", "data": ket_qua})
    return ket_qua


@router.post("/kenh-chat/{kenh_id}/thanh-vien")
def them_thanh_vien(kenh_id: int, data: ThemThanhVien, db: Session = Depends(get_db)):
    try:
        kenh = db.query(KenhChat).filter(KenhChat.id == kenh_id).first()
        if not kenh:
            raise HTTPException(status_code=404, detail="Kênh không tồn tại")
        if kenh.loai == "kenh_tu_do":
            if data.nguoi_them_id != kenh.ma_chu_kenh:
                raise HTTPException(status_code=403, detail="Chỉ chủ kênh mới được thêm thành viên")
        else:
            if not _la_thanh_vien(kenh_id, data.nguoi_them_id, db):
                raise HTTPException(status_code=403, detail="Bạn không phải thành viên kênh này")
        nv_moi = db.query(NhanVien).filter(NhanVien.id == data.nhan_vien_id).first()
        if not nv_moi:
            raise HTTPException(status_code=404, detail="Nhân viên không tồn tại")
        if not _la_thanh_vien(kenh_id, data.nhan_vien_id, db):
            db.add(ThanhVienKenh(
                ma_kenh=kenh_id, ma_nhan_vien=data.nhan_vien_id,
                thoi_gian_tham_gia=now_vn().strftime("%Y-%m-%d %H:%M"),
            ))
        # Kênh theo đơn hàng: thêm thành viên vào kênh thì tự động thêm luôn vào đơn hàng
        if kenh.loai == "kenh_don_hang" and kenh.ma_don_hang:
            da_la_picker = db.query(DonHangPicker).filter(
                DonHangPicker.ma_don_hang == kenh.ma_don_hang, DonHangPicker.ma_nhan_vien == data.nhan_vien_id
            ).first()
            if not da_la_picker:
                db.add(DonHangPicker(
                    ma_don_hang=kenh.ma_don_hang, ma_nhan_vien=data.nhan_vien_id, la_nguoi_nhan_dau=0,
                    thoi_gian_them=now_vn().strftime("%Y-%m-%d %H:%M"),
                ))
        db.commit()
        thanh_vien_ids = _thanh_vien_ids(kenh_id, db)
        quan_ly_ket_noi.broadcast_sync(thanh_vien_ids, {
            "type": "channel_member_add",
            "data": {"kenh_id": kenh_id, "nhan_vien_id": data.nhan_vien_id, "name": nv_moi.name},
        })
        return {"status": "ok"}
    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/kenh-chat/{kenh_id}/thanh-vien/{nv_id}")
def xoa_thanh_vien(kenh_id: int, nv_id: int, nguoi_xoa_id: int = Query(...), db: Session = Depends(get_db)):
    kenh = db.query(KenhChat).filter(KenhChat.id == kenh_id).first()
    if not kenh:
        raise HTTPException(status_code=404, detail="Kênh không tồn tại")
    if nguoi_xoa_id != kenh.ma_chu_kenh:
        raise HTTPException(status_code=403, detail="Chỉ chủ kênh mới được xóa thành viên")
    row = db.query(ThanhVienKenh).filter(
        ThanhVienKenh.ma_kenh == kenh_id, ThanhVienKenh.ma_nhan_vien == nv_id
    ).first()
    if row:
        db.delete(row)
        db.commit()
    thanh_vien_ids = _thanh_vien_ids(kenh_id, db) + [nv_id]
    quan_ly_ket_noi.broadcast_sync(thanh_vien_ids, {
        "type": "channel_member_remove", "data": {"kenh_id": kenh_id, "nhan_vien_id": nv_id},
    })
    return {"status": "ok"}


@router.get("/kenh-chat/{kenh_id}/tin-nhan")
def lay_tin_nhan(kenh_id: int, before_id: Optional[int] = None, limit: int = 50, db: Session = Depends(get_db)):
    gioi_han = min(max(limit, 1), 200)
    query = db.query(TinNhan).filter(TinNhan.ma_kenh == kenh_id)
    if before_id:
        query = query.filter(TinNhan.id < before_id)
    tin_nhans = query.order_by(desc(TinNhan.id)).limit(gioi_han).all()
    return {"data": [_serialize_tin_nhan(t, db) for t in reversed(tin_nhans)], "count": len(tin_nhans)}


@router.post("/kenh-chat/{kenh_id}/tin-nhan")
async def gui_tin_nhan(
    kenh_id: int,
    nguoi_gui_id: int = Form(...),
    noi_dung: str = Form(""),
    files: Optional[List[UploadFile]] = File(None),
    db: Session = Depends(get_db),
):
    kenh = db.query(KenhChat).filter(KenhChat.id == kenh_id).first()
    if not kenh:
        raise HTTPException(status_code=404, detail="Kênh không tồn tại")
    if not _la_thanh_vien(kenh_id, nguoi_gui_id, db):
        raise HTTPException(status_code=403, detail="Bạn không phải thành viên kênh này")
    nguoi_gui = db.query(NhanVien).filter(NhanVien.id == nguoi_gui_id).first()
    if not nguoi_gui:
        raise HTTPException(status_code=404, detail="Người gửi không tồn tại")

    upload_files = [f for f in (files or []) if f is not None and f.filename]
    loai_tin = "text"
    if upload_files:
        loai_tin = "anh" if all((f.content_type or "").startswith("image/") for f in upload_files) else "tep"

    tin_nhan = TinNhan(
        ma_kenh=kenh_id, ma_nguoi_gui=nguoi_gui_id, noi_dung=noi_dung.strip() or None,
        loai_tin=loai_tin, thoi_gian_gui=now_vn().strftime("%Y-%m-%d %H:%M"), dau_moc_gui_ts=now_vn_ts(),
    )
    db.add(tin_nhan)
    db.flush()

    for f in upload_files:
        data = await f.read()
        if len(data) > _MAX_CHAT_BYTES:
            db.rollback()
            raise HTTPException(status_code=400, detail=f"Tệp {f.filename} vượt giới hạn {settings.MAX_CHAT_FILE_MB}MB")
        ext = (f.filename.rsplit(".", 1)[-1] if "." in f.filename else "bin")
        key = s3.upload_bytes(data, f"chat/{kenh_id}/{now_vn().strftime('%Y%m%d%H%M%S')}_{tin_nhan.id}_{f.filename}",
                               ext=ext, content_type=f.content_type)
        db.add(TepDinhKem(
            ma_tin_nhan=tin_nhan.id, s3_key=key, ten_goc=f.filename,
            loai_mime=f.content_type or "", kich_thuoc_byte=len(data),
        ))
    db.commit()
    db.refresh(tin_nhan)

    payload = _serialize_tin_nhan(tin_nhan, db)
    thanh_vien_ids = _thanh_vien_ids(kenh_id, db)
    quan_ly_ket_noi.broadcast_sync(thanh_vien_ids, {"type": "chat_message_new", "data": payload})
    return payload


@router.get("/rtc/turn-credentials")
def turn_credentials(nhan_vien_id: int):
    if not settings.TURN_SECRET or not settings.TURN_URL:
        raise HTTPException(status_code=503, detail="TURN server chưa được cấu hình")
    het_han = int(time.time()) + 3600
    username = f"{het_han}:{nhan_vien_id}"
    credential = base64.b64encode(
        hmac.new(settings.TURN_SECRET.encode(), username.encode(), hashlib.sha1).digest()
    ).decode()
    return {
        "urls": [settings.TURN_URL, "stun:stun.l.google.com:19302"],
        "username": username,
        "credential": credential,
    }
