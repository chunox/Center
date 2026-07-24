# EPIC 1 — Foundation: Identity, Tenancy and RBAC

## Description

As the PM Tool backend, I want to persist user identities, organization tenancy, and role-based permissions, and enforce authentication and real-time authorization on every request, so that every future domain feature can safely operate within a verified user, tenant, and permission context.

## Objective

Build the identity, tenancy, and authorization foundation of the PM Tool backend.

This epic establishes user registration and password authentication, organization creation and membership, and a role-based access control (RBAC) system with a fixed permission catalog and non-cached authorization resolved on every request — required before any project, work item, or collaboration feature can be safely built on top of it.

This epic does not implement projects, work items, ceremonies, documents, messaging, notifications, or email-based invitations.

Social login, multi-device session tracking, and password reset are deferred to a later section of the domain (see `pm-tool-schema-decisiones.md` D9) and are out of scope here; authentication in this epic is stateless, JWT-based.

## Scope

The scope for this epic includes:

Defining the SQLAlchemy models and Pydantic schemas for `User`, `Organization`, `OrganizationMember`, `Permission`, `Role`, and `RolePermission`.

Defining the `TimestampMixin`, `SoftDeleteMixin`, and `AuditMixin` shared by these models.

Persisting these entities in the real database via an Alembic migration.

Implementing user registration with hashed password storage.

Implementing password-based login issuing a signed JWT access token.

Implementing a current-user dependency that resolves identity from the JWT on every request.

Implementing a permission-check dependency that resolves authorization in real time against `roles`/`role_permissions`/`organization_members`, never from a cached claim.

Implementing organization creation, auto-assigning the creator as an Admin member.

