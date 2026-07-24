# US-1.1 — Define Identity, Organization and RBAC Contracts

## Description

As the PM Tool backend,

I want to define the data contracts for users, organizations, membership, and role-based permissions,

so that every later story in this epic (and every future domain epic) has a single, consistent representation of identity and tenancy to build on.

## Scope

This story defines the foundational data contracts of EPIC 1.

It must define:

`Base` declarative base

`TimestampMixin`, `SoftDeleteMixin`, `AuditMixin`

`User` model and schemas

`Organization` and `OrganizationMember` models and schemas

`Permission`, `Role`, and `RolePermission` models and schemas

This story is contract-only.

It does not implement authentication, endpoints, permission enforcement, or seed data — those are US-1.2 through US-1.6.

## Implementation Location

Suggested location:

`app/models/base.py`, `app/models/user.py`, `app/models/organization.py`, `app/models/rbac.py`, `app/core/mixins.py`, `app/schemas/user.py`, `app/schemas/organization.py`, `app/schemas/rbac.py`

Model contracts must not be duplicated across `app/schemas/`; Pydantic schemas describe API input/output shape only and never subclass or wrap a SQLAlchemy model directly.

## Code Sketch

Structural skeleton only — attribute declarations are shown since they *are* the contract, but no method bodies beyond `__repr__`. Fill in imports and remaining fields per the `Contracts` section below.

```python
# app/core/mixins.py
class TimestampMixin:
    created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, server_default=func.now(), onupdate=func.now())


class SoftDeleteMixin:
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)


class AuditMixin:
    @declared_attr
    def created_by(cls) -> Mapped[uuid.UUID | None]: ...

    @declared_attr
    def updated_by(cls) -> Mapped[uuid.UUID | None]: ...
```

```python
# app/models/base.py
class Base(DeclarativeBase):
    pass
```

```python
# app/models/user.py
class User(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, server_default=text("gen_random_uuid()"))
    email: Mapped[str] = mapped_column(String, nullable=False, unique=True)
    password_hash: Mapped[str | None] = mapped_column(String, nullable=True)
    first_name: Mapped[str] = mapped_column(String, nullable=False)
    last_name: Mapped[str] = mapped_column(String, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default="true")
    email_verified_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    last_login_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    organization_memberships: Mapped[list["OrganizationMember"]] = relationship(
        back_populates="user", foreign_keys="OrganizationMember.user_id"
    )

    def __repr__(self) -> str: ...
```

```python
# app/models/organization.py
class Organization(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "organizations"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, server_default=text("gen_random_uuid()"))
    created_by: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="RESTRICT"))
    name: Mapped[str] = mapped_column(String, nullable=False)
    slug: Mapped[str] = mapped_column(String, nullable=False, unique=True)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default="true")

    members: Mapped[list["OrganizationMember"]] = relationship(back_populates="organization")

    def __repr__(self) -> str: ...


class OrganizationMember(Base, SoftDeleteMixin):
    __tablename__ = "organization_members"
    __table_args__ = (
        Index("organization_members_active_uk", "organization_id", "user_id", unique=True,
              postgresql_where=text("deleted_at IS NULL")),
        Index("organization_members_user_idx", "user_id"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, server_default=text("gen_random_uuid()"))
    organization_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("organizations.id", ondelete="RESTRICT"))
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="RESTRICT"))
    role_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("roles.id", ondelete="RESTRICT"))
    invited_by: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="RESTRICT"))
    joined_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, server_default=func.now())
    left_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    updated_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, server_default=func.now(), onupdate=func.now())

    organization: Mapped["Organization"] = relationship(back_populates="members")
    user: Mapped["User"] = relationship(foreign_keys=[user_id], back_populates="organization_memberships")
    role: Mapped["Role"] = relationship(foreign_keys=[role_id])

    def __repr__(self) -> str: ...
```

