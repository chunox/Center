-- ============================================================
-- PM Tool — DDL final Postgres
-- 31 tablas. Generado a partir de pm-tool-schema.dbml
-- Incluye: CHECK constraints, índices únicos parciales y notas
-- de triggers pendientes que no se pudieron modelar en dbdiagram.io
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================
-- 1. CORE: usuarios, organizaciones, roles y permisos
-- ============================================================

CREATE TABLE users (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email               VARCHAR NOT NULL UNIQUE,
    password_hash       VARCHAR,
    first_name          VARCHAR NOT NULL,
    last_name           VARCHAR NOT NULL,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    email_verified_at   TIMESTAMP,
    last_login_at       TIMESTAMP,
    created_at          TIMESTAMP NOT NULL DEFAULT now(),
    updated_at          TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at          TIMESTAMP
);
COMMENT ON TABLE users IS 'password_hash nullable = login social permitido como único método de auth.';
-- PENDIENTE (trigger o validación de aplicación, no expresable en CHECK simple):
-- todo usuario debe tener password_hash NOT NULL O al menos una fila en user_identities.

CREATE TABLE organizations (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_by  UUID REFERENCES users(id) ON DELETE RESTRICT,
    name        VARCHAR NOT NULL,
    slug        VARCHAR NOT NULL UNIQUE,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP NOT NULL DEFAULT now(),
    updated_at  TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at  TIMESTAMP
);

CREATE TABLE permissions (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key         VARCHAR NOT NULL UNIQUE,
    description VARCHAR,
    created_at  TIMESTAMP NOT NULL DEFAULT now(),
    updated_at  TIMESTAMP NOT NULL DEFAULT now()
);
COMMENT ON TABLE permissions IS 'Catálogo fijo de permisos que provee la app, ej: work_items.create, work_items.delete, members.invite';

CREATE TABLE roles (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scope_type  VARCHAR,
    scope_id    UUID,
    created_by  UUID REFERENCES users(id) ON DELETE RESTRICT,
    name        VARCHAR NOT NULL,
    description VARCHAR,
    is_system   BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMP NOT NULL DEFAULT now(),
    updated_at  TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at  TIMESTAMP,
    CONSTRAINT roles_scope_consistency_chk CHECK (
        (is_system = TRUE  AND scope_type IS NULL     AND scope_id IS NULL)
        OR
        (is_system = FALSE AND scope_type IS NOT NULL AND scope_id IS NOT NULL)
    )
);
COMMENT ON TABLE roles IS 'scope_id polimórfico (organization o project según scope_type) sin FK real — validar a nivel aplicación o trigger.';
-- Únicos parciales (Postgres trata cada NULL como distinto, por eso se separan):
CREATE UNIQUE INDEX roles_custom_scope_name_uk ON roles (scope_type, scope_id, name)
    WHERE deleted_at IS NULL AND is_system = FALSE;
CREATE UNIQUE INDEX roles_system_name_uk ON roles (name)
    WHERE is_system = TRUE AND deleted_at IS NULL;

CREATE TABLE role_permissions (
    role_id       UUID NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE RESTRICT,
    granted_by    UUID REFERENCES users(id) ON DELETE RESTRICT,
    created_at    TIMESTAMP NOT NULL DEFAULT now(),
    PRIMARY KEY (role_id, permission_id)
);

-- ============================================================
-- 2. MULTI-TENANCY: organizaciones, proyectos y membresías
-- ============================================================

CREATE TABLE organization_members (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE RESTRICT,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    role_id         UUID NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
    invited_by      UUID REFERENCES users(id) ON DELETE RESTRICT,
    joined_at       TIMESTAMP NOT NULL DEFAULT now(),
    left_at         TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at      TIMESTAMP
);
COMMENT ON TABLE organization_members IS 'left_at = salida real del negocio. deleted_at = corrección/borrado por error.';
CREATE UNIQUE INDEX organization_members_active_uk ON organization_members (organization_id, user_id)
    WHERE deleted_at IS NULL;
CREATE INDEX organization_members_user_idx ON organization_members (user_id);