Implementing organization membership management (list members, change a member's role, remove a member).

Enforcing soft-delete semantics (`deleted_at`) and the partial-unique reactivation rule on `organization_members`.

Seeding the fixed permission catalog and the system default roles (Admin, Member).

Enforcing deterministic, client-safe error responses for authentication and authorization failures.

## Security Model

This backend uses a role-based access control (RBAC) model scoped per organization.

A `User` is a global identity that can belong to zero or more `Organization`s.

An `OrganizationMember` is the join entity that ties a `User` to an `Organization` through exactly one `Role`, and is the only place a permission set is attached to a person — there is no global role on `User` itself.

A `Role` is a named, ordered set of `Permission`s. Roles marked `is_system = true` are fixed, application-provided roles (Admin, Member) with no `scope_type`/`scope_id`; custom, organization- or project-scoped roles are out of scope for this epic — it only ships the two system roles.

Authorization is never cached: every authorized request re-resolves the caller's role and permissions from the database, per Decision D7 in `pm-tool-schema-decisiones.md` — removing a member takes effect on their very next request, without needing to invalidate a token.

## Roles / Actores

This epic ships 2 system roles:

- ADMIN
- MEMBER

Role scope:

- ADMIN and MEMBER are organization-scoped in this epic (project-scoped custom roles are out of scope here).

Role rules:

- ADMIN may manage organization membership (add, remove, change role).
- MEMBER may read organization membership but may not manage it.
- The user who creates an organization is automatically assigned ADMIN for that organization.

---

## Identity Responsibilities

This epic defines how a person is identified and authenticated in the system.

Each `User` has a globally unique `email`.

Passwords are stored only as a salted hash (`password_hash`), never in plain text.

`password_hash` is nullable at the schema level (D9), but this epic requires every user created through registration to have one set; social login remains unimplemented.

A `User` can be deactivated (`is_active = false`) without deleting their row.

Soft-deleted users (`deleted_at` set) must not be able to authenticate.

## Organization & Tenancy Responsibilities

This epic defines how organizations are created and how users are tied to them.

An `Organization` has a globally unique `slug` used for identification.

Creating an `Organization` requires an authenticated user, who becomes `created_by` and is auto-enrolled as an `OrganizationMember` with role ADMIN.

A `User` can belong to multiple `Organization`s simultaneously (D1) — creating or joining an organization never overwrites a prior membership in a different organization.

Removing a member sets `left_at` and `deleted_at` on their `OrganizationMember` row rather than deleting it, per the soft-delete strategy (D2).

A user who left an organization (or was removed) can be re-added later; the partial unique index on `(organization_id, user_id) WHERE deleted_at IS NULL` allows this.

## RBAC & Authorization Responsibilities

This epic defines how permissions are catalogued, assigned, and checked.

The permission catalog is a fixed set loaded once by `scripts/seed.py`; this epic does not expose an endpoint to create permissions.

Two system roles are seeded — ADMIN and MEMBER — each `is_system = true` with `scope_type`/`scope_id` `NULL`, matching the `roles_scope_consistency_chk` constraint.

Every protected endpoint resolves the caller's permissions by joining `organization_members` → `roles` → `role_permissions` for the organization referenced in the request, at request time.

No permission or role information is embedded in the JWT payload beyond the user's identity (`sub` claim); the token proves identity, not authorization (D7).

## Error Handling Responsibilities

Authentication and authorization failures return a deterministic, client-safe error response.

Invalid credentials return 401 with `error.code = INVALID_CREDENTIALS`, without revealing whether the email exists.

A duplicate email on registration returns 409 with `error.code = EMAIL_ALREADY_REGISTERED`.

Missing or insufficient permission on a protected endpoint returns 403 with `error.code = PERMISSION_DENIED`.

An expired or malformed JWT returns 401 with `error.code = INVALID_TOKEN`.

```json
{
  "error": {
    "code": "PERMISSION_DENIED",
    "message": "You do not have permission to perform this action.",
    "details": {}
  }
}
```

---

## Out of Scope

The following are out of scope for this epic:

- Projects, project members, and project settings.
- Work items, iterations, ceremonies, documents, messaging, and notifications.
- Email-based invitations (`invitations` table).
- Social login and `user_identities`.
- Multi-device session tracking (`sessions`, `user_tokens`) and logout/session revocation.
- Password reset / forgot-password flow.
- Login rate limiting / account lockout after failed attempts.
- Custom (non-system), organization- or project-scoped roles.

## Key User Stories

- Define the Identity, Organization, and RBAC contracts (models, schemas, mixins).
- Implement core application infrastructure (settings, database session, app bootstrap).
- Implement user registration and password login issuing a JWT.
- Implement the current-user and permission-check dependencies.
- Seed the system permission catalog and default roles.
- Implement organization creation and membership management.

## User Stories

US-1.1 — Define Identity, Organization and RBAC Contracts

US-1.2 — Implement Core Application Infrastructure

US-1.3 — Implement Registration and Password Authentication

US-1.4 — Implement Current-User and Permission Authorization Dependencies

US-1.5 — Seed System Permissions and Roles

US-1.6 — Implement Organization Creation and Membership Management

## Dependencies

Existing `app/` layered structure (`api/v1`, `core`, `models`, `repositories`, `schemas`, `services`) as documented in `backend/README.md`.

Existing Alembic async setup (`alembic/env.py`, `alembic.ini`).

`pm-tool-schema-decisiones.md`, `pm-tool-schema-diccionario-datos.md`, `pm-tool-schema-validaciones.md` as the schema source of truth.

uv-managed Python 3.12 environment (`pyproject.toml`).

## Definition of Done

This epic is complete when:

`User`, `Organization`, `OrganizationMember`, `Permission`, `Role`, and `RolePermission` contracts are defined as SQLAlchemy models and Pydantic schemas.

`TimestampMixin`, `SoftDeleteMixin`, and `AuditMixin` are implemented and applied per Decision D8.

All six entities are persisted via an Alembic migration, and `alembic/env.py` imports them for autogenerate.

User registration with hashed passwords is implemented.

Password login issuing a signed JWT access token is implemented.

The current-user dependency resolves identity from the JWT on every request.

The permission-check dependency resolves authorization in real time against `roles`/`role_permissions`/`organization_members`, never from a cached claim.

The partial-unique reactivation rule on `organization_members` is enforced.

The system permission catalog and the ADMIN/MEMBER system roles are seeded by `scripts/seed.py`.

Organization creation, membership listing, role change, and member removal endpoints are implemented.

Authentication and authorization errors return deterministic, client-safe error codes.

OpenAPI / Swagger includes the implemented public endpoints (`/auth`, `/organizations`).

Required contracts are documented under `docs/contracts/identity` and `docs/contracts/rbac`.

Registration, login, organization creation, and membership management flows are covered by tests.

Backend checks pass (lint, type-check, test suite).

No project, work item, ceremony, document, messaging, notification, email-invitation, social-login, session-tracking, password-reset, rate-limiting, or custom-role functionality is implemented in this epic.
