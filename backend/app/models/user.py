"""
Dominio: users (Sección 1).
Las demás tablas relacionadas con usuario (user_preferences, user_tokens,
sessions, user_identities) se agregan en este mismo archivo durante la
Sección 2 y 4 del plan de desarrollo — no se modelan todavía.
"""
import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, DateTime, String, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.mixins import SoftDeleteMixin, TimestampMixin
from app.models.base import Base

if TYPE_CHECKING:
    from app.models.organization import OrganizationMember


class User(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, server_default=text("gen_random_uuid()")
    )
    email: Mapped[str] = mapped_column(String, nullable=False, unique=True)
    # Nullable: login social (Sección 2) permite no tener password nunca.
    password_hash: Mapped[str | None] = mapped_column(String, nullable=True)
    first_name: Mapped[str] = mapped_column(String, nullable=False)
    last_name: Mapped[str] = mapped_column(String, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default="true")
    email_verified_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    last_login_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    # Relaciones — Sección 1
    organization_memberships: Mapped[list["OrganizationMember"]] = relationship(
        back_populates="user",
        foreign_keys="OrganizationMember.user_id",
    )

    def __repr__(self) -> str:
        return f"<User id={self.id} email={self.email}>"
