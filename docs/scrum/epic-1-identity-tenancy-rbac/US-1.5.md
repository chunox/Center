# US-1.5 — Seed System Permissions and Roles

## Description

As the PM Tool backend,

I want a seed script that loads the fixed permission catalog and the ADMIN/MEMBER system roles,

so that organization creation and membership management (US-1.6) have real, persisted roles to assign instead of requiring manual data entry.

## Scope

This story implements the seed data loading path for this epic's RBAC contracts.

It must define:

The fixed `Permission` catalog for this epic

The ADMIN and MEMBER `Role` rows and their `RolePermission` grants

This story is implementation-only (seed data), building on the RBAC contracts from US-1.1.

It does not implement any endpoint to create, update, or delete permissions or system roles — the catalog is only ever loaded by this script.

## Implementation Location

Suggested location:

`scripts/seed.py`

Permission keys and role-to-permission mappings must be defined only in `scripts/seed.py`; no other module may hardcode a permission key string — future code that checks a permission imports the key as a constant sourced from this script or a shared constants module it defines.

## Code Sketch

```python
# scripts/seed.py
PERMISSIONS = [
    "organizations.members.read",
    "organizations.members.manage",
]

SYSTEM_ROLES = {
    "ADMIN": PERMISSIONS,
    "MEMBER": ["organizations.members.read"],
}


async def upsert_permissions(db: AsyncSession) -> dict[str, Permission]: ...
async def upsert_system_roles(db: AsyncSession, permissions: dict[str, Permission]) -> None: ...


async def main() -> None: ...


if __name__ == "__main__":
    asyncio.run(main())
```

## Idempotent Seed Rule

Running `scripts/seed.py` more than once must never create duplicate rows or fail with a constraint violation.

This means:

- Every `Permission` is inserted with an upsert-by-`key` (insert if missing, otherwise leave untouched).
- Every system `Role` is inserted with an upsert-by-`name` where `is_system = true`.
- Every `RolePermission` grant is inserted only if the `(role_id, permission_id)` pair does not already exist.

---

## Seed Data

### Permission catalog (this epic)

The minimal set of permissions this epic's endpoints check.

Required entries:

- `organizations.members.read` — list members of an organization and view a single member's role.
- `organizations.members.manage` — add a member, change a member's role, or remove a member.

This catalog is not exhaustive of the full domain; later epics extend `scripts/seed.py` with their own permission keys as their endpoints are implemented, following the same `<resource>.<capability>` naming convention.

### System roles

The two fixed, application-provided roles available to every organization.

Required entries:

- ADMIN — `is_system = true`, `scope_type = NULL`, `scope_id = NULL`.
- MEMBER — `is_system = true`, `scope_type = NULL`, `scope_id = NULL`.

### Role → permission grants

| Role | Permissions granted |
|---|---|
| ADMIN | `organizations.members.read`, `organizations.members.manage` |
| MEMBER | `organizations.members.read` |

```json
{
  "role": "ADMIN",
  "permissions": ["organizations.members.read", "organizations.members.manage"]
}
```

---

## Seed Data Usage Principle

This story does not implement organization creation or membership assignment — it only guarantees that a fixed ADMIN and MEMBER `Role` row exist for US-1.6 to reference by id.

Later stories (US-1.6, and any future epic introducing project-scoped custom roles) must look up these system roles by `name` + `is_system = true` rather than hardcoding a UUID, since seed-generated ids are not fixed across environments.

## Domain Rules

The permission catalog is fixed and only grows by editing this script — no runtime code path inserts a `Permission` row.

ADMIN always grants a superset of MEMBER's permissions in this epic; a later epic that adds more organization-scoped permissions must decide ADMIN vs. MEMBER grants explicitly, not by assumption.

Re-running the seed script in any environment (including production) is safe and produces no duplicate or inconsistent data.

This story does not implement any endpoint to create, update, or delete permissions or system roles.

## Acceptance Criteria

Running `scripts/seed.py` on an empty database creates both permissions and both system roles with the correct grants.

Running `scripts/seed.py` a second time makes no changes and raises no error.

`organization_members` created by US-1.6 can reference the seeded ADMIN/MEMBER role ids.

This story does not implement any endpoint to create, update, or delete permissions or system roles.

## Validation Rules

Each `Permission.key` in the catalog is unique within the catalog.

Each system `Role.name` is unique among `is_system = true` roles.

Every `RolePermission` grant references a `Permission.key` that exists in the catalog defined in this same script.

## Error Handling

The seed script is an operational tool, not a public API — it exits with a non-zero status and a clear stderr message on failure rather than returning an HTTP error response.

Possible failure conditions:

Database connection failure — script exits non-zero with a clear message.

A `RolePermission` grant referencing an undefined permission key — script exits non-zero before any insert.

## Tasks

Define the permission catalog constants in `scripts/seed.py`.

Implement idempotent upsert-by-`key` for `Permission` rows.

Implement idempotent upsert-by-`name` (`is_system = true`) for `Role` rows.

Implement idempotent insert-if-missing for `RolePermission` grants.

Wire the script to run via `uv run python scripts/seed.py`.

Add a test that runs the seed script twice against a test database and asserts no duplicates.

Add a test asserting the ADMIN and MEMBER grants match the table above.

## Tests

Running the seed script against an empty database creates exactly 2 permissions and 2 system roles.

ADMIN role has both `organizations.members.read` and `organizations.members.manage`.

MEMBER role has only `organizations.members.read`.

Running the seed script twice does not create duplicate `Permission`, `Role`, or `RolePermission` rows.

Seeding does not create any `User`, `Organization`, or `OrganizationMember` row.

## Documentation Required

Create or update:

`docs/contracts/rbac/permission-catalog.md`

## Dependencies

US-1.1, which defines the `Permission`, `Role`, and `RolePermission` models this script populates.

US-1.2, which provides the database session this script uses to connect.

## Definition of Done

The permission catalog for this epic is seeded.

ADMIN and MEMBER system roles and their grants are seeded.

Seeding is idempotent.

Required contract docs are updated.

Tests pass.

Backend checks pass.

No endpoint to create, update, or delete permissions or system roles is implemented in this story.
