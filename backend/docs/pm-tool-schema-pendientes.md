# Pendientes y consideraciones — PM Tool Schema

Estado: 8 tablas modeladas — `users`, `organizations`, `organization_members`,
`projects`, `project_members`, `permissions`, `roles`, `role_permissions`.

Estos puntos no se pueden aplicar en dbdiagram.io por limitaciones del parser
(no soporta `CHECK`, índices parciales `WHERE`, ni triggers). Quedan para el
DDL final directo en Postgres.

## 1. Índices únicos parciales

dbdiagram no soporta la cláusula `where` en índices. En el DDL final hay que
recrear estos únicos como parciales, para permitir que un usuario reingrese
a una organización/proyecto tras un soft-delete previo:

```sql
CREATE UNIQUE INDEX organization_members_org_user_active_uk
  ON organization_members (organization_id, user_id)
  WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX project_members_project_user_active_uk
  ON project_members (project_id, user_id)
  WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX roles_scope_name_active_uk
  ON roles (scope_type, scope_id, name)
  WHERE deleted_at IS NULL AND is_system = false;

CREATE UNIQUE INDEX roles_system_name_active_uk
  ON roles (name)
  WHERE is_system = true AND deleted_at IS NULL;
```

## 2. CHECK constraint de consistencia en `roles`

Nada impide hoy una fila contradictoria (`is_system = true` con `scope_type`
seteado, o `is_system = false` sin scope). Agregar en el DDL final:

```sql
ALTER TABLE roles ADD CONSTRAINT roles_scope_consistency_chk
  CHECK (
    (is_system = true  AND scope_type IS NULL     AND scope_id IS NULL)
    OR
    (is_system = false AND scope_type IS NOT NULL AND scope_id IS NOT NULL)
  );
```

## 3. `roles.scope_id` — polimórfico sin FK real

`scope_type` indica `'organization'` o `'project'`, y `scope_id` apunta al id
correspondiente. Postgres no puede validar con una FK simple que ese id
exista o sea del tipo correcto — es el único punto del esquema sin
integridad referencial nativa. Queda 100% a cargo de la aplicación, o se
puede reforzar con un trigger de validación en el DDL final.

## 4. Validación cruzada `project_members` ↔ `organization_members`

Regla de negocio: un `project_member` debería ser también `organization_member`
activo de la organización dueña de ese proyecto. Ninguna FK simple expresa
esto porque involucra dos tablas distintas. Opciones para el DDL final:
un trigger `BEFORE INSERT/UPDATE` en `project_members`, o validación en la
capa de aplicación.

## 5. Decisiones de diseño ya resueltas (contexto, no pendientes)

- **Multi-tenancy**: relación n:n usuario↔organización vía `organization_members`
  (no 1:1 fijo).
- **Soft-delete** como estrategia general en todo el esquema, con `restrict`
  en las FKs como red de seguridad contra hard-deletes accidentales.
- **Roles como conjunto de permisos** (RBAC), no como enum fijo: roles base
  provistos por la app (`is_system = true`) + roles custom por organización,
  con permisos elegidos libremente (sin herencia).
- **Editar un rol de sistema** genera una versión custom (copy-on-write a
  nivel aplicación); no se traza de qué rol de sistema se originó.
- **Scope de roles**: polimórfico (`organization` o `project`), ver punto 3.
- **`left_at` vs `deleted_at`** en las tablas de membresía: `left_at` marca
  salida real del negocio; `deleted_at` queda para corrección/borrado por
  error — son conceptos distintos aunque ambos puedan estar seteados.

## 6. Cómo se asigna un rol a un usuario (referencia rápida)

No existe un rol directo en `users`. El rol vive en la fila de membresía:

```sql
-- Rol a nivel organización
INSERT INTO organization_members (id, organization_id, user_id, role_id, invited_by, joined_at)
VALUES (gen_random_uuid(), :organization_id, :user_id, :role_id, :invited_by_user_id, now());

-- Cambiar el rol de un miembro existente
UPDATE organization_members
SET role_id = :nuevo_role_id, updated_at = now()
WHERE organization_id = :organization_id AND user_id = :user_id AND deleted_at IS NULL;
```

Un usuario puede tener roles distintos en cada organización/proyecto al que
pertenece — no hay un rol "global" único por usuario.
