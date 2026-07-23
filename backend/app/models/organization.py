"""
Dominio: organizations (Sección 1).
organization_settings se agrega en este mismo archivo en la Sección 4.
"""
import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, DateTime, ForeignKey, Index, String, func, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.mixins import SoftDeleteMixin, TimestampMixin
from app.models.base import Base

if TYPE_CHECKING:
    from app.models.rbac import Role
    from app.models.user import User


class Organization(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "organizations"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, server_default=text("gen_random_uuid()")
    )
    created_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="RESTRICT"), nullable=True
    )
    name: Mapped[str] = mapped_column(String, nullable=False)
    slug: Mapped[str] = mapped_column(String, nullable=False, unique=True)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default="true")

    members: Mapped[list["OrganizationMember"]] = relationship(back_populates="organization")

    def __repr__(self) -> str:
        return f"<Organization id={self.id} slug={self.slug}>"


class OrganizationMember(Base, SoftDeleteMixin):
    """
    NO usa TimestampMixin: la tabla tiene joined_at en vez de created_at.
    left_at = salida real del negocio (distinto de deleted_at, que es
    corrección/borrado por error) — ver Decisión de left_at vs deleted_at.
    """

    __tablename__ = "organization_members"
    __table_args__ = (
        Index(
            "organization_members_active_uk",
            "organization_id",
            "user_id",
            unique=True,
            postgresql_where=text("deleted_at IS NULL"),
        ),
        Index("organization_members_user_idx", "user_id"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, server_default=text("gen_random_uuid()")
    )
    organization_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("organizations.id", ondelete="RESTRICT"), nullable=False
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="RESTRICT"), nullable=False
    )
    role_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("roles.id", ondelete="RESTRICT"), nullable=False
    )
    invited_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="RESTRICT"), nullable=True
    )
    joined_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, server_default=func.now())
    left_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, nullable=False, server_default=func.now(), onupdate=func.now()
    )

    organization: Mapped["Organization"] = relationship(back_populates="members")
    user: Mapped["User"] = relationship(
        foreign_keys=[user_id], back_populates="organization_memberships"
    )
    role: Mapped["Role"] = relationship(foreign_keys=[role_id])

    def __repr__(self) -> str:
        return f"<OrganizationMember org={self.organization_id} user={self.user_id}>"