CREATE TABLE projects (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE RESTRICT,
    created_by      UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    name            VARCHAR NOT NULL,
    description     TEXT,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP NOT NULL DEFAULT now(),
    updated_at      TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at      TIMESTAMP
);

CREATE TABLE project_members (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id  UUID NOT NULL REFERENCES projects(id) ON DELETE RESTRICT,
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    role_id     UUID NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
    invited_by  UUID REFERENCES users(id) ON DELETE RESTRICT,
    joined_at   TIMESTAMP NOT NULL DEFAULT now(),
    left_at     TIMESTAMP,
    updated_at  TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at  TIMESTAMP
);
CREATE UNIQUE INDEX project_members_active_uk ON project_members (project_id, user_id)
    WHERE deleted_at IS NULL;
CREATE INDEX project_members_user_idx ON project_members (user_id);
-- PENDIENTE (trigger o validación de aplicación):
-- project_members.user_id debe ser también organization_member activo
-- de la organization_id dueña de este project.

-- ============================================================
-- 3. PREFERENCIAS Y CONFIGURACIÓN
-- ============================================================

CREATE TABLE user_preferences (
    id                            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                       UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE RESTRICT,
    language                      VARCHAR NOT NULL DEFAULT 'es',
    theme                         VARCHAR NOT NULL DEFAULT 'system',
    timezone                      VARCHAR NOT NULL DEFAULT 'UTC',
    date_format                   VARCHAR NOT NULL DEFAULT 'YYYY-MM-DD',
    email_notifications_enabled   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                    TIMESTAMP NOT NULL DEFAULT now(),
    updated_at                    TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE organization_settings (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL UNIQUE REFERENCES organizations(id) ON DELETE RESTRICT,
    default_language VARCHAR NOT NULL DEFAULT 'es',
    default_timezone VARCHAR NOT NULL DEFAULT 'UTC',
    plan            VARCHAR NOT NULL DEFAULT 'free',
    member_limit    INTEGER,
    billing_email   VARCHAR,
    updated_by      UUID REFERENCES users(id) ON DELETE RESTRICT,
    created_at      TIMESTAMP NOT NULL DEFAULT now(),
    updated_at      TIMESTAMP NOT NULL DEFAULT now(),
    CONSTRAINT organization_settings_member_limit_chk CHECK (member_limit IS NULL OR member_limit > 0)
);

CREATE TABLE project_settings (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id  UUID NOT NULL UNIQUE REFERENCES projects(id) ON DELETE RESTRICT,
    methodology VARCHAR NOT NULL DEFAULT 'free',
    is_public   BOOLEAN NOT NULL DEFAULT FALSE,
    updated_by  UUID REFERENCES users(id) ON DELETE RESTRICT,
    created_at  TIMESTAMP NOT NULL DEFAULT now(),
    updated_at  TIMESTAMP NOT NULL DEFAULT now()
);
COMMENT ON COLUMN project_settings.methodology IS 'free | scrum | feature_based. Comportamiento resuelto 100% a nivel aplicación.';

-- ============================================================
-- 4. AUTENTICACIÓN, SESIÓN, INVITACIONES, LOGIN SOCIAL
-- ============================================================

CREATE TABLE user_tokens (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    type        VARCHAR NOT NULL,
    token_hash  VARCHAR NOT NULL UNIQUE,
    expires_at  TIMESTAMP NOT NULL,
    used_at     TIMESTAMP,
    created_at  TIMESTAMP NOT NULL DEFAULT now(),
    CONSTRAINT user_tokens_type_chk CHECK (type IN ('password_reset', 'email_verification'))
);
CREATE INDEX user_tokens_user_idx ON user_tokens (user_id);
COMMENT ON COLUMN user_tokens.token_hash IS 'Nunca guardar el token en texto plano, solo su hash.';

CREATE TABLE invitations (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scope_type  VARCHAR NOT NULL,
    scope_id    UUID NOT NULL,
    email       VARCHAR NOT NULL,
    role_id     UUID NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
    invited_by  UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    status      VARCHAR NOT NULL DEFAULT 'pending',
    token_hash  VARCHAR NOT NULL UNIQUE,
    expires_at  TIMESTAMP NOT NULL,
    accepted_at TIMESTAMP,
    accepted_by UUID REFERENCES users(id) ON DELETE RESTRICT,
    created_at  TIMESTAMP NOT NULL DEFAULT now(),
    updated_at  TIMESTAMP NOT NULL DEFAULT now(),
    CONSTRAINT invitations_scope_type_chk CHECK (scope_type IN ('organization', 'project')),
    CONSTRAINT invitations_status_chk CHECK (status IN ('pending', 'accepted', 'expired', 'revoked'))
);
CREATE UNIQUE INDEX invitations_pending_uk ON invitations (scope_type, scope_id, email)
    WHERE status = 'pending';
COMMENT ON TABLE invitations IS 'Si scope_type=project y el invitado no es organization_member de la organización dueña, la app debe crear esa membership al aceptar.';
-- PENDIENTE (validación de aplicación): role_id debe coincidir en scope con la invitación.

CREATE TABLE sessions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    token_hash          VARCHAR NOT NULL UNIQUE,
    user_agent          VARCHAR,
    ip_address          VARCHAR,
    device_name         VARCHAR,
    last_activity_at    TIMESTAMP NOT NULL DEFAULT now(),
    expires_at          TIMESTAMP NOT NULL,
    revoked_at          TIMESTAMP,
    created_at          TIMESTAMP NOT NULL DEFAULT now()
);
CREATE INDEX sessions_user_idx ON sessions (user_id);
COMMENT ON TABLE sessions IS 'No cachea rol/permisos — autorización se resuelve en cada request. Límite de sesiones simultáneas y expulsión: lógica de aplicación.';

