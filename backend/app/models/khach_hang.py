from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base


class KhuVuc(Base):
    __tablename__ = "khu_vuc"

    id = Column(Integer, primary_key=True, index=True)
    name = Column("ten", String, index=True)

    khach_hangs = relationship("KhachHang", back_populates="khu_vuc")


class KhachHang(Base):
    __tablename__ = "khach_hang"

    id = Column(Integer, primary_key=True, index=True)
    name = Column("ten", String, index=True)
    phone = Column("so_dien_thoai", String, default="")
    debt = Column("no_hien_tai", Integer, default=0)
    area_id = Column("ma_khu_vuc", Integer, ForeignKey("khu_vuc.id"), nullable=True)

    khu_vuc = relationship("KhuVuc", back_populates="khach_hangs")
    lich_su_no = relationship("LichSuNo", back_populates="khach_hang", cascade="all, delete-orphan")


class LichSuNo(Base):
    __tablename__ = "lich_su_no"

    id = Column(Integer, primary_key=True, index=True)
    customer_id = Column("ma_khach_hang", Integer, ForeignKey("khach_hang.id"))
    actor_employee_id = Column("ma_nv_thuc_hien", Integer, ForeignKey("nhan_vien.id"), nullable=True)
    change_amount = Column("so_tien_thay_doi", Integer, default=0)
    new_balance = Column("du_no_sau", Integer, default=0)
    note = Column("ghi_chu", String, default="")
    created_at = Column("thoi_gian", String, default="")
    created_ts = Column("dau_moc", Integer, default=0)

    khach_hang = relationship("KhachHang", back_populates="lich_su_no")
