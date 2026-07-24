# US-1.2 — Implement Core Application Infrastructure

## Description

As the PM Tool backend,

I want a working FastAPI application with configuration, a database session, and centralized error handling,

so that every endpoint implemented in this epic (and every future epic) has a running app, a real database connection, and a consistent error contract to build on.

## Scope

This story defines the cross-cutting infrastructure of the application.

It must define:

`Settings` configuration loaded from `.env`

Async database engine and session factory

FastAPI app bootstrap and router mounting

Custom application exceptions and their handlers

This story is implementation-only (infrastructure, no domain endpoints).

It does not implement any domain endpoint, model, or business rule — those are US-1.1 and US-1.3 through US-1.6.

## Implementation Location

Suggested location:

`app/core/config.py`, `app/core/database.py`, `app/core/exceptions.py`, `app/main.py`, `app/api/v1/router.py`

Configuration, database session setup, and exception handling must live only in `app/core/`; no other module may construct its own database engine or define its own settings object.

## Code Sketch

```python
# app/core/config.py
class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    environment: str = "development"
    database_url: str = "sqlite+aiosqlite:///./dev.db"
    secret_key: str = "changeme"
    access_token_expire_minutes: int = 30


@lru_cache
def get_settings() -> Settings: ...
```

```python
# app/core/database.py
engine = create_async_engine(settings.database_url, echo=settings.environment == "development")
SessionLocal = async_sessionmaker(engine, expire_on_commit=False)


async def get_db() -> AsyncGenerator[AsyncSession, None]: ...
```

```python
# app/core/exceptions.py
class AppError(Exception):
    def __init__(self, code: str, message: str, status_code: int, details: dict | None = None): ...


class EmailAlreadyRegisteredError(AppError): ...
class InvalidCredentialsError(AppError): ...
class PermissionDeniedError(AppError): ...


async def app_error_handler(request: Request, exc: AppError) -> JSONResponse: ...
async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse: ...
```

```python
# app/main.py
app = FastAPI(title="PM Tool API", version="0.1.0")
app.add_exception_handler(AppError, app_error_handler)
app.add_exception_handler(Exception, unhandled_exception_handler)
app.include_router(api_router, prefix="/api/v1")


@app.get("/health")
async def health() -> dict[str, str]: ...
```

## Core Principle

`app/core/` contains infrastructure only — no business logic and no direct SQL query ever lives here.

This means:

- `config.py` only reads environment variables into a typed `Settings` object.
- `database.py` only exposes the engine, the session factory, and the `get_db()` dependency.
- Domain-specific queries belong to `app/repositories/`, not `app/core/`.

## Deterministic Error Contract Rule

Every error response returned by the API, in this story and every later one, uses the same JSON shape: `{"error": {"code": ..., "message": ..., "details": {...}}}`.

This means:

- A base `AppError` exception class carries `code`, `message`, and optional `details`.
- A single FastAPI exception handler translates any `AppError` subclass into that JSON shape and the correct HTTP status.
- Later stories in this epic (and future epics) raise a subclass of `AppError` rather than inventing their own error response shape.

This rule exists independently of any specific epic's data model — it is the general error-handling contract for the whole API.

---

## Components

### Settings (`app/core/config.py`)

Typed application configuration read from `.env` via `pydantic-settings`.

Required fields:

- `environment` (default `"development"`)
- `database_url`
- `secret_key`
- `access_token_expire_minutes`

`get_settings()` is cached (`lru_cache`) so the `.env` file is parsed once per process.

### Database session (`app/core/database.py`)

Async SQLAlchemy engine and session factory.

Required behavior:

- `engine` is created from `settings.database_url` via `create_async_engine`.
- `SessionLocal` is an `async_sessionmaker` with `expire_on_commit=False`.
- `get_db()` is a FastAPI dependency yielding one `AsyncSession` per request and closing it afterward.

### Application exceptions (`app/core/exceptions.py`)

Base exception hierarchy for deterministic API errors.

