from sqlalchemy import Column, Integer, String, ForeignKey, UniqueConstraint
from app.database import Base


class SoanKhoTrangThai(Base):
    __tablename__ = "soan_kho_trang_thai"
    __table_args__ = (UniqueConstraint("ma_chi_tiet_don", name="uq_soan_kho_chi_tiet_don"),)

    id = Column(Integer, primary_key=True, index=True)
    ma_don_hang = Column(Integer, ForeignKey("don_hang.id", ondelete="CASCADE"))
    ma_chi_tiet_don = Column(Integer, ForeignKey("chi_tiet_don.id", ondelete="CASCADE"))
    ma_kho = Column(Integer, ForeignKey("kho_hang.id"), nullable=True)
    so_luong_chon = Column(Integer, default=0)
    cap_nhat_boi = Column(Integer, ForeignKey("nhan_vien.id"), nullable=True)
    thoi_gian_cap_nhat = Column(String, default="")