CREATE TABLE user_identities (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                 UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    provider                VARCHAR NOT NULL,
    provider_user_id        VARCHAR NOT NULL,
    email                   VARCHAR,
    access_token_encrypted  TEXT,
    refresh_token_encrypted TEXT,
    token_expires_at        TIMESTAMP,
    created_at              TIMESTAMP NOT NULL DEFAULT now(),
    updated_at              TIMESTAMP NOT NULL DEFAULT now(),
    UNIQUE (provider, provider_user_id)
);
CREATE INDEX user_identities_user_idx ON user_identities (user_id);
COMMENT ON COLUMN user_identities.access_token_encrypted IS 'Cifrado reversible (pgcrypto o cifrado en capa de aplicación), no hash — se necesita recuperar el valor original.';

-- ============================================================
-- 5. CONTENEDOR DE TIEMPO Y UNIDAD DE TRABAJO
-- ============================================================

CREATE TABLE iterations (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id  UUID NOT NULL REFERENCES projects(id) ON DELETE RESTRICT,
    created_by  UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    updated_by  UUID REFERENCES users(id) ON DELETE RESTRICT,
    name        VARCHAR NOT NULL,
    start_date  DATE,
    end_date    DATE,
    status      VARCHAR NOT NULL DEFAULT 'planned',
    goal        TEXT,
    created_at  TIMESTAMP NOT NULL DEFAULT now(),
    updated_at  TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at  TIMESTAMP
);
COMMENT ON TABLE iterations IS 'Contenedor de tiempo genérico: sprint (con fechas) o milestone (sin fechas).';
CREATE UNIQUE INDEX iterations_active_name_uk ON iterations (project_id, name)
    WHERE deleted_at IS NULL;

CREATE TABLE work_item_statuses (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id  UUID NOT NULL REFERENCES projects(id) ON DELETE RESTRICT,
    created_by  UUID REFERENCES users(id) ON DELETE RESTRICT,
    updated_by  UUID REFERENCES users(id) ON DELETE RESTRICT,
    name        VARCHAR NOT NULL,
    category    VARCHAR NOT NULL,
    position    INTEGER NOT NULL,
    is_default  BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMP NOT NULL DEFAULT now(),
    updated_at  TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at  TIMESTAMP,
    CONSTRAINT work_item_statuses_category_chk CHECK (category IN ('todo', 'in_progress', 'done'))
);
COMMENT ON TABLE work_item_statuses IS 'Columnas del tablero Kanban, configurables por proyecto.';
CREATE UNIQUE INDEX work_item_statuses_active_position_uk ON work_item_statuses (project_id, position)
    WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX work_item_statuses_active_name_uk ON work_item_statuses (project_id, name)
    WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX work_item_statuses_one_default_uk ON work_item_statuses (project_id)
    WHERE is_default = TRUE AND deleted_at IS NULL;

