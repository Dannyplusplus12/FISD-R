from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base


class KhuVuc(Base):
    __tablename__ = "areas"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)

    khach_hangs = relationship("KhachHang", back_populates="khu_vuc")


class KhachHang(Base):
    __tablename__ = "customers"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    phone = Column(String, default="")
    debt = Column(Integer, default=0)
    area_id = Column(Integer, ForeignKey("areas.id"), nullable=True)

    khu_vuc = relationship("KhuVuc", back_populates="khach_hangs")
    lich_su_no = relationship("LichSuNo", back_populates="khach_hang", cascade="all, delete-orphan")


class LichSuNo(Base):
    __tablename__ = "debt_logs"

    id = Column(Integer, primary_key=True, index=True)
    customer_id = Column(Integer, ForeignKey("customers.id"))
    actor_employee_id = Column(Integer, ForeignKey("employees.id"), nullable=True)
    change_amount = Column(Integer, default=0)
    new_balance = Column(Integer, default=0)
    note = Column(String, default="")
    created_at = Column(String, default="")
    created_ts = Column(Integer, default=0)

    khach_hang = relationship("KhachHang", back_populates="lich_su_no")