```python
# app/models/rbac.py
class Permission(Base):
    __tablename__ = "permissions"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, server_default=text("gen_random_uuid()"))
    key: Mapped[str] = mapped_column(String, nullable=False, unique=True)
    description: Mapped[str | None] = mapped_column(String, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, server_default=func.now(), onupdate=func.now())

    def __repr__(self) -> str: ...


class Role(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "roles"
    __table_args__ = (
        Index("roles_custom_scope_name_uk", "scope_type", "scope_id", "name", unique=True,
              postgresql_where=text("deleted_at IS NULL AND is_system = false")),
        Index("roles_system_name_uk", "name", unique=True,
              postgresql_where=text("is_system = true AND deleted_at IS NULL")),
        CheckConstraint(
            "(is_system = true AND scope_type IS NULL AND scope_id IS NULL) OR "
            "(is_system = false AND scope_type IS NOT NULL AND scope_id IS NOT NULL)",
            name="roles_scope_consistency_chk",
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, server_default=text("gen_random_uuid()"))
    scope_type: Mapped[str | None] = mapped_column(String, nullable=True)
    scope_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), nullable=True)
    created_by: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="RESTRICT"))
    name: Mapped[str] = mapped_column(String, nullable=False)
    description: Mapped[str | None] = mapped_column(String, nullable=True)
    is_system: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default="false")

    permissions: Mapped[list["Permission"]] = relationship(secondary="role_permissions", viewonly=True)

    def __repr__(self) -> str: ...


class RolePermission(Base):
    __tablename__ = "role_permissions"

    role_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("roles.id", ondelete="RESTRICT"), primary_key=True)
    permission_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("permissions.id", ondelete="RESTRICT"), primary_key=True)
    granted_by: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="RESTRICT"))
    created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, server_default=func.now())

    def __repr__(self) -> str: ...
```

```python
# app/schemas/user.py
class UserCreate(BaseModel):
    email: EmailStr
    password: str
    first_name: str
    last_name: str


class UserRead(BaseModel):
    id: uuid.UUID
    email: EmailStr
    first_name: str
    last_name: str
    is_active: bool
    model_config = ConfigDict(from_attributes=True)
```

```python
# app/schemas/organization.py
class OrganizationCreate(BaseModel):
    name: str
    slug: str


class OrganizationRead(BaseModel):
    id: uuid.UUID
    name: str
    slug: str
    is_active: bool
    model_config = ConfigDict(from_attributes=True)


class OrganizationMemberRead(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    role_id: uuid.UUID
    joined_at: datetime
    model_config = ConfigDict(from_attributes=True)
```

```python
# app/schemas/rbac.py
class PermissionRead(BaseModel):
    id: uuid.UUID
    key: str
    model_config = ConfigDict(from_attributes=True)


class RoleRead(BaseModel):
    id: uuid.UUID
    name: str
    is_system: bool
    model_config = ConfigDict(from_attributes=True)
```

## Global Tenant Rule

No row in `organization_members`, and no future project- or work-item-scoped row, may exist without resolving to exactly one `organization_id` (directly or transitively).

This means:

- `Organization` is the tenant root; every other tenant-scoped entity in later epics traces back to one `Organization` through a foreign key chain.
- A `User` has no tenant of its own — tenancy is always established through an `OrganizationMember` row, never through a column on `User`.

## Soft-Delete Rule

Every entity in this story except `Permission` and `RolePermission` carries a nullable `deleted_at`; `NULL` means the row is active.

This means:

- All repository queries built on top of these models in later stories must filter `WHERE deleted_at IS NULL` unless explicitly listing history.
- Deleting a row here is always an `UPDATE ... SET deleted_at = now()`, never a `DELETE`.

Explicit exceptions (per Decision D2 in `pm-tool-schema-decisiones.md`):

- `Permission` — a fixed, seed-only catalog with no mutable lifecycle.
- `RolePermission` — a pure join row between `Role` and `Permission` with no content of its own to soft-delete.

This rule exists independently of any specific epic's data model — it is the general soft-delete strategy for the whole schema.

---

## Contracts

### Base

The single declarative base every ORM model in the application inherits from.

Required fields:

- (none — structural base class only)

`Base` must be the only `DeclarativeBase` subclass in the application; every model module imports it from `app.models.base`.

### TimestampMixin

Adds `created_at`/`updated_at` auditing to a model.

Required fields:

- `created_at`
- `updated_at`

`created_at` defaults to the database's current timestamp on insert. `updated_at` defaults to the current timestamp on insert and refreshes on every update.

Must not be used on tables that name these columns differently (e.g. `organization_members` uses `joined_at` instead of `created_at` — see that model for the manual pattern).

### SoftDeleteMixin

Adds the soft-delete column described in the Soft-Delete Rule above.

Required fields:

- `deleted_at`

`deleted_at` is nullable; `NULL` means active.

### AuditMixin

Adds `created_by`/`updated_by` to a model, per Decision D8.

Optional fields:

- `created_by` (nullable FK → `users.id`, `ON DELETE RESTRICT`)
- `updated_by` (nullable FK → `users.id`, `ON DELETE RESTRICT`)