CREATE TABLE work_items (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id      UUID NOT NULL REFERENCES projects(id) ON DELETE RESTRICT,
    parent_id       UUID REFERENCES work_items(id) ON DELETE RESTRICT,
    iteration_id    UUID REFERENCES iterations(id) ON DELETE RESTRICT,
    status_id       UUID NOT NULL REFERENCES work_item_statuses(id) ON DELETE RESTRICT,
    created_by      UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    updated_by      UUID REFERENCES users(id) ON DELETE RESTRICT,
    type            VARCHAR NOT NULL,
    title           VARCHAR NOT NULL,
    description     TEXT,
    priority        VARCHAR,
    due_date        DATE,
    estimate        NUMERIC,
    position        INTEGER,
    created_at      TIMESTAMP NOT NULL DEFAULT now(),
    updated_at      TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at      TIMESTAMP
);
CREATE INDEX work_items_project_idx ON work_items (project_id);
CREATE INDEX work_items_parent_idx ON work_items (parent_id);
CREATE INDEX work_items_iteration_idx ON work_items (iteration_id);
COMMENT ON TABLE work_items IS 'parent_id arma la jerarquía (epic→story→task→subtask o feature→task→subtask) sin tabla por nivel.';
COMMENT ON COLUMN work_items.type IS 'epic | story | feature | task | subtask. Sin CHECK a propósito: extensible sin migración si se agregan nuevos tipos.';
-- PENDIENTE (validación de aplicación):
-- iteration_id y status_id deben pertenecer al mismo project_id que el work_item.
-- Reglas de jerarquía por type (ej. subtask no debería tener hijos).

CREATE TABLE work_item_assignees (
    work_item_id    UUID NOT NULL REFERENCES work_items(id) ON DELETE RESTRICT,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    assigned_by     UUID REFERENCES users(id) ON DELETE RESTRICT,
    assigned_at     TIMESTAMP NOT NULL DEFAULT now(),
    PRIMARY KEY (work_item_id, user_id)
);
CREATE INDEX work_item_assignees_user_idx ON work_item_assignees (user_id);

CREATE TABLE work_item_dependencies (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_work_item_id     UUID NOT NULL REFERENCES work_items(id) ON DELETE RESTRICT,
    target_work_item_id     UUID NOT NULL REFERENCES work_items(id) ON DELETE RESTRICT,
    type                    VARCHAR NOT NULL,
    created_by              UUID REFERENCES users(id) ON DELETE RESTRICT,
    created_at              TIMESTAMP NOT NULL DEFAULT now(),
    CONSTRAINT work_item_dependencies_no_self_chk CHECK (source_work_item_id != target_work_item_id),
    UNIQUE (source_work_item_id, target_work_item_id, type)
);
CREATE INDEX work_item_dependencies_source_idx ON work_item_dependencies (source_work_item_id);
CREATE INDEX work_item_dependencies_target_idx ON work_item_dependencies (target_work_item_id);
COMMENT ON TABLE work_item_dependencies IS 'blocks es direccional. relates_to/duplicates son simétricos — la app maneja filas espejo.';
COMMENT ON COLUMN work_item_dependencies.type IS 'blocks | relates_to | duplicates. Sin CHECK a propósito, mismo criterio que work_items.type.';

-- ============================================================
-- 6. CEREMONIAS
-- ============================================================

