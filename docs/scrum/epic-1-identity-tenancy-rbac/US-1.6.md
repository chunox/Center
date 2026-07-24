# US-1.6 — Implement Organization Creation and Membership Management

## Description

As an authenticated user,

I want to create an organization and manage who belongs to it and with which role,

so that my team has a tenant to work in and I can control who can administer it.

## Scope

This story implements the organization and membership endpoints of the epic.

It must define:

`POST /api/v1/organizations`

`GET /api/v1/organizations` (mine)

`GET /api/v1/organizations/{organization_id}/members`

`PATCH /api/v1/organizations/{organization_id}/members/{user_id}` (change role)

`DELETE /api/v1/organizations/{organization_id}/members/{user_id}` (remove)

This story is implementation-only (endpoints), building on the contracts from US-1.1, the dependencies from US-1.4, and the seeded roles from US-1.5.

It does not implement email-based invitations, organization settings, or project-level membership — a person is added to an organization directly by id in this epic, not through an invitation flow.

## Implementation Location

Suggested location:

`app/api/v1/organizations.py`, `app/services/membership_service.py`, `app/repositories/organization_repository.py`

Membership business rules (auto-assigning ADMIN to the creator, enforcing the reactivation rule) must live in `app/services/membership_service.py`, not in the router or the repository.

## Code Sketch

```python
# app/repositories/organization_repository.py
class OrganizationRepository:
    def __init__(self, session: AsyncSession): ...

    async def get_by_slug(self, slug: str) -> Organization | None: ...
    async def create(self, data: OrganizationCreate, created_by: uuid.UUID) -> Organization: ...
    async def list_for_user(self, user_id: uuid.UUID) -> list[Organization]: ...
    async def add_member(self, organization_id: uuid.UUID, user_id: uuid.UUID, role_id: uuid.UUID) -> OrganizationMember: ...
    async def list_members(self, organization_id: uuid.UUID) -> list[OrganizationMember]: ...
    async def get_member(self, organization_id: uuid.UUID, user_id: uuid.UUID) -> OrganizationMember | None: ...
    async def count_active_admins(self, organization_id: uuid.UUID) -> int: ...
```

```python
# app/services/membership_service.py
class MembershipService:
    def __init__(self, org_repo: OrganizationRepository): ...

    async def create_organization_with_admin(self, data: OrganizationCreate, creator_id: uuid.UUID) -> Organization: ...
    async def list_members(self, organization_id: uuid.UUID) -> list[OrganizationMember]: ...
    async def change_role(self, organization_id: uuid.UUID, user_id: uuid.UUID, role_id: uuid.UUID) -> OrganizationMember: ...
    async def remove_member(self, organization_id: uuid.UUID, user_id: uuid.UUID) -> None: ...

    async def _assert_last_admin_safe(self, organization_id: uuid.UUID, user_id: uuid.UUID) -> None: ...
```

```python
# app/api/v1/organizations.py
router = APIRouter()


@router.post("", response_model=OrganizationRead, status_code=201)
async def create_organization(
    data: OrganizationCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Organization: ...


@router.get("", response_model=list[OrganizationRead])
async def list_my_organizations(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[Organization]: ...


@router.get("/{organization_id}/members", response_model=list[OrganizationMemberRead])
async def list_members(
    organization_id: uuid.UUID,
    _: None = Depends(require_permission("organizations.members.read")),
    db: AsyncSession = Depends(get_db),
) -> list[OrganizationMember]: ...


@router.patch("/{organization_id}/members/{user_id}", response_model=OrganizationMemberRead)
async def change_member_role(
    organization_id: uuid.UUID,
    user_id: uuid.UUID,
    data: ChangeMemberRoleRequest,
    _: None = Depends(require_permission("organizations.members.manage")),
    db: AsyncSession = Depends(get_db),
) -> OrganizationMember: ...


@router.delete("/{organization_id}/members/{user_id}", status_code=204)
async def remove_member(
    organization_id: uuid.UUID,
    user_id: uuid.UUID,
    _: None = Depends(require_permission("organizations.members.manage")),
    db: AsyncSession = Depends(get_db),
) -> None: ...
```

