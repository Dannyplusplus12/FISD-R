from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base


class DonHang(Base):
    __tablename__ = "don_hang"

    id = Column(Integer, primary_key=True, index=True)
    customer_name = Column("ten_khach_hang", String, default="Khách lẻ")
    customer_id = Column("ma_khach_hang", Integer, ForeignKey("khach_hang.id"), nullable=True)
    created_at = Column("thoi_gian_tao", String, default="")
    created_ts = Column("dau_moc_tao", Integer, default=0)
    total_amount = Column("tong_tien", Integer, default=0)
    is_draft = Column("la_nhap", Integer, default=0)
    status = Column("trang_thai", String, default="completed")
    picker_note = Column("ghi_chu_picker", String, default="")
    created_by_employee_id = Column("ma_nv_tao", Integer, ForeignKey("nhan_vien.id"), nullable=True)
    assigned_picker_id = Column("ma_picker", Integer, ForeignKey("nhan_vien.id"), nullable=True)
    assigned_at = Column("thoi_gian_nhan", String, default="")
    delivered_by_id = Column("ma_nv_giao", Integer, ForeignKey("nhan_vien.id"), nullable=True)
    delivered_at = Column("thoi_gian_giao", String, default="")
    delivery_photo_path = Column("duong_dan_anh_giao", String, default="")
    telegram_file_id = Column("id_file_telegram", String, default="")
    telegram_message_id = Column("id_tin_telegram", String, default="")

    nguoi_tao = relationship("NhanVien", foreign_keys=[created_by_employee_id], back_populates="don_hang_tao")
    picker = relationship("NhanVien", foreign_keys=[assigned_picker_id], back_populates="don_hang_nhan")
    nguoi_giao = relationship("NhanVien", foreign_keys=[delivered_by_id], back_populates="don_hang_giao")
    chi_tiet = relationship("ChiTietDon", back_populates="don_hang", cascade="all, delete-orphan")


class ChiTietDon(Base):
    __tablename__ = "chi_tiet_don"

    id = Column(Integer, primary_key=True, index=True)
    order_id = Column("ma_don_hang", Integer, ForeignKey("don_hang.id"))
    product_name = Column("ten_san_pham", String, default="")
    variant_id = Column("ma_bien_the", Integer, ForeignKey("bien_the.id"), nullable=True)
    variant_info = Column("thong_tin_bien_the", String, default="")
    quantity = Column("so_luong", Integer, default=1)
    price = Column("don_gia", Integer, default=0)

    don_hang = relationship("DonHang", back_populates="chi_tiet")
