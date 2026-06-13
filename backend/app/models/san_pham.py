from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base


class SanPham(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(String, index=True, default="")
    name = Column(String, index=True)
    description = Column(String, default="")
    image_path = Column(String, default="")

    variants = relationship("BienThe", back_populates="san_pham", cascade="all, delete-orphan")


class BienThe(Base):
    __tablename__ = "variants"

    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id"))
    color = Column(String, default="")
    size = Column(String, default="")
    price = Column(Integer, default=0)
    stock = Column(Integer, default=0)

    san_pham = relationship("SanPham", back_populates="variants")