## Creator-Is-Admin Rule

The user who creates an organization is always its first member, with the ADMIN role.

This means:

- Organization creation and the creator's `OrganizationMember` row are created in the same transaction — an organization is never persisted without its creator also being a member.
- The creator cannot be removed from the organization by removing themself as the sole ADMIN member if it would leave the organization with zero active ADMIN members (see the Last-Admin Rule below).

## Last-Admin Rule

An organization must always have at least one active ADMIN member.

This means:

- Removing a member, or changing a member's role away from ADMIN, is rejected if it would leave the organization with zero active ADMIN members.
- This check re-queries active ADMIN membership count at the time of the operation — it is not based on a cached count.

---

## Endpoints

### POST /api/v1/organizations

Creates a new organization and enrolls the caller as its ADMIN member.

Requires: `get_current_user` (any authenticated user — no prior organization membership needed).

Request fields (required):

- `name`
- `slug`

Response:

- `OrganizationRead`

Rules:

- `slug` must be globally unique among active organizations.
- The caller becomes `Organization.created_by` and is enrolled as an `OrganizationMember` with the seeded ADMIN role, per the Creator-Is-Admin Rule.

```json
{
  "name": "Acme Inc",
  "slug": "acme-inc"
}
```

### GET /api/v1/organizations

Lists the organizations the caller is an active member of.

Requires: `get_current_user`.

Response:

- List of `OrganizationRead`

Rules:

- Only organizations with an active (`deleted_at IS NULL`) `OrganizationMember` row for the caller are returned.

### GET /api/v1/organizations/{organization_id}/members

Lists the active members of an organization.

Requires: `get_current_user` + `require_permission("organizations.members.read")`.

Response:

