# Separación de validaciones — DB vs. aplicación

Qué garantiza la base de datos por sí sola, y qué debe validar
obligatoriamente la capa de aplicación (o un trigger, si se prefiere
forzarlo a nivel DB). Ver `pm-tool-schema.sql` para el DDL completo con
estos constraints ya aplicados donde corresponde.

## Garantizado a nivel base de datos

| Constraint | Tablas |
|---|---|
| Integridad referencial (FK + `ON DELETE RESTRICT`) | Todas las relaciones con FK real (la gran mayoría del esquema) |
| Unicidad simple (email, slug, token_hash, etc.) | `users.email`, `organizations.slug`, `user_tokens.token_hash`, `sessions.token_hash`, `invitations.token_hash` |
| Unicidad compuesta 1:1 (`UNIQUE` en la FK) | `user_preferences.user_id`, `organization_settings.organization_id`, `project_settings.project_id` |
| Unicidad compuesta parcial (activos únicamente) | `organization_members`/`project_members` (org/project + user, `WHERE deleted_at IS NULL`), `iterations` (proyecto + nombre), `work_item_statuses` (proyecto + posición, proyecto + nombre, un solo default) |
| CHECK de valores fijos | `roles.is_system` vs `scope_type`/`scope_id`; `user_tokens.type`; `invitations.scope_type`/`status`; `work_item_statuses.category`; `ceremonies.status`; `documents.type` |
| CHECK de rango | `organization_settings.member_limit` (NULL o positivo) |
| CHECK de exclusión mutua | `documents` (`content` XOR `file_url` según `type`) |
| CHECK anti auto-referencia | `work_item_dependencies` (`source != target`) |
| PK compuesta (evita duplicados exactos) | `role_permissions`, `work_item_assignees`, `ceremony_participants`, `conversation_participants` |

## NO garantizado a nivel DB — requiere validación de aplicación (o trigger)

Estas reglas cruzan tablas de forma que ninguna FK o CHECK simple puede
expresar. Se agrupan por tipo de regla:

### A. Scope polimórfico sin FK real

Cinco tablas apuntan a una entidad "de tipo variable" sin que Postgres
pueda validar que el id referenciado exista o sea del tipo correcto:

| Tabla | Columnas | Valores esperados de `type` |
|---|---|---|
| `roles` | `scope_type`/`scope_id` | organization, project |
| `invitations` | `scope_type`/`scope_id` | organization, project |
| `notifications` | `entity_type`/`entity_id` | message, work_item, ceremony, invitation, document |
| `comments` | `entity_type`/`entity_id` | work_item, ceremony, document |
| `activity_log` | `entity_type`/`entity_id` | work_item, ceremony, document |

**Mitigación posible**: un trigger `BEFORE INSERT/UPDATE` que, según el
valor de `*_type`, verifique contra la tabla correspondiente que el id
exista. Se documenta como opción, no se implementó en el DDL por el costo
de mantenimiento (cada trigger debe actualizarse si se agrega un nuevo
`type` posible).

### B. Consistencia de `project_id` entre entidades relacionadas

Ninguna FK simple garantiza que dos columnas que referencian distintas
tablas, pero que conceptualmente deben pertenecer al mismo proyecto,
efectivamente lo hagan:

| Regla | Tablas involucradas |
|---|---|
| `work_items.iteration_id` y `work_items.status_id` deben pertenecer al mismo `project_id` que el `work_item` | `work_items`, `iterations`, `work_item_statuses` |
| `ceremony_work_items.work_item_id` debe pertenecer al mismo proyecto que `ceremony_work_items.ceremony_id` | `ceremony_work_items`, `work_items`, `ceremonies` |
| `document_work_items.work_item_id` debe pertenecer al mismo proyecto que `document_work_items.document_id` | `document_work_items`, `work_items`, `documents` |
| `conversations.work_item_id` debe pertenecer al mismo proyecto que `conversations.project_id` | `conversations`, `work_items` |

**Mitigación posible**: trigger que haga un `SELECT` cruzado antes de
insertar/actualizar, o resolverlo en la capa de servicio antes de
persistir.

### C. Reglas de negocio sin representación estructural

| Regla | Detalle |
|---|---|
| Todo usuario necesita al menos un método de autenticación activo | `users.password_hash` NOT NULL O al menos una fila en `user_identities` para ese `user_id` |
| `project_members.user_id` debe ser `organization_member` activo de la organización dueña del proyecto | Si se invita directo a un proyecto y la persona no es miembro de la organización, la app debe crear ambas membresías al aceptar |
| `invitations.role_id` debe coincidir en scope con la invitación | El rol asignado debe tener el mismo `scope_type`/`scope_id` que la invitación, o la asignación queda inconsistente |
| Reglas de jerarquía en `work_items` por `type` | Ej. una `subtask` no debería tener `parent_id` apuntando a otra `subtask`; un `epic` no debería tener `parent_id` seteado. Varía según `project_settings.methodology` |
| Relaciones simétricas duplicadas en `work_item_dependencies` | `relates_to`/`duplicates` son conceptualmente simétricos — nada impide insertar tanto `A relates_to B` como `B relates_to A` como filas separadas para la misma relación |
| Límite de sesiones simultáneas y expulsión de la más antigua | `sessions` no tiene ningún límite a nivel DB — la app decide cuántas permitir y cuándo expulsar |
| Auto-generación de columnas default del tablero Kanban | `work_item_statuses.is_default` no se auto-crea al crear un proyecto — es responsabilidad de la app hacerlo con `created_by = NULL` |

## Resumen para el equipo de backend

Al implementar cada operación de escritura (crear, actualizar, invitar,
aceptar, mover un work item de sprint, etc.), revisar contra la tabla de
la sección "NO garantizado" si esa operación toca alguna de estas reglas
cruzadas. Ninguna de ellas está cubierta por un rollback automático de la
base de datos — un error ahí produce datos inconsistentes silenciosos,
no un error de constraint visible.
