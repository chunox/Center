# US-1.3 — Implement Registration and Password Authentication

## Description

As a person who wants to use PM Tool,

I want to register an account with an email and password, and log in to receive an access token,

so that I can make authenticated requests to the rest of the API.

## Scope

This story implements the first two public, unauthenticated endpoints of the API.

It must define:

`POST /api/v1/auth/register`

`POST /api/v1/auth/login`

Password hashing and JWT issuance in `app/core/security.py`

This story is implementation-only (endpoints and security utilities, building on the `User` contract from US-1.1).

It does not implement social login, session/token persistence, password reset, or login rate limiting.

## Implementation Location

Suggested location:

`app/api/v1/auth.py`, `app/services/auth_service.py`, `app/repositories/user_repository.py`, `app/core/security.py`, `app/schemas/user.py`

Password hashing and JWT encode/decode logic must live only in `app/core/security.py`; no other module may call a hashing or JWT library directly.

## Code Sketch

```python
# app/core/security.py
def hash_password(password: str) -> str: ...
def verify_password(password: str, password_hash: str) -> bool: ...

def create_access_token(user_id: uuid.UUID) -> str: ...
def decode_access_token(token: str) -> uuid.UUID: ...
```

```python
# app/repositories/user_repository.py
class UserRepository:
    def __init__(self, session: AsyncSession): ...

    async def get_by_email(self, email: str) -> User | None: ...
    async def create(self, data: UserCreate, password_hash: str) -> User: ...
    async def update_last_login(self, user_id: uuid.UUID) -> None: ...
```

```python
# app/services/auth_service.py
class AuthService:
    def __init__(self, user_repo: UserRepository): ...

    async def register(self, data: UserCreate) -> User: ...
    async def login(self, email: str, password: str) -> str: ...
```

```python
# app/api/v1/auth.py
router = APIRouter()


@router.post("/register", response_model=UserRead, status_code=201)
async def register(data: UserCreate, db: AsyncSession = Depends(get_db)) -> User: ...


@router.post("/login", response_model=TokenResponse)
async def login(data: LoginRequest, db: AsyncSession = Depends(get_db)) -> TokenResponse: ...
```

## Password Hashing Rule

Passwords are never stored or compared in plain text.

This means:

- Registration hashes the plaintext password before persisting it as `User.password_hash`.
- Login compares the submitted plaintext password against the stored hash using the hashing library's verify function, never with `==`.
- The plaintext password is never logged, never included in any response, and never persisted anywhere other than the hashed column.

## Stateless Token Rule

Authentication in this epic is stateless: the JWT itself is the only artifact proving identity, per the epic's decision to defer `sessions`/`user_tokens` persistence.

This means:

