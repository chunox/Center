# Decisiones de diseño — PM Tool Schema

Registro consolidado de las decisiones de arquitectura tomadas durante el
diseño del esquema, con el contexto y las alternativas consideradas.

---

## D1 — Multi-tenancy: n:n en vez de 1:1

**Decisión**: un usuario puede pertenecer a varias organizaciones, vía
tabla puente `organization_members`, en vez de una FK directa
`organization_id` en `users`.

**Por qué**: el caso de uso real (una persona trabajando para varios
clientes/organizaciones) no encaja con un modelo de un solo tenant por
usuario.

---

## D2 — Soft-delete como estrategia general

**Decisión**: prácticamente todas las entidades usan `deleted_at` en vez
de borrado físico, con `delete: restrict` en las FKs como red de
seguridad.

**Alternativas consideradas**: hard-delete con `cascade`.

**Por qué**: se prioriza auditoría e historial (poder reconstruir quién
hizo qué) sobre la simplicidad de queries. El trade-off aceptado es que
casi toda consulta necesita filtrar `WHERE deleted_at IS NULL`, y los
índices únicos necesitan ser parciales.

**Excepciones deliberadas**: `user_identities` (desconectar un proveedor
social no necesita historial) y las tablas puente sin contenido mutable
(`work_item_assignees`, `document_work_items`) no llevan `deleted_at`.

---

## D3 — Roles como conjunto de permisos, no como enum fijo

**Decisión**: `roles` + `permissions` + `role_permissions` (RBAC), con
roles base provistos por la app (`is_system = true`) y roles custom por
organización/proyecto con permisos elegidos libremente.

**Alternativas consideradas**: enum fijo de roles (Admin/Member/Viewer).

**Por qué**: el requisito explícito era permitir personalización completa
del conjunto de permisos por rol custom, sin herencia de un rol base —
edición de un rol de sistema genera una copia independiente
(copy-on-write a nivel aplicación), sin trazar de cuál se originó.

---

## D4 — Scope polimórfico para relaciones que aplican a más de un tipo de entidad

**Decisión**: cinco tablas (`roles`, `invitations`, `notifications`,
`comments`, `activity_log`) usan un par `scope_type`/`scope_id` (o
`entity_type`/`entity_id`) en vez de una FK real, para poder apuntar a
distintas tablas según el tipo.

**Alternativas consideradas**: una tabla separada por cada combinación
(ej. `organization_roles` y `project_roles` en vez de `roles` con scope).

**Trade-off aceptado**: se pierde integridad referencial nativa —
Postgres no puede validar que el id apuntado exista o sea del tipo
correcto. Esto se acepta conscientemente 5 veces en el esquema porque la
alternativa (una tabla por combinación) multiplicaría la cantidad de
tablas sin necesidad, dado que la mayoría de estas relaciones son
transversales por diseño (una notificación puede ser sobre cualquier
cosa).

---

## D5 — `work_items` auto-referenciada en vez de una tabla por nivel jerárquico

**Decisión**: una sola tabla `work_items` con `parent_id` (self-FK) y un
campo `type` (epic/story/feature/task/subtask) resuelve toda la
jerarquía, sin necesitar `epics`, `stories`, `tasks`, `subtasks` como
tablas separadas.

**Por qué**: la jerarquía varía según la metodología (Scrum usa
epic→story→task→subtask, feature-based usa feature→task→subtask, el modo
libre solo usa task→subtask) — modelarlo como tablas separadas hubiera
requerido lógica condicional a nivel de esquema. Con una sola tabla, el
comportamiento por metodología queda 100% en la aplicación.

---

## D6 — Comportamiento de negocio resuelto en la aplicación, no en la base de datos

**Decisión recurrente**: la metodología del proyecto
(`project_settings.methodology`), el comportamiento de cada tipo de
ceremonia, las reglas de jerarquía de `work_items`, y el bloqueo de
intentos fallidos de login, se resuelven todos a nivel aplicación.

**Por qué**: mantener el esquema flexible y evitar que la base de datos
imponga reglas de negocio que cambian según configuración — la DB modela
la forma de los datos, no el comportamiento condicional.

---

## D7 — Autorización nunca cacheada en la sesión

**Decisión**: `sessions` certifica identidad, no permisos. Cada request
resuelve autorización en tiempo real contra `roles`/`role_permissions`/
las tablas de membresía.

**Alternativas consideradas**: cachear el rol/permisos en el token o la
sesión al momento del login.

**Por qué**: si se cachearan permisos, un cambio de rol a mitad de sesión
dejaría a la persona operando con permisos viejos hasta renovar sesión —
hueco de seguridad. Como consecuencia positiva, remover a alguien de una
organización/proyecto no requiere invalidar sus sesiones activas: el
próximo request simplemente falla la autorización.

**Costo aceptado**: una consulta extra a la DB por request para validar
la sesión.

---

## D8 — Auditoría (`created_by`/`updated_by`) según quién puede editar

**Regla aplicada consistentemente**: toda entidad editable por más de una
persona lleva `created_by` y `updated_by`. Toda entidad que solo edita su
propio dueño (`user_preferences`, `sessions`, `messages`) NO lleva
`updated_by` — sería siempre igual al dueño, dato redundante.

**Por qué**: evitar tanto el hueco de auditoría (no saber quién cambió
algo compartido) como el ruido de un campo que nunca aporta información
nueva.

---

## D9 — Login social como método de autenticación completo

**Decisión**: `users.password_hash` es nullable — una persona puede
autenticarse únicamente vía proveedor social, sin nunca configurar
contraseña.

**Consecuencia**: existe una regla de negocio no expresable con
CHECK/FK simple — todo usuario debe tener `password_hash` seteado O al
menos una fila en `user_identities`. Queda documentada como validación
pendiente de aplicación.

**Tokens de proveedor**: se guardan cifrados de forma reversible (no
hasheados), porque se necesitan recuperar para llamar las APIs del
proveedor después del login — a diferencia de `password_hash`/
`token_hash`, que solo se verifican y nunca se recuperan.

---

## D10 — Metodología ágil sin imponer un flujo fijo

**Decisión**: `iterations` es un contenedor de tiempo genérico (sirve de
sprint o milestone según fechas presentes o no), y las ceremonias
(`ceremonies`) usan un `type` libre en vez de tablas separadas por tipo
de ceremonia.

**Por qué**: permitir que el equipo defina ceremonias personalizadas
además de las estándar de Scrum (daily, planning, refinement, retro) sin
requerir cambios de esquema.

---

## D11 — Separación entre conversación general y comentarios puntuales

**Decisión**: `conversations`/`messages` (chat de proyecto o de una
unidad de trabajo específica) es una entidad distinta de `comments`
(anotaciones puntuales sobre cualquier entidad).

**Por qué**: son patrones de uso distintos — una conversación es un flujo
continuo entre personas; un comentario es una anotación adjunta a algo
específico, sin la estructura de "ida y vuelta" de un chat.
