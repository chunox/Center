# US-1.4 — Implement Current-User and Permission Authorization Dependencies

## Description

As the PM Tool backend,

I want a dependency that resolves the caller's identity from a JWT and a dependency that checks the caller's permission within an organization,

so that every protected endpoint in this and future epics can require authentication and authorization without re-implementing the check.

## Scope

This story implements the two shared FastAPI dependencies every protected endpoint will depend on.

It must define:

`get_current_user` dependency

`require_permission(key)` dependency factory

This story is implementation-only (dependencies), building on the JWT issued in US-1.3 and the RBAC contracts from US-1.1.

It does not implement any specific domain endpoint that uses these dependencies beyond the organization endpoints of US-1.6 — future epics reuse these same dependencies rather than defining their own.

## Implementation Location

Suggested location:

`app/core/dependencies.py`

Identity and permission resolution logic must live only in `app/core/dependencies.py`; no router or service in any future epic may decode a JWT or query `role_permissions` directly — they depend on these functions instead.

## Code Sketch

```python
# app/core/dependencies.py
oauth2_scheme = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> User: ...


def require_permission(key: str):
    async def dependency(
        organization_id: uuid.UUID,
        current_user: User = Depends(get_current_user),
        db: AsyncSession = Depends(get_db),
    ) -> None: ...

    return dependency
```

## Global Authorization Rule

Authorization is resolved fresh on every request, never cached in the token or in memory, per Decision D7 in `pm-tool-schema-decisiones.md`.

This means:

- `get_current_user` only establishes identity (who is making the request) by decoding the JWT and loading the `User` row.
- `require_permission` performs a live database query joining `organization_members` → `roles` → `role_permissions` for the organization referenced by the request, every time it runs.
- Removing a member's role or removing them from an organization takes effect on their very next request — no token invalidation or session expiry is required.

Explicit exceptions (none in this story — this rule applies uniformly to every protected endpoint defined from this point forward).

This rule exists independently of any specific epic's data model — it is the general authorization contract for the whole API.

---

## Dependencies (FastAPI)

### get_current_user

Resolves the authenticated `User` from the `Authorization: Bearer <token>` header.

Required behavior:

- Decodes and verifies the JWT signature and expiration using `app.core.security`.
- Loads the `User` row by the `sub` claim.
- Rejects the request if the token is missing, malformed, expired, or its subject no longer resolves to an active, non-deleted user.

```json
{
  "error": {
    "code": "INVALID_TOKEN",
    "message": "Your session is invalid or has expired. Please log in again.",
    "details": {}
  }
}
```

### require_permission(key: str)

A dependency factory returning a dependency that checks the current user holds the given permission key within the organization referenced by the request path.

Required behavior:

- Depends on `get_current_user` internally — a caller must be authenticated before authorization is checked.
- Reads `organization_id` from the request path (e.g. `/organizations/{organization_id}/...`).
- Joins the caller's active `OrganizationMember` row for that `organization_id` to its `Role`, then to `RolePermission`/`Permission`, checking for a row where `Permission.key == key`.
- Rejects the request with `PERMISSION_DENIED` if the caller has no active membership in that organization, or has a membership but lacks the permission.

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

## Dependency Reuse Principle

This story does not implement any endpoint beyond wiring these two dependencies into the FastAPI dependency-injection system for later stories to use.

Later stories (starting with US-1.6, and every future epic) must depend on `get_current_user` for identity and `require_permission("<key>")` for authorization, rather than writing their own JWT decoding or permission query.

## Domain Rules

`get_current_user` never trusts a claim other than the token's signature and expiration and the subject's current, live `User` row state.

`require_permission` never trusts any role or permission information embedded in the JWT — none exists, per the Stateless Token Rule in US-1.3.

A caller with no `OrganizationMember` row for the referenced organization is denied, not treated as having zero permissions on an implicit membership.

This story does not implement any domain endpoint beyond wiring the dependencies themselves.

## Acceptance Criteria

`get_current_user` resolves the authenticated `User` for a valid, unexpired token.

`get_current_user` rejects a missing, malformed, or expired token with `INVALID_TOKEN`.

`get_current_user` rejects a token whose subject is inactive or soft-deleted.

`require_permission(key)` allows a caller whose role in the referenced organization grants that permission.

`require_permission(key)` rejects a caller without an active membership in the referenced organization.

`require_permission(key)` rejects a caller whose role does not grant that permission.

This story does not implement any domain endpoint beyond wiring the dependencies themselves.

## Validation Rules

The `Authorization` header must be present and use the `Bearer` scheme for any endpoint depending on `get_current_user`.

The JWT `sub` claim must be a valid `User.id` UUID.

The `organization_id` path parameter consumed by `require_permission` must be a valid UUID.

## Error Handling

Authentication and authorization failures must return deterministic, client-safe error responses.

Possible error codes:

INVALID_TOKEN

PERMISSION_DENIED

```json
{
  "error": {
    "code": "INVALID_TOKEN",
    "message": "Your session is invalid or has expired. Please log in again.",
    "details": {}
  }
}
```

## Tasks

Implement JWT decoding/verification usage in `get_current_user`.

Implement `User` lookup and active/soft-delete checks in `get_current_user`.

Implement the `organization_members` → `roles` → `role_permissions` join query in `require_permission`.

Implement `require_permission` as a dependency factory parameterized by permission key.

Wire both dependencies for reuse via `app/core/dependencies.py`.

Add unit tests for `get_current_user` with valid, expired, malformed, and orphaned tokens.

Add unit tests for `require_permission` with an authorized member, an unauthorized member, and a non-member.

## Tests

`get_current_user` resolves a valid token to the correct `User`.

`get_current_user` rejects an expired token with `INVALID_TOKEN`.

`get_current_user` rejects a malformed token with `INVALID_TOKEN`.

`get_current_user` rejects a token whose user was deactivated after issuance.

`require_permission` allows an ADMIN member performing an ADMIN-only action.

`require_permission` denies a MEMBER performing an ADMIN-only action.

`require_permission` denies a caller with no membership in the referenced organization.

`require_permission` re-evaluates on every call and does not cache a prior result across requests.

## Documentation Required

Create or update:

`docs/contracts/authorization.md`

## Dependencies

US-1.1, which defines the `OrganizationMember`, `Role`, `Permission`, and `RolePermission` contracts this story queries.

US-1.3, which issues the JWT this story decodes, and `app/core/security.py`'s decode helper.

US-1.2, which provides `get_db()` used by both dependencies to query the database.

## Definition of Done

`get_current_user` is implemented and enforces token validity and account state.

`require_permission` is implemented and resolves authorization live on every call.

Deterministic authentication and authorization errors are implemented.

Required contract docs are updated.

Tests pass.

Backend checks pass.

No domain endpoint beyond wiring these dependencies is implemented in this story.
