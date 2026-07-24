# Graph Report - .  (2026-07-24)

## Corpus Check
- Corpus is ~24,602 words - fits in a single context window. You may not need a graph.

## Summary
- 317 nodes · 409 edges · 86 communities (77 shown, 9 thin omitted)
- Extraction: 94% EXTRACTED · 6% INFERRED · 0% AMBIGUOUS · INFERRED: 24 edges (avg confidence: 0.86)
- Token cost: 221,960 input · 0 output

## Community Hubs (Navigation)
- PM Tool DB Schema & Data Dictionary
- RBAC & Auth Contracts (US-1.1/1.3-1.6)
- Epic-1 RBAC Design Decisions
- Frontend tsconfig.app.json
- Backend App Bootstrap & Config
- Frontend package.json Dependencies
- Frontend tsconfig.node.json
- Project READMEs & Docs Index
- Frontend devDependencies
- Backend Core Mixins (Audit/Timestamp/SoftDelete)
- Frontend App Shell & API Client
- Scrum Format Guides & Templates
- Frontend vite-env.d.ts
- Frontend tsconfig Root
- US-1.1 AuditMixin Reference
- US-1.2 Database Session
- US-1.2 get_db Dependency
- US-1.2 Settings Reference
- US-1.6 List Organizations Endpoint
- Frontend README Components Dir
- Backend Package (pyproject.toml)

## God Nodes (most connected - your core abstractions)
1. `app/models (SQLAlchemy ORM layer)` - 36 edges
2. `users table` - 26 edges
3. `EPIC 1 — Foundation: Identity, Tenancy and RBAC` - 24 edges
4. `compilerOptions` - 17 edges
5. `roles table` - 17 edges
6. `work_items table` - 16 edges
7. `Modelo conceptual — Herramienta de gestión de proyectos` - 14 edges
8. `US-1.1 — Define Identity, Organization and RBAC Contracts` - 14 edges
9. `compilerOptions` - 13 edges
10. `projects table` - 11 edges

## Surprising Connections (you probably didn't know these)
- `US-1.1 — Define Identity, Organization and RBAC Contracts` --cites--> `roles_scope_consistency_chk CHECK constraint`  [EXTRACTED]
  docs/scrum/epic-1-identity-tenancy-rbac/US-1.1.md → backend/docs/pm-tool-schema-pendientes.md
- `Center — PM Tool Monorepo` --references--> `PM Tool Backend API`  [EXTRACTED]
  README.md → backend/README.md
- `EPIC 1 — Foundation: Identity, Tenancy and RBAC` --references--> `PM Tool Backend API`  [EXTRACTED]
  docs/scrum/epic-1-identity-tenancy-rbac/EPIC-1.md → backend/README.md
- `Core Principle (app/core is infra-only)` --conceptually_related_to--> `app/core (infrastructure layer)`  [INFERRED]
  docs/scrum/epic-1-identity-tenancy-rbac/US-1.2.md → backend/README.md
- `US-1.1 — Define Identity, Organization and RBAC Contracts` --references--> `app/models (SQLAlchemy ORM layer)`  [EXTRACTED]
  docs/scrum/epic-1-identity-tenancy-rbac/US-1.1.md → backend/README.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **RBAC Domain Model Entities** — docs_scrum_epic_1_identity_tenancy_rbac_us_1_1_user, docs_scrum_epic_1_identity_tenancy_rbac_us_1_1_organizationmember, docs_scrum_epic_1_identity_tenancy_rbac_us_1_1_role, docs_scrum_epic_1_identity_tenancy_rbac_us_1_1_permission, docs_scrum_epic_1_identity_tenancy_rbac_us_1_1_rolepermission [INFERRED 0.85]
- **Epic 1 User Stories Delivering RBAC Foundation** — docs_scrum_epic_1_identity_tenancy_rbac_epic_1_doc, docs_scrum_epic_1_identity_tenancy_rbac_us_1_1_doc, docs_scrum_epic_1_identity_tenancy_rbac_us_1_2_doc, docs_scrum_epic_1_identity_tenancy_rbac_us_1_3_doc, docs_scrum_epic_1_identity_tenancy_rbac_us_1_4_doc, docs_scrum_epic_1_identity_tenancy_rbac_us_1_5_doc, docs_scrum_epic_1_identity_tenancy_rbac_us_1_6_doc [EXTRACTED 1.00]
- **PM Tool Schema Design Documentation Set** — backend_docs_pm_tool_schema_decisiones_doc, backend_docs_pm_tool_schema_diccionario_datos_doc, backend_docs_pm_tool_schema_modelo_conceptual_doc, backend_docs_pm_tool_schema_validaciones_doc [INFERRED 0.85]

## Communities (86 total, 9 thin omitted)

### Community 0 - "PM Tool DB Schema & Data Dictionary"
Cohesion: 0.15
Nodes (42): D10 — Agile methodology without fixed flow, D11 — Separation of conversations and comments, D4 — Polymorphic scope for cross-entity relations, D5 — work_items self-referencing hierarchy, activity_log table, ceremonies table, ceremony_participants table, ceremony_work_items table (+34 more)