CREATE TABLE ceremonies (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id      UUID NOT NULL REFERENCES projects(id) ON DELETE RESTRICT,
    iteration_id    UUID REFERENCES iterations(id) ON DELETE RESTRICT,
    created_by      UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    updated_by      UUID REFERENCES users(id) ON DELETE RESTRICT,
    type            VARCHAR NOT NULL,
    name            VARCHAR,
    scheduled_at    TIMESTAMP NOT NULL,
    held_at         TIMESTAMP,
    status          VARCHAR NOT NULL DEFAULT 'scheduled',
    notes           TEXT,
    created_at      TIMESTAMP NOT NULL DEFAULT now(),
    updated_at      TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at      TIMESTAMP,
    CONSTRAINT ceremonies_status_chk CHECK (status IN ('scheduled', 'completed', 'cancelled'))
);
CREATE INDEX ceremonies_project_idx ON ceremonies (project_id);
CREATE INDEX ceremonies_iteration_idx ON ceremonies (iteration_id);
COMMENT ON COLUMN ceremonies.type IS 'daily | planning | refinement | retro | custom. Sin CHECK a propósito: permite ceremonias personalizadas sin migración.';

CREATE TABLE ceremony_participants (
    ceremony_id UUID NOT NULL REFERENCES ceremonies(id) ON DELETE RESTRICT,
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    attended    BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMP NOT NULL DEFAULT now(),
    PRIMARY KEY (ceremony_id, user_id)
);
CREATE INDEX ceremony_participants_user_idx ON ceremony_participants (user_id);

CREATE TABLE ceremony_work_items (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ceremony_id UUID NOT NULL REFERENCES ceremonies(id) ON DELETE RESTRICT,
    work_item_id UUID NOT NULL REFERENCES work_items(id) ON DELETE RESTRICT,
    created_by  UUID REFERENCES users(id) ON DELETE RESTRICT,
    flag        VARCHAR,
    note        TEXT,
    created_at  TIMESTAMP NOT NULL DEFAULT now(),
    updated_at  TIMESTAMP NOT NULL DEFAULT now()
);
CREATE INDEX ceremony_work_items_ceremony_idx ON ceremony_work_items (ceremony_id);
CREATE INDEX ceremony_work_items_work_item_idx ON ceremony_work_items (work_item_id);
COMMENT ON TABLE ceremony_work_items IS 'Permite múltiples filas por (ceremony_id, work_item_id) — bitácora, no estado único.';
-- PENDIENTE (validación de aplicación): work_item_id y ceremony_id deben compartir project_id.

-- ============================================================
-- 7. DOCUMENTACIÓN
-- ============================================================

CREATE TABLE documents (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id  UUID NOT NULL REFERENCES projects(id) ON DELETE RESTRICT,
    created_by  UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    updated_by  UUID REFERENCES users(id) ON DELETE RESTRICT,
    type        VARCHAR NOT NULL DEFAULT 'native',
    title       VARCHAR NOT NULL,
    content     TEXT,
    file_url    VARCHAR,
    file_name   VARCHAR,
    file_type   VARCHAR,
    file_size   BIGINT,
    created_at  TIMESTAMP NOT NULL DEFAULT now(),
    updated_at  TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at  TIMESTAMP,
    CONSTRAINT documents_type_chk CHECK (type IN ('native', 'file')),
    CONSTRAINT documents_content_xor_file_chk CHECK (
        (type = 'native' AND content IS NOT NULL AND file_url IS NULL)
        OR
        (type = 'file' AND file_url IS NOT NULL AND content IS NULL)
    )
);
CREATE INDEX documents_project_idx ON documents (project_id);

CREATE TABLE document_work_items (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id     UUID NOT NULL REFERENCES documents(id) ON DELETE RESTRICT,
    work_item_id     UUID NOT NULL REFERENCES work_items(id) ON DELETE RESTRICT,
    created_by       UUID REFERENCES users(id) ON DELETE RESTRICT,
    created_at       TIMESTAMP NOT NULL DEFAULT now(),
    UNIQUE (document_id, work_item_id)
);
CREATE INDEX document_work_items_document_idx ON document_work_items (document_id);
CREATE INDEX document_work_items_work_item_idx ON document_work_items (work_item_id);
-- PENDIENTE (validación de aplicación): document_id y work_item_id deben compartir project_id.

-- ============================================================
-- 8. MENSAJERÍA Y NOTIFICACIONES
-- ============================================================