- The JWT payload contains only the user's `id` (`sub` claim) and an expiration (`exp`), signed with `settings.secret_key`.
- No permission or role claim is embedded in the token (see US-1.4's Global Authorization Rule).
- Logout is not implemented in this epic — the client discards the token; the token remains valid until it expires.

---

## Endpoints

### POST /api/v1/auth/register

Creates a new `User` with a hashed password.

Request fields (required):

- `email`
- `password`
- `first_name`
- `last_name`

Response:

- `UserRead` (no `password_hash` field ever included)

Rules:

- `email` must not already belong to an active (`deleted_at IS NULL`) user.
- The password is hashed before the `User` row is inserted.
- The new user is created with `is_active = true` and no organization membership; joining or creating an organization is US-1.6.

```json
{
  "email": "ada@example.com",
  "password": "correct horse battery staple",
  "first_name": "Ada",
  "last_name": "Lovelace"
}
```

### POST /api/v1/auth/login

Authenticates a user by email and password, returning a signed JWT.

Request fields (required):

- `email`
- `password`

Response:

- `access_token`
- `token_type` (`"bearer"`)
- `expires_in` (seconds, derived from `settings.access_token_expire_minutes`)

Rules:

- A soft-deleted or `is_active = false` user cannot log in, and receives the same `INVALID_CREDENTIALS` error as a wrong password (no distinct error code, so as not to leak account state).
- On successful login, `User.last_login_at` is updated to the current timestamp.
- The JWT is signed with `settings.secret_key` and expires after `settings.access_token_expire_minutes`.

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 1800
}
```

---

## Public Endpoint Principle

This story does not implement any endpoint that requires an existing access token — both endpoints here are unauthenticated by design (registration and login are the entry points).

Later stories (US-1.4 onward) must protect every other endpoint with the current-user dependency defined there; none of that protection logic is duplicated here.

## Domain Rules

`User.email` uniqueness is enforced at registration, not just at the database level, so a duplicate returns a deterministic error rather than a raw constraint violation.

A password is hashed exactly once, at registration, and never rehashed or re-derived elsewhere.

Login does not reveal whether the failure was due to a nonexistent email or a wrong password.

This story does not implement social login, session/token persistence, password reset, or login rate limiting.

## Acceptance Criteria

`POST /api/v1/auth/register` creates a user with a hashed password and returns `UserRead`.

Registering with an email already in use returns a deterministic conflict error.

`POST /api/v1/auth/login` returns a signed JWT for valid credentials.

`POST /api/v1/auth/login` returns a deterministic error for invalid credentials, without revealing which factor was wrong.

An inactive or soft-deleted user cannot log in.

`User.last_login_at` is updated on successful login.

This story does not implement social login, session/token persistence, password reset, or login rate limiting.

## Validation Rules

`RegisterRequest.email` is required and must be a valid email format.

`RegisterRequest.password` is required and must meet the minimum length policy (8 characters).

`RegisterRequest.first_name` and `.last_name` are required.

`LoginRequest.email` is required.

`LoginRequest.password` is required.

`UserRead` must never include `password_hash`.

## Error Handling

Invalid contracts must return deterministic validation errors, using the application's standard `ErrorResponse` shape.

Possible error codes:

EMAIL_ALREADY_REGISTERED

INVALID_CREDENTIALS

VALIDATION_ERROR

```json
{
  "error": {
    "code": "INVALID_CREDENTIALS",
    "message": "Incorrect email or password.",
    "details": {}
  }
}
```

## Tasks

Implement password hashing and verification in `app/core/security.py`.

Implement JWT encode/decode helpers in `app/core/security.py`.

Implement `UserRepository.get_by_email` and `.create` in `app/repositories/user_repository.py`.

Implement `AuthService.register` and `.login` in `app/services/auth_service.py`.

Implement `POST /api/v1/auth/register` in `app/api/v1/auth.py`.

Implement `POST /api/v1/auth/login` in `app/api/v1/auth.py`.

Register the auth router in `app/api/v1/router.py`.

Add unit tests for password hashing and JWT encode/decode.

Add integration tests for both endpoints.

Document the endpoints under `docs/contracts/auth.md`.

## Tests

Registering with a new email creates a user and returns `UserRead`.

Registering with an already-registered email fails with `EMAIL_ALREADY_REGISTERED`.

Registering with an invalid email format fails validation.

Logging in with correct credentials returns a valid, decodable JWT.

Logging in with a wrong password fails with `INVALID_CREDENTIALS`.

Logging in with a nonexistent email fails with the same `INVALID_CREDENTIALS` code.

Logging in as an inactive or soft-deleted user fails with `INVALID_CREDENTIALS`.

A successful login updates `last_login_at`.

Registration and login do not create any `OrganizationMember` row.

Registration and login do not call any permission-checking dependency.

## Documentation Required

Create or update:

`docs/contracts/auth.md`

## Dependencies

US-1.1, which defines the `User` model and `UserCreate`/`UserRead` schemas this story persists and returns.

US-1.2, which provides `get_db()`, `AppError`, and the app bootstrap this story's endpoints run on.

A JWT library and a password hashing library added to `pyproject.toml` (e.g. `pyjwt`, `passlib[bcrypt]` or `argon2-cffi`).

## Definition of Done

Registration and login endpoints are implemented.

Password hashing and JWT issuance are implemented.

Deterministic validation and authentication errors are implemented.

Required contract docs are updated.

Tests pass.

Backend checks pass.

No social login, session/token persistence, password reset, or login rate limiting is implemented in this story.