### Community 1 - "RBAC & Auth Contracts (US-1.1/1.3-1.6)"
Cohesion: 0.07
Nodes (40): Base declarative base, Global Tenant Rule, Organization model contract, OrganizationCreate schema, OrganizationMember model contract, OrganizationMemberRead schema, OrganizationRead schema, Permission model contract (+32 more)

### Community 2 - "Epic-1 RBAC Design Decisions"
Cohesion: 0.16
Nodes (25): D1 — Multi-tenancy: n:n instead of 1:1, D2 — Soft-delete as general strategy, D3 — Roles as permission sets (RBAC), not fixed enum, D7 — Authorization never cached in session, D8 — Audit fields based on editability, D9 — Social login as full auth method, permissions table, role_permissions table (+17 more)

### Community 3 - "Frontend tsconfig.app.json"
Cohesion: 0.09
Nodes (22): compilerOptions, allowImportingTsExtensions, jsx, lib, module, moduleDetection, moduleResolution, noEmit (+14 more)

### Community 4 - "Backend App Bootstrap & Config"
Cohesion: 0.13
Nodes (7): AsyncSession, do_run_migrations(), run_migrations_online(), get_settings(), Settings, get_db(), BaseSettings

### Community 5 - "Frontend package.json Dependencies"
Cohesion: 0.12
Nodes (16): dependencies, react, react-dom, react-router-dom, name, private, scripts, build (+8 more)

### Community 6 - "Frontend tsconfig.node.json"
Cohesion: 0.12
Nodes (16): compilerOptions, allowImportingTsExtensions, lib, module, moduleDetection, moduleResolution, noEmit, noUnusedLocals (+8 more)

### Community 7 - "Project READMEs & Docs Index"
Cohesion: 0.14
Nodes (16): D6 — Business behavior resolved in application, not DB, Decisiones de diseño — PM Tool Schema, Diccionario de datos — PM Tool Schema (31 tables), Separación de validaciones — DB vs aplicación, app/api/v1 (HTTP routers layer), app/repositories (data access layer), app/schemas (Pydantic layer), app/services (business logic layer) (+8 more)

### Community 8 - "Frontend devDependencies"
Cohesion: 0.15
Nodes (13): devDependencies, @types/node, @types/react, @types/react-dom, typescript, vite, @vitejs/plugin-react, @types/node (+5 more)

### Community 9 - "Backend Core Mixins (Audit/Timestamp/SoftDelete)"
Cohesion: 0.21
Nodes (9): AuditMixin, Mixins reusables para los modelos SQLAlchemy. Aplican el patrón de auditoría doc, created_at / updated_at estándar. No usar en tablas con nombres     distintos pa, deleted_at nullable — NULL significa fila activa. Todas las queries     de repos, created_by / updated_by — FK a users.id. Solo para entidades donde     más de un, SoftDeleteMixin, TimestampMixin, Mapped (+1 more)

### Community 10 - "Frontend App Shell & API Client"
Cohesion: 0.22
Nodes (3): apiClient, ApiError, HealthResponse

### Community 11 - "Scrum Format Guides & Templates"
Cohesion: 0.70
Nodes (5): Epic Format Guide, Epic Template, Scrum Documentation Templates README, User Story Format Guide, User Story Template (contract-only)

## Ambiguous Edges - Review These
- `Epic Format Guide` → `EPIC 1 — Foundation: Identity, Tenancy and RBAC`  [AMBIGUOUS]
  docs/scrum/EPIC-FORMAT-GUIDE.md · relation: references
- `User Story Format Guide` → `US-1.1 — Define Identity, Organization and RBAC Contracts`  [AMBIGUOUS]
  docs/scrum/US-FORMAT-GUIDE.md · relation: references

## Knowledge Gaps
- **77 isolated node(s):** `pm-tool-backend`, `name`, `private`, `version`, `type` (+72 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **9 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `Epic Format Guide` and `EPIC 1 — Foundation: Identity, Tenancy and RBAC`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._
- **What is the exact relationship between `User Story Format Guide` and `US-1.1 — Define Identity, Organization and RBAC Contracts`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._
- **Why does `EPIC 1 — Foundation: Identity, Tenancy and RBAC` connect `Epic-1 RBAC Design Decisions` to `PM Tool DB Schema & Data Dictionary`, `Scrum Format Guides & Templates`, `Project READMEs & Docs Index`?**
  _High betweenness centrality (0.046) - this node is a cross-community bridge._
- **Why does `app/models (SQLAlchemy ORM layer)` connect `PM Tool DB Schema & Data Dictionary` to `Epic-1 RBAC Design Decisions`, `Project READMEs & Docs Index`?**
  _High betweenness centrality (0.043) - this node is a cross-community bridge._
- **Why does `users table` connect `PM Tool DB Schema & Data Dictionary` to `RBAC & Auth Contracts (US-1.1/1.3-1.6)`, `Epic-1 RBAC Design Decisions`?**
  _High betweenness centrality (0.031) - this node is a cross-community bridge._
- **What connects `pm-tool-backend`, `name`, `private` to the rest of the system?**
  _77 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `PM Tool DB Schema & Data Dictionary` be split into smaller, more focused modules?**
  _Cohesion score 0.14634146341463414 - nodes in this community are weakly interconnected._