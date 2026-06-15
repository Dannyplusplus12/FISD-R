from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relationship
from app.database import Base


class NhanVien(Base):
    __tablename__ = "nhan_vien"

    id = Column(Integer, primary_key=True, index=True)
    name = Column("ten", String, index=True)
    phone = Column("so_dien_thoai", String, default="")
    email = Column("email", String, default="")
    address = Column("dia_chi", String, default="")
    notes = Column("ghi_chu", String, default="")
    role = Column("vai_tro", String, default="orderer")
    pin = Column("ma_pin", String, default="")
    is_active = Column("dang_hoat_dong", Integer, default=1)
    created_at = Column("thoi_gian_tao", String, default="")

    don_hang_tao = relationship("DonHang", foreign_keys="DonHang.created_by_employee_id", back_populates="nguoi_tao")
    don_hang_nhan = relationship("DonHang", foreign_keys="DonHang.assigned_picker_id", back_populates="picker")
    don_hang_giao = relationship("DonHang", foreign_keys="DonHang.delivered_by_id", back_populates="nguoi_giao")
