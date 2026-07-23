"""
Mixins reusables para los modelos SQLAlchemy.
Aplican el patrón de auditoría documentado en pm-tool-schema-decisiones.md
(Decisión D8): created_by/updated_by solo en entidades editables por más
de una persona; TimestampMixin/SoftDeleteMixin en casi todo el esquema.
"""
import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, declared_attr, mapped_column


class TimestampMixin:
    """created_at / updated_at estándar. No usar en tablas con nombres
    distintos para estos campos (ej. organization_members usa joined_at
    en vez de created_at — ver ese modelo para el patrón manual)."""

    created_at: Mapped[datetime] = mapped_column(
        DateTime, nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, nullable=False, server_default=func.now(), onupdate=func.now()
    )


class SoftDeleteMixin:
    """deleted_at nullable — NULL significa fila activa. Todas las queries
    de repositorio deben filtrar por deleted_at IS NULL salvo que se pida
    explícitamente lo contrario (ej. listar histórico)."""

    deleted_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)


class AuditMixin:
    """created_by / updated_by — FK a users.id. Solo para entidades donde
    más de una persona puede editar el registro. NO usar en entidades que
    solo edita su propio dueño (ver Decisión D8): user_preferences,
    sessions, messages, etc."""

    @declared_attr
    def created_by(cls) -> Mapped[uuid.UUID | None]:
        return mapped_column(
            UUID(as_uuid=True),
            ForeignKey("users.id", ondelete="RESTRICT"),
            nullable=True,
        )

    @declared_attr
    def updated_by(cls) -> Mapped[uuid.UUID | None]:
        return mapped_column(
            UUID(as_uuid=True),
            ForeignKey("users.id", ondelete="RESTRICT"),
            nullable=True,
        )