Must only be applied to entities editable by more than one person. Must not be applied to entities that only their own owner can edit (e.g. a future `user_preferences`, `sessions`); on those, `updated_by` would always equal the owner and add no information.

### User

A global person identity, independent of any organization.

Required fields:

- `id` (UUID, PK)
- `email` (unique, case-sensitive as stored)
- `first_name`
- `last_name`
- `is_active` (default `true`)

Optional fields:

- `password_hash` (nullable — see Note below)
- `email_verified_at`
- `last_login_at`

`password_hash` is nullable at the schema level (D9: social login may leave it unset), but this story's Pydantic `UserCreate` schema requires a plaintext `password` input, since US-1.3 (registration) is the only creation path implemented in this epic.

A `User` has no organization or role reference of its own; both are resolved exclusively through `OrganizationMember`.

```json
{
  "email": "ada@example.com",
  "first_name": "Ada",
  "last_name": "Lovelace",
  "is_active": true
}
```

### Organization

A tenant root — a company or team using the tool.

Required fields:

- `id` (UUID, PK)
- `name`
- `slug` (globally unique)
- `is_active` (default `true`)

Optional fields:

- `created_by` (nullable FK → `users.id`)

`slug` is immutable-by-convention in this epic (no update endpoint is defined until a later epic); it is only ever set at creation.

### OrganizationMember

The join entity tying a `User` to an `Organization` through exactly one `Role`.

Required fields:

- `id` (UUID, PK)
- `organization_id` (FK → `organizations.id`, `ON DELETE RESTRICT`)
- `user_id` (FK → `users.id`, `ON DELETE RESTRICT`)
- `role_id` (FK → `roles.id`, `ON DELETE RESTRICT`)
- `joined_at` (defaults to current timestamp)

Optional fields:

- `invited_by` (nullable FK → `users.id`)
- `left_at` (nullable — real-world departure, distinct from `deleted_at`)

Does not use `TimestampMixin` — it has `joined_at` instead of `created_at`, and still defines `updated_at` manually.

Uses `SoftDeleteMixin` (`deleted_at`) for correction/erroneous-membership removal, kept conceptually distinct from `left_at` (real departure) even though both may be set together on a normal removal.

A partial unique index on `(organization_id, user_id) WHERE deleted_at IS NULL` allows a user to rejoin after a prior removal.

### Permission

A fixed, seed-only catalog entry — one row per grantable capability.

Required fields:

- `id` (UUID, PK)
- `key` (unique, e.g. `"organizations.members.manage"`)

Optional fields:

- `description`

No public creation endpoint exists for `Permission` in this or any story of this epic; rows are only inserted by `scripts/seed.py` (US-1.5).

### Role

A named, ordered set of `Permission`s, either system-provided or scoped to an organization/project.

Required fields:

- `id` (UUID, PK)
- `name`
- `is_system` (default `false`)

Optional fields:

- `scope_type` (nullable — `organization` \| `project`)
- `scope_id` (nullable — polymorphic, no real FK)
- `created_by` (nullable FK → `users.id`)
- `description`

Allowed `scope_type` values:

- organization
- project

`is_system = true` requires `scope_type`/`scope_id` both `NULL`; `is_system = false` requires both set — enforced by the `roles_scope_consistency_chk` constraint from `pm-tool-schema-pendientes.md`.

This epic (US-1.5) only ever inserts `is_system = true` rows (ADMIN, MEMBER); custom, non-system roles are out of scope here.

### RolePermission

The join row granting one `Permission` to one `Role`.

Required fields:

- `role_id` (FK → `roles.id`, `ON DELETE RESTRICT`, part of composite PK)
- `permission_id` (FK → `permissions.id`, `ON DELETE RESTRICT`, part of composite PK)
- `created_at`

Optional fields:

- `granted_by` (nullable FK → `users.id`)

Composite primary key `(role_id, permission_id)` prevents granting the same permission to the same role twice.

---

## Authorization Data Principle

This story does not implement any endpoint, dependency, or query that reads these tables to make an authorization decision — that is US-1.4 and US-1.6.

Later stories must ensure that every permission check reads `organization_members` → `roles` → `role_permissions` fresh on each request rather than caching a resolved permission set (see Decision D7).

## Domain Rules

A `User` is never directly linked to a `Role` or an `Organization` — only through `OrganizationMember`.

A `User` can have multiple active `OrganizationMember` rows across different organizations simultaneously (D1).

`Organization.slug` is globally unique across all organizations, not just active ones.

