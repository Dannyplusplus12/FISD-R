from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base


class SanPham(Base):
    __tablename__ = "san_pham"

    id = Column(Integer, primary_key=True, index=True)
    code = Column("ma_hang", String, index=True, default="")
    name = Column("ten", String, index=True)
    description = Column("mo_ta", String, default="")
    image_path = Column("duong_dan_anh", String, default="")

    variants = relationship("BienThe", back_populates="san_pham", cascade="all, delete-orphan")


class BienThe(Base):
    __tablename__ = "bien_the"

    id = Column(Integer, primary_key=True, index=True)
    product_id = Column("ma_san_pham", Integer, ForeignKey("san_pham.id"))
    color = Column("mau_sac", String, default="")
    size = Column("kich_co", String, default="")
    price = Column("don_gia", Integer, default=0)
    stock = Column("ton_kho", Integer, default=0)

    san_pham = relationship("SanPham", back_populates="variants")