- List of `OrganizationMemberRead` (including each member's role name)

Rules:

- Only active (`deleted_at IS NULL`) members are returned.

### PATCH /api/v1/organizations/{organization_id}/members/{user_id}

Changes a member's role.

Requires: `get_current_user` + `require_permission("organizations.members.manage")`.

Request fields (required):

- `role_id` (must be one of the seeded system roles for this epic)

Response:

- `OrganizationMemberRead`

Rules:

- Rejected by the Last-Admin Rule if it would demote the organization's only active ADMIN.
- `updated_at` is refreshed on the `OrganizationMember` row.

### DELETE /api/v1/organizations/{organization_id}/members/{user_id}

Removes a member from the organization.

Requires: `get_current_user` + `require_permission("organizations.members.manage")`.

Response:

- 204 No Content

Rules:

- Sets both `left_at` and `deleted_at` on the `OrganizationMember` row — this is a real departure, not a correction (see US-1.1's `OrganizationMember` contract).
- Rejected by the Last-Admin Rule if the member being removed is the organization's only active ADMIN.

---

## Membership Endpoint Principle

This story does not implement email-based invitations — adding a member to an organization by inviting an email address that may not yet have an account is deferred to a future epic covering the `invitations` table.

Later stories (the invitations epic) must ensure the invitation-acceptance flow creates the same kind of `OrganizationMember` row this story creates directly, so both paths converge on one membership contract.

## Domain Rules

An organization is never created without its creator becoming an active ADMIN member in the same transaction.

An organization can never be left with zero active ADMIN members through any operation in this story.

A user re-added to an organization after being removed gets a new `OrganizationMember` row, made possible by the partial unique index from US-1.1.

This story does not implement email-based invitations, organization settings, or project-level membership.

## Acceptance Criteria

Creating an organization persists it and enrolls the creator as ADMIN in one transaction.

`GET /api/v1/organizations` returns only organizations the caller actively belongs to.

`GET /api/v1/organizations/{organization_id}/members` requires `organizations.members.read` and returns only active members.

Changing a member's role requires `organizations.members.manage` and is rejected if it would violate the Last-Admin Rule.

Removing a member requires `organizations.members.manage`, soft-deletes the membership, and is rejected if it would violate the Last-Admin Rule.

A previously removed member can be re-added and appears again as active.

This story does not implement email-based invitations, organization settings, or project-level membership.

## Validation Rules

`CreateOrganizationRequest.name` is required.

`CreateOrganizationRequest.slug` is required, must be unique, and must match a URL-safe slug pattern.

`ChangeMemberRoleRequest.role_id` is required and must reference an existing, seeded system role.

`organization_id` and `user_id` path parameters must be valid UUIDs.

## Error Handling

Invalid requests and rule violations must return deterministic errors, using the application's standard `ErrorResponse` shape.

Possible error codes:

ORGANIZATION_SLUG_ALREADY_TAKEN

ORGANIZATION_NOT_FOUND

MEMBER_NOT_FOUND

LAST_ADMIN_CANNOT_BE_REMOVED

PERMISSION_DENIED

```json
{
  "error": {
    "code": "LAST_ADMIN_CANNOT_BE_REMOVED",
    "message": "An organization must have at least one admin.",
    "details": {}
  }
}
```

## Tasks

Implement `OrganizationRepository` methods for create, list-by-member, and slug uniqueness check.

Implement `MembershipService.create_organization_with_admin`.

Implement `MembershipService.list_members`, `.change_role`, and `.remove_member`, including the Last-Admin Rule check.

Implement `POST /api/v1/organizations` in `app/api/v1/organizations.py`.

Implement `GET /api/v1/organizations` in `app/api/v1/organizations.py`.

Implement `GET /api/v1/organizations/{organization_id}/members` in `app/api/v1/organizations.py`.

Implement `PATCH /api/v1/organizations/{organization_id}/members/{user_id}` in `app/api/v1/organizations.py`.

Implement `DELETE /api/v1/organizations/{organization_id}/members/{user_id}` in `app/api/v1/organizations.py`.

Register the organizations router in `app/api/v1/router.py`.

Add integration tests for all five endpoints, including permission-denied and Last-Admin Rule cases.

## Tests

Creating an organization returns 201 and enrolls the creator as ADMIN.

Creating an organization with a taken slug fails with `ORGANIZATION_SLUG_ALREADY_TAKEN`.

Listing organizations only returns those the caller actively belongs to.

Listing members without `organizations.members.read` fails with `PERMISSION_DENIED`.

Listing members returns only active members.

A MEMBER changing another member's role fails with `PERMISSION_DENIED`.

An ADMIN changing the sole ADMIN's role to MEMBER fails with `LAST_ADMIN_CANNOT_BE_REMOVED`.

An ADMIN removing a non-admin member soft-deletes their membership and sets `left_at`.

An ADMIN removing the organization's only ADMIN fails with `LAST_ADMIN_CANNOT_BE_REMOVED`.

A removed member re-added to the organization appears again in the active members list.

Organization and membership endpoints do not implement or reference any invitation entity.

## Documentation Required

Create or update:

`docs/contracts/organizations.md`

## Dependencies

US-1.1, which defines the `Organization` and `OrganizationMember` contracts this story persists and queries.

US-1.4, which provides `get_current_user` and `require_permission` used by every endpoint in this story.

US-1.5, which seeds the ADMIN/MEMBER roles this story assigns and validates against.

## Definition of Done

Organization creation with creator auto-enrollment as ADMIN is implemented.

Organization listing (mine) is implemented.

Member listing, role change, and removal endpoints are implemented.

The Last-Admin Rule is enforced on role change and removal.

The soft-delete reactivation path for organization membership is verified end to end.

Deterministic errors are implemented for all rule violations.

OpenAPI / Swagger includes all five endpoints.

Required contract docs are updated.

Tests pass.

Backend checks pass.

No email-based invitation, organization settings, or project-level membership functionality is implemented in this story.
