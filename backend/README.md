# PM Tool — Backend

API para una herramienta de gestión de proyectos (organizaciones, proyectos,
work items jerárquicos, sprints/ceremonias, documentos, chat, notificaciones).
El diseño completo del modelo de datos vive en [`docs/`](docs/) — este README
explica cómo está organizado el **código** y qué va en cada carpeta.

## Stack

- **FastAPI** — capa HTTP
- **SQLAlchemy 2.0** (async) — ORM
- **Alembic** (template async) — migraciones
- **Pydantic Settings** — configuración vía `.env`
- **SQLite** en desarrollo (`aiosqlite`), **Postgres** en producción (`asyncpg`)

## Arranque rápido

```bash
uv sync                              # instala dependencias en .venv
cp .env.example .env                 # ajustar si hace falta
uv run uvicorn app.main:app --reload # http://127.0.0.1:8000/docs
```

## Estructura de carpetas

```
app/
├── main.py           # punto de entrada: crea la app FastAPI, monta el router
├── core/              # infraestructura transversal — nada de lógica de negocio
├── api/v1/            # capa HTTP: un router por dominio
├── schemas/           # Pydantic: forma de los datos que entran/salen por la API
├── services/          # lógica de negocio y reglas de validación cruzada
├── repositories/       # acceso a datos: queries contra los models
└── models/            # SQLAlchemy ORM: refleja 1:1 el esquema de docs/

alembic/                # migraciones de base de datos
scripts/seed.py         # carga de datos iniciales (permisos, roles de sistema)
tests/unit/             # tests sin DB real (mocks/lógica pura)
tests/integration/      # tests contra una DB real (repositories, endpoints)
docs/                   # diseño del schema — fuente de verdad del modelo de datos
```

### `app/core/` — infraestructura, no negocio

| Archivo | Qué va acá |
|---|---|
| `config.py` | `Settings` (pydantic-settings), lee `.env` |
| `database.py` | engine async, `SessionLocal`, dependency `get_db()` |
| `security.py` | hashing de passwords, JWT, cifrado de tokens de proveedor |
| `dependencies.py` | dependencias de FastAPI compartidas (`get_current_user`, checks de permisos) |
| `exceptions.py` | excepciones custom de la app y sus handlers |
| `mixins.py` | `TimestampMixin` / `SoftDeleteMixin` / `AuditMixin` para los models |

Nunca debería haber una query SQL ni una regla de negocio en `core/`.

### `app/models/` — SQLAlchemy ORM

Un archivo por área del dominio, reflejando las tablas de
[`docs/pm-tool-schema-diccionario-datos.md`](docs/pm-tool-schema-diccionario-datos.md):

| Archivo | Tablas |
|---|---|
| `user.py` | `users`, `user_preferences`, `user_tokens`, `sessions`, `user_identities` |
| `organization.py` | `organizations`, `organization_members`, `organization_settings` |
| `rbac.py` | `permissions`, `roles`, `role_permissions` |
| `project.py` | `projects`, `project_members`, `project_settings` |
| `iteration.py` | `iterations`, `work_item_statuses` |
| `work_item.py` | `work_items`, `work_item_assignees`, `work_item_dependencies` |
| `ceremony.py` | `ceremonies`, `ceremony_participants`, `ceremony_work_items` |
| `document.py` | `documents`, `document_work_items` |
| `messaging.py` | `conversations`, `conversation_participants`, `messages` |
| `invitation.py` | `invitations` |
| `activity.py` | `notifications`, `comments`, `activity_log` |

Reglas a seguir (ver [`docs/pm-tool-schema-decisiones.md`](docs/pm-tool-schema-decisiones.md)):
- Heredar `TimestampMixin`/`SoftDeleteMixin` salvo excepción documentada (tablas puente sin contenido mutable, o con nombres de columna distintos — ver `OrganizationMember`).
- `created_by`/`updated_by` solo si la entidad la puede editar más de una persona.
- Ningún método con lógica de negocio acá — solo forma de los datos y relaciones.

### `app/schemas/` — Pydantic

Un archivo por dominio (mismo split que `models/`), con los schemas de
entrada/salida de la API (`UserCreate`, `UserRead`, `ProjectUpdate`, etc.).
No son los models de SQLAlchemy — nunca se importa un model de `app/models`
directamente en un router.

### `app/repositories/` — acceso a datos

Un repositorio por entidad principal. Encapsula las queries (incluido el
`WHERE deleted_at IS NULL` que exige el soft-delete, ver
[`docs/pm-tool-schema-validaciones.md`](docs/pm-tool-schema-validaciones.md)).
Recibe una `AsyncSession` y devuelve models o `None`/listas — sin conocer HTTP
ni schemas Pydantic. `base.py` tiene el repositorio genérico (CRUD común) del
que heredan los demás.

### `app/services/` — lógica de negocio

Acá viven las reglas que el schema de base de datos **no puede garantizar por
sí solo** — ver la sección "NO garantizado a nivel DB" de
`docs/pm-tool-schema-validaciones.md`: validar scope polimórfico, chequear que
un `work_item` y su `iteration`/`status` pertenezcan al mismo proyecto, la
jerarquía válida según `methodology`, etc. Un service orquesta uno o más
repositories dentro de una transacción; nunca arma la respuesta HTTP.

### `app/api/v1/` — routers

Un archivo por dominio. Cada endpoint: recibe la request, la valida contra un
schema de `app/schemas/`, llama a un service, devuelve otro schema. Sin
queries ni lógica de negocio directa acá. `router.py` agrega todos los
sub-routers en `api_router`, que `main.py` monta con prefijo `/api/v1`.

### Flujo de una request

```
Request → api/v1/<dominio>.py (valida con schema)
        → services/<dominio>_service.py (reglas de negocio)
        → repositories/<dominio>_repository.py (query)
        → models/<dominio>.py (tabla real)
        → Response (serializa con schema)
```

## Migraciones

```bash
uv run alembic revision --autogenerate -m "descripción"
uv run alembic upgrade head
```

`alembic/env.py` importa todos los módulos de `app/models/` para que
`Base.metadata` los detecte — al agregar un archivo de modelo nuevo, sumarlo
también al import de `alembic/env.py`.

> **Nota SQLite → Postgres**: en desarrollo se usa SQLite. Algunos models ya
> escritos usan tipos específicos de Postgres (`UUID` nativo,
> `gen_random_uuid()`, índices únicos parciales) que no son 100% compatibles
> con SQLite al autogenerar migraciones. Al migrar a Postgres esto deja de ser
> un problema; mientras tanto, revisar el DDL generado antes de aplicarlo.

## Documentación del schema

Antes de modelar o tocar una tabla, leer en este orden:
1. [`docs/pm-tool-schema-modelo-conceptual.md`](docs/pm-tool-schema-modelo-conceptual.md) — qué representa cada entidad, en criollo.
2. [`docs/pm-tool-schema-diccionario-datos.md`](docs/pm-tool-schema-diccionario-datos.md) — columnas exactas de las 31 tablas.
3. [`docs/pm-tool-schema-decisiones.md`](docs/pm-tool-schema-decisiones.md) — por qué el schema es como es (multi-tenancy, soft-delete, RBAC, scope polimórfico, etc.).
4. [`docs/pm-tool-schema-validaciones.md`](docs/pm-tool-schema-validaciones.md) — qué garantiza la DB vs. qué debe validar el `service`.
