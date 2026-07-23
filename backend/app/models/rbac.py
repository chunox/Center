"""
Dominio: permissions, roles, role_permissions (Sección 1).
Ver Decisión D3 (roles como conjunto de permisos) y D4 (scope
polimórfico) en pm-tool-schema-decisiones.md.
"""
import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    DateTime,
    ForeignKey,
    Index,
    String,
    func,
    text,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.mixins import SoftDeleteMixin, TimestampMixin
from app.models.base import Base

if TYPE_CHECKING:
    pass


class Permission(Base):
    """Catálogo fijo cargado por scripts/seed.py — sin endpoint de
    creación pública (Historia 7)."""

    __tablename__ = "permissions"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, server_default=text("gen_random_uuid()")
    )
    key: Mapped[str] = mapped_column(String, nullable=False, unique=True)
    description: Mapped[str | None] = mapped_column(String, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, nullable=False, server_default=func.now(), onupdate=func.now()
    )

    def __repr__(self) -> str:
        return f"<Permission key={self.key}>"


class Role(Base, TimestampMixin, SoftDeleteMixin):
    """
    scope_type/scope_id: polimórfico (organization | project), sin FK real
    — ver Decisión D4. is_system=true → rol base global, scope_type/
    scope_id NULL. is_system=false → rol custom de una organización o
    proyecto puntual.
    """

    __tablename__ = "roles"
    __table_args__ = (
        # Únicos parciales — Postgres trata cada NULL como distinto,
        # por eso se separan roles custom (scope_id NOT NULL) de roles
        # de sistema (scope_id NULL). Ver pm-tool-schema.sql.
        Index(
            "roles_custom_scope_name_uk",
            "scope_type",
            "scope_id",
            "name",
            unique=True,
            postgresql_where=text("deleted_at IS NULL AND is_system = false"),
        ),
        Index(
            "roles_system_name_uk",
            "name",
            unique=True,
            postgresql_where=text("is_system = true AND deleted_at IS NULL"),
        ),
        CheckConstraint(
            "(is_system = true AND scope_type IS NULL AND scope_id IS NULL) OR "
            "(is_system = false AND scope_type IS NOT NULL AND scope_id IS NOT NULL)",
            name="roles_scope_consistency_chk",
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, server_default=text("gen_random_uuid()")
    )
    scope_type: Mapped[str | None] = mapped_column(String, nullable=True)
    scope_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), nullable=True)
    created_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="RESTRICT"), nullable=True
    )
    name: Mapped[str] = mapped_column(String, nullable=False)
    description: Mapped[str | None] = mapped_column(String, nullable=True)
    is_system: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default="false")

    permissions: Mapped[list["Permission"]] = relationship(
        secondary="role_permissions", viewonly=True
    )

    def __repr__(self) -> str:
        return f"<Role name={self.name} is_system={self.is_system}>"


class RolePermission(Base):
    __tablename__ = "role_permissions"

    role_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("roles.id", ondelete="RESTRICT"),
        primary_key=True,
    )
    permission_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("permissions.id", ondelete="RESTRICT"),
        primary_key=True,
    )
    granted_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="RESTRICT"), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, server_default=func.now())

    def __repr__(self) -> str:
        return f"<RolePermission role={self.role_id} permission={self.permission_id}>"
