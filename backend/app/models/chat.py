from sqlalchemy import BigInteger, Column, Integer, String, Text, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from app.database import Base


class KenhChat(Base):
    __tablename__ = "kenh_chat"

    id = Column(Integer, primary_key=True, index=True)
    ten = Column(String, default="")
    loai = Column(String, default="kenh_tu_do")  # "kenh_tu_do" | "kenh_don_hang"
    ma_don_hang = Column(Integer, ForeignKey("don_hang.id", ondelete="CASCADE"), nullable=True)
    ma_chu_kenh = Column(Integer, ForeignKey("nhan_vien.id"))
    thoi_gian_tao = Column(String, default="")

    thanh_viens = relationship("ThanhVienKenh", back_populates="kenh_chat", cascade="all, delete-orphan")
    tin_nhans = relationship("TinNhan", back_populates="kenh_chat", cascade="all, delete-orphan")


class ThanhVienKenh(Base):
    __tablename__ = "thanh_vien_kenh"
    __table_args__ = (UniqueConstraint("ma_kenh", "ma_nhan_vien", name="uq_thanh_vien_kenh"),)

    id = Column(Integer, primary_key=True, index=True)
    ma_kenh = Column(Integer, ForeignKey("kenh_chat.id", ondelete="CASCADE"))
    ma_nhan_vien = Column(Integer, ForeignKey("nhan_vien.id"))
    thoi_gian_tham_gia = Column(String, default="")

    kenh_chat = relationship("KenhChat", back_populates="thanh_viens")


class TinNhan(Base):
    __tablename__ = "tin_nhan"

    id = Column(Integer, primary_key=True, index=True)
    ma_kenh = Column(Integer, ForeignKey("kenh_chat.id", ondelete="CASCADE"))
    ma_nguoi_gui = Column(Integer, ForeignKey("nhan_vien.id"))
    noi_dung = Column(Text, nullable=True)
    loai_tin = Column(String, default="text")  # "text" | "anh" | "tep" | "he_thong"
    thoi_gian_gui = Column(String, default="")
    dau_moc_gui_ts = Column(BigInteger, default=0)

    kenh_chat = relationship("KenhChat", back_populates="tin_nhans")
    tep_dinh_kems = relationship("TepDinhKem", back_populates="tin_nhan", cascade="all, delete-orphan")


class TepDinhKem(Base):
    __tablename__ = "tep_dinh_kem"

    id = Column(Integer, primary_key=True, index=True)
    ma_tin_nhan = Column(Integer, ForeignKey("tin_nhan.id", ondelete="CASCADE"))
    s3_key = Column(String, default="")
    ten_goc = Column(String, default="")
    loai_mime = Column(String, default="")
    kich_thuoc_byte = Column(Integer, default=0)

    tin_nhan = relationship("TinNhan", back_populates="tep_dinh_kems")