`Role.is_system` and `Role.scope_type`/`scope_id` must remain consistent per the CHECK constraint — no contract in this story allows constructing an inconsistent combination.

`RolePermission` cannot express the same `(role_id, permission_id)` pair twice.

This story does not implement authentication, endpoints, permission enforcement, or seed data.

## Acceptance Criteria

`Base` declarative base is defined and is the single base class for all models.

`TimestampMixin`, `SoftDeleteMixin`, and `AuditMixin` contracts are defined.

`User` contract is defined, with `UserCreate`/`UserRead` schemas.

`Organization` and `OrganizationMember` contracts are defined, with corresponding schemas.

`Permission`, `Role`, and `RolePermission` contracts are defined, with corresponding schemas.

The `roles_scope_consistency_chk` rule is enforced by validation at the schema level.

Contract validation exists for all defined contracts.

This story does not implement authentication, endpoints, permission enforcement, or seed data.

## Validation Rules

`User.email` is required and must be a valid email format.

`User.email` must be unique.

`User.password_hash` is not set by any contract in this story (no creation logic yet).

`Organization.name` is required.

`Organization.slug` is required, must be unique, and must match a URL-safe slug pattern.

`OrganizationMember.organization_id`, `.user_id`, and `.role_id` are all required.

`OrganizationMember` must not allow `left_at` to be set without `deleted_at` also being set on removal (enforced at the service layer in a later story; documented here as an invariant of the contract).

`Permission.key` is required and must be unique.

`Role.name` is required.

`Role` must not allow `is_system = true` together with a non-null `scope_type` or `scope_id`.

`Role` must not allow `is_system = false` with a null `scope_type` or `scope_id`.

`RolePermission.role_id` and `.permission_id` are both required and together must be unique.

## Error Handling

Invalid contracts must return deterministic validation errors, using the application's standard `ErrorResponse` shape.

Possible error codes:

INVALID_USER_CONTRACT

INVALID_ORGANIZATION_CONTRACT

INVALID_ORGANIZATION_MEMBER_CONTRACT

INVALID_ROLE_CONTRACT

```json
{
  "error": {
    "code": "INVALID_ROLE_CONTRACT",
    "message": "A system role cannot have a scope_type or scope_id.",
    "details": {}
  }
}
```

## Tasks

Create `app/core/mixins.py` with `TimestampMixin`, `SoftDeleteMixin`, `AuditMixin`.

Define `Base` in `app/models/base.py`.

Define `User` model in `app/models/user.py`.

Define `Organization` and `OrganizationMember` models in `app/models/organization.py`.

Define `Permission`, `Role`, `RolePermission` models in `app/models/rbac.py`.

Define `UserCreate`/`UserRead` schemas in `app/schemas/user.py`.

Define `OrganizationCreate`/`OrganizationRead`/`OrganizationMemberRead` schemas in `app/schemas/organization.py`.

Define `RoleRead`/`PermissionRead` schemas in `app/schemas/rbac.py`.

Implement the `roles_scope_consistency_chk` validation at the schema level.

Add unit tests for valid contracts.

Add unit tests for invalid contracts.

Document contracts under `docs/contracts/identity` and `docs/contracts/rbac`.

## Tests

Valid `User` contract passes validation.

`User` with a malformed email fails validation.

Valid `Organization` contract passes validation.

`Organization` with a missing `slug` fails validation.

Valid `OrganizationMember` contract passes validation.

Valid `Role` contract with `is_system = true` and no scope passes validation.

`Role` with `is_system = true` and a non-null `scope_type` fails validation.

`Role` with `is_system = false` and a null `scope_type` fails validation.

Valid `RolePermission` contract passes validation.

Contract validation does not persist entities.

Contract validation does not call any authentication or authorization module.

## Documentation Required

Create or update:

`docs/contracts/identity/user.md`

`docs/contracts/identity/organization.md`

`docs/contracts/rbac/role.md`

`docs/contracts/rbac/permission.md`

## Dependencies

Existing `app/models/`, `app/schemas/`, `app/core/` module structure.

SQLAlchemy 2.0 declarative mapping conventions already used elsewhere in the repo.

## Definition of Done

`Base` and all three mixins are defined.

`User`, `Organization`, `OrganizationMember`, `Permission`, `Role`, and `RolePermission` contracts are defined.

The `roles_scope_consistency_chk` rule is defined.

Contract validation is implemented.

Deterministic validation errors are implemented.

Required contract docs are updated.

Tests pass.

Backend checks pass.

No authentication, endpoints, permission enforcement, or seed data is implemented in this story.
