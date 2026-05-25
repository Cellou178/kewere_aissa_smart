from sqlalchemy import Column, String, Boolean, Integer, ForeignKey, TIMESTAMP, Numeric
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
import uuid

class Entreprise(Base):
    __tablename__ = "entreprises"
    __table_args__ = {'extend_existing': True}
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    nom = Column(String(150), nullable=False)
    email = Column(String(150), unique=True, nullable=False)
    telephone = Column(String(50))
    pays = Column(String(100))
    devise = Column(String(10), default='XOF')
    date_creation = Column(TIMESTAMP, server_default=func.now())

class Role(Base):
    __tablename__ = "roles"
    __table_args__ = {'extend_existing': True}
    id = Column(Integer, primary_key=True)
    nom = Column(String(50), unique=True, nullable=False)

class Utilisateur(Base):
    __tablename__ = "utilisateurs"
    __table_args__ = {'extend_existing': True}
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    entreprise_id = Column(UUID(as_uuid=True), ForeignKey("entreprises.id", ondelete="CASCADE"))
    ferme_id = Column(UUID(as_uuid=True), nullable=True)
    role_id = Column(Integer, ForeignKey("roles.id"))
    nom = Column(String(150), nullable=False)
    email = Column(String(150), unique=True, nullable=False)
    mot_de_passe = Column(String(255), nullable=False)
    telephone = Column(String(50), nullable=True)
    actif = Column(Boolean, default=True)
    date_creation = Column(TIMESTAMP, server_default=func.now())
    derniere_connexion = Column(TIMESTAMP, nullable=True)
    role = relationship("Role")