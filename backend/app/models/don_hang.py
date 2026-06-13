from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base


class DonHang(Base):
    __tablename__ = "orders"

    id = Column(Integer, primary_key=True, index=True)
    customer_name = Column(String, default="Khách lẻ")
    customer_id = Column(Integer, ForeignKey("customers.id"), nullable=True)
    created_at = Column(String, default="")
    created_ts = Column(Integer, default=0)
    total_amount = Column(Integer, default=0)
    is_draft = Column(Integer, default=0)

    # Status machine: pending → approved → assigned → completed
    status = Column(String, default="completed")

    picker_note = Column(String, default="")

    created_by_employee_id = Column(Integer, ForeignKey("employees.id"), nullable=True)
    assigned_picker_id = Column(Integer, ForeignKey("employees.id"), nullable=True)
    assigned_at = Column(String, default="")
    delivered_by_id = Column(Integer, ForeignKey("employees.id"), nullable=True)
    delivered_at = Column(String, default="")
    delivery_photo_path = Column(String, default="")
    telegram_file_id = Column(String, default="")
    telegram_message_id = Column(String, default="")

    nguoi_tao = relationship("NhanVien", foreign_keys=[created_by_employee_id], back_populates="don_hang_tao")
    picker = relationship("NhanVien", foreign_keys=[assigned_picker_id], back_populates="don_hang_nhan")
    nguoi_giao = relationship("NhanVien", foreign_keys=[delivered_by_id], back_populates="don_hang_giao")
    chi_tiet = relationship("ChiTietDon", back_populates="don_hang", cascade="all, delete-orphan")


class ChiTietDon(Base):
    __tablename__ = "order_items"

    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"))
    product_name = Column(String, default="")
    variant_id = Column(Integer, ForeignKey("variants.id"), nullable=True)
    variant_info = Column(String, default="")
    quantity = Column(Integer, default=1)
    price = Column(Integer, default=0)

    don_hang = relationship("DonHang", back_populates="chi_tiet")