CREATE TABLE conversations (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id  UUID NOT NULL REFERENCES projects(id) ON DELETE RESTRICT,
    work_item_id UUID REFERENCES work_items(id) ON DELETE RESTRICT,
    created_by  UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    updated_by  UUID REFERENCES users(id) ON DELETE RESTRICT,
    title       VARCHAR,
    created_at  TIMESTAMP NOT NULL DEFAULT now(),
    updated_at  TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at  TIMESTAMP
);
CREATE INDEX conversations_project_idx ON conversations (project_id);
CREATE INDEX conversations_work_item_idx ON conversations (work_item_id);
-- PENDIENTE (validación de aplicación): work_item_id debe pertenecer al mismo project_id.

CREATE TABLE conversation_participants (
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE RESTRICT,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    added_by        UUID REFERENCES users(id) ON DELETE RESTRICT,
    joined_at       TIMESTAMP NOT NULL DEFAULT now(),
    left_at         TIMESTAMP,
    last_read_at    TIMESTAMP,
    PRIMARY KEY (conversation_id, user_id)
);
CREATE INDEX conversation_participants_user_idx ON conversation_participants (user_id);

CREATE TABLE messages (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE RESTRICT,
    sender_id       UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    content         TEXT NOT NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT now(),
    updated_at      TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at      TIMESTAMP
);
CREATE INDEX messages_conversation_idx ON messages (conversation_id);

CREATE TABLE notifications (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    entity_type VARCHAR,
    entity_id   UUID,
    type        VARCHAR NOT NULL,
    title       VARCHAR NOT NULL,
    body        TEXT,
    read_at     TIMESTAMP,
    created_at  TIMESTAMP NOT NULL DEFAULT now()
);
CREATE INDEX notifications_user_idx ON notifications (user_id);
CREATE INDEX notifications_user_read_idx ON notifications (user_id, read_at);
CREATE INDEX notifications_entity_idx ON notifications (entity_type, entity_id);
COMMENT ON TABLE notifications IS 'entity_type/entity_id polimórfico sin FK real — validar a nivel aplicación.';

-- ============================================================
-- 9. COMENTARIOS Y ACTIVITY LOG
-- ============================================================

CREATE TABLE comments (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type VARCHAR NOT NULL,
    entity_id   UUID NOT NULL,
    author_id   UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    content     TEXT NOT NULL,
    created_at  TIMESTAMP NOT NULL DEFAULT now(),
    updated_at  TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at  TIMESTAMP
);
CREATE INDEX comments_entity_idx ON comments (entity_type, entity_id);
COMMENT ON TABLE comments IS 'entity_type/entity_id polimórfico. Estructura plana, sin respuestas anidadas.';

CREATE TABLE activity_log (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type VARCHAR NOT NULL,
    entity_id   UUID NOT NULL,
    actor_id    UUID REFERENCES users(id) ON DELETE RESTRICT,
    field_name  VARCHAR NOT NULL,
    old_value   VARCHAR,
    new_value   VARCHAR,
    created_at  TIMESTAMP NOT NULL DEFAULT now()
);
CREATE INDEX activity_log_entity_idx ON activity_log (entity_type, entity_id);
COMMENT ON TABLE activity_log IS 'Append-only: solo cambios clave de negocio (status, iteration, asignados). actor_id nullable para cambios automáticos del sistema.';

-- ============================================================
-- FIN DEL DDL
-- Triggers pendientes de implementar (no expresables en CHECK/FK):
--   1. users: al menos un método de auth activo (password_hash o user_identities)
--   2. project_members: user_id debe ser organization_member activo de la organización dueña
--   3. work_items: iteration_id/status_id deben compartir project_id con el work_item
--   4. ceremony_work_items: work_item_id y ceremony_id deben compartir project_id
--   5. document_work_items: document_id y work_item_id deben compartir project_id
--   6. conversations: work_item_id debe compartir project_id
--   7. invitations: role_id debe coincidir en scope con la invitación
--   8. work_items: reglas de jerarquía por type (ej. subtask sin hijos)
-- ============================================================
