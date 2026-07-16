from sqlalchemy import Column, Integer, String, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from app.database import Base


class DonHangPicker(Base):
    __tablename__ = "don_hang_picker"
    __table_args__ = (UniqueConstraint("ma_don_hang", "ma_nhan_vien", name="uq_don_hang_picker"),)

    id = Column(Integer, primary_key=True, index=True)
    ma_don_hang = Column(Integer, ForeignKey("don_hang.id", ondelete="CASCADE"))
    ma_nhan_vien = Column(Integer, ForeignKey("nhan_vien.id"))
    la_nguoi_nhan_dau = Column(Integer, default=0)
    thoi_gian_them = Column(String, default="")

    don_hang = relationship("DonHang", back_populates="pickers")
    nhan_vien = relationship("NhanVien", back_populates="don_hang_phu")