Required behavior:

- `AppError(code: str, message: str, status_code: int, details: dict | None)` base class.
- A FastAPI exception handler registered in `app/main.py` that catches `AppError` and returns the standard error JSON shape with the right status code.
- An unhandled-exception fallback handler that never leaks a stack trace to the client, returning `error.code = INTERNAL_ERROR` with status 500.

### App bootstrap (`app/main.py`, `app/api/v1/router.py`)

FastAPI application instance and router aggregation.

Required behavior:

- `app/main.py` creates the `FastAPI` instance, registers exception handlers, and mounts `api_router` under `/api/v1`.
- `app/api/v1/router.py` aggregates every domain sub-router (auth, organizations, ...) implemented across this epic's later stories.
- `GET /health` continues to report `{"status": "ok", "environment": ...}`.

---

## Infrastructure Usage Principle

This story does not implement any domain endpoint under `/api/v1` beyond what already exists (`/health`).

Later stories must register their routers in `app/api/v1/router.py` and depend on `get_db()` for data access — no domain story may construct its own engine or session.

## Domain Rules

Exactly one `Settings` instance, one `engine`, and one `SessionLocal` exist per process.

Every domain exception raised by later stories in this epic subclasses `AppError`.

No stack trace or internal exception detail is ever included in an API response body.

This story does not implement any domain endpoint, model, or business rule.

## Acceptance Criteria

`Settings` loads configuration from `.env` with documented defaults.

`get_db()` yields a working `AsyncSession` against `settings.database_url`.

`AppError` and its handler produce the standard error JSON shape.

An unhandled exception is caught and returns `INTERNAL_ERROR` without leaking internals.

`GET /health` still returns `{"status": "ok", "environment": ...}`.

This story does not implement any domain endpoint, model, or business rule.

## Validation Rules

`Settings.database_url` must be a valid SQLAlchemy async connection string.

`Settings.secret_key` must be non-empty in any environment other than `development`.

`Settings.access_token_expire_minutes` must be a positive integer.

`AppError.code` must be a non-empty, `SCREAMING_SNAKE_CASE` string.

## Error Handling

Unhandled exceptions must never surface framework or database internals to the client.

Possible error codes:

INTERNAL_ERROR

```json
{
  "error": {
    "code": "INTERNAL_ERROR",
    "message": "Something went wrong. Please try again.",
    "details": {}
  }
}
```

## Tasks

Implement `Settings` in `app/core/config.py`.

Implement async `engine`, `SessionLocal`, and `get_db()` in `app/core/database.py`.

Implement `AppError` and its subclasses in `app/core/exceptions.py`.

Register the `AppError` handler and the unhandled-exception fallback handler in `app/main.py`.

Verify `api_router` mounts correctly under `/api/v1` in `app/main.py`.

Add unit tests for `Settings` defaults and overrides.

Add unit tests for the `AppError` handler's JSON shape and status code.

Add an integration test for `GET /health`.

## Tests

`Settings` loads default values when `.env` is absent.

`Settings` overrides defaults from environment variables.

`get_db()` yields a session that can execute a trivial query.

Raising an `AppError` subclass returns the standard error JSON shape with the declared status code.

An unhandled `Exception` is converted to `INTERNAL_ERROR` with status 500.

`GET /health` returns 200 with the expected payload.

Infrastructure setup does not persist any domain entity.

## Documentation Required

Create or update:

`docs/contracts/errors.md`

## Dependencies

Existing `pyproject.toml` dependencies (`fastapi`, `sqlalchemy`, `pydantic-settings`, `aiosqlite`, `asyncpg`).

Existing `.env.example`.

## Definition of Done

`Settings`, database session, and exception handling are implemented.

The deterministic error contract is defined and enforced.

`app/main.py` bootstraps the app and mounts `api_router`.

`GET /health` passes its test.

Required contract docs are updated.

Tests pass.

Backend checks pass.

No domain endpoint, model, or business rule is implemented in this story.
