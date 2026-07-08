from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base


class KhoHang(Base):
    __tablename__ = "kho_hang"

    id = Column(Integer, primary_key=True, index=True)
    ten = Column("ten", String, default="")
    vi_tri = Column("vi_tri", String, default="")
    ghi_chu = Column("ghi_chu", String, default="")

    vi_tri_bien_thes = relationship("ViTriBienThe", back_populates="kho_hang", cascade="all, delete-orphan")


class ViTriBienThe(Base):
    __tablename__ = "vi_tri_bien_the"

    id = Column(Integer, primary_key=True, index=True)
    ma_bien_the = Column("ma_bien_the", Integer, ForeignKey("bien_the.id", ondelete="CASCADE"))
    ma_kho = Column("ma_kho", Integer, ForeignKey("kho_hang.id", ondelete="CASCADE"))

    kho_hang = relationship("KhoHang", back_populates="vi_tri_bien_thes")
