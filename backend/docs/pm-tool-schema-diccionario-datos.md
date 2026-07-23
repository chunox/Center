# Diccionario de datos — PM Tool Schema

Referencia rápida de las 31 tablas del esquema. `PK` = clave primaria,
`FK` = clave foránea, `U` = único, `N` = nullable.

---

## users
| Columna | Tipo | N | Descripción |
|---|---|---|---|
| id | uuid | PK | Identificador |
| email | varchar | U | Email, único global |
| password_hash | varchar | N | Nullable: login social permite no tener password |
| first_name | varchar | | |
| last_name | varchar | | |
| is_active | boolean | | Default true |
| email_verified_at | timestamp | N | |
| last_login_at | timestamp | N | |
| created_at / updated_at / deleted_at | timestamp | N (deleted_at) | Auditoría estándar |

## organizations
| Columna | Tipo | N | Descripción |
|---|---|---|---|
| id | uuid | PK | |
| created_by | uuid | N, FK→users | |
| name | varchar | | |
| slug | varchar | U | Para URLs/subdominios |
| is_active | boolean | | |
| created_at / updated_at / deleted_at | timestamp | N (deleted_at) | |

## organization_members
| Columna | Tipo | N | Descripción |
|---|---|---|---|
| id | uuid | PK | |
| organization_id | uuid | FK→organizations | |
| user_id | uuid | FK→users | |
| role_id | uuid | FK→roles | |
| invited_by | uuid | N, FK→users | |
| joined_at | timestamp | | |
| left_at | timestamp | N | Salida real del negocio |
| updated_at / deleted_at | timestamp | N (deleted_at) | |

Índices: único parcial (organization_id, user_id) activos; (user_id).

## projects
| Columna | Tipo | N | Descripción |
|---|---|---|---|
| id | uuid | PK | |
| organization_id | uuid | FK→organizations | |
| created_by | uuid | FK→users | Not null |
| name | varchar | | |
| description | text | N | |
| is_active | boolean | | |
| created_at / updated_at / deleted_at | timestamp | N (deleted_at) | |

## project_members
Igual estructura que `organization_members`, referenciando `projects` en
vez de `organizations`.

## permissions
| Columna | Tipo | N | Descripción |
|---|---|---|---|
| id | uuid | PK | |
| key | varchar | U | Ej. "work_items.create" |
| description | varchar | N | |
| created_at / updated_at | timestamp | | |

## roles
| Columna | Tipo | N | Descripción |
|---|---|---|---|
| id | uuid | PK | |
| scope_type | varchar | N | organization \| project (NULL si is_system) |
| scope_id | uuid | N | Polimórfico, sin FK real |
| created_by | uuid | N, FK→users | NULL para roles de sistema |
| name | varchar | | |
| description | varchar | N | |
| is_system | boolean | | true = rol base de la app |
| created_at / updated_at / deleted_at | timestamp | N (deleted_at) | |

Índices: único parcial (scope_type, scope_id, name) para custom; único
parcial (name) para is_system.

## role_permissions
| Columna | Tipo | N | Descripción |
|---|---|---|---|
| role_id | uuid | PK, FK→roles | |
| permission_id | uuid | PK, FK→permissions | |
| granted_by | uuid | N, FK→users | |
| created_at | timestamp | | |

## user_preferences
| Columna | Tipo | N | Descripción |
|---|---|---|---|
| id | uuid | PK | |
| user_id | uuid | U, FK→users | 1:1 |
| language | varchar | | Default 'es' |
| theme | varchar | | Default 'system' |
| timezone | varchar | | Default 'UTC' |
| date_format | varchar | | Default 'YYYY-MM-DD' |
| email_notifications_enabled | boolean | | Default true |
| created_at / updated_at | timestamp | | Sin updated_by: solo el dueño edita |

## organization_settings
| Columna | Tipo | N | Descripción |
|---|---|---|---|
| id | uuid | PK | |
| organization_id | uuid | U, FK→organizations | 1:1 |
| default_language / default_timezone | varchar | | |
| plan | varchar | | Default 'free' |
| member_limit | integer | N | NULL = sin límite |
| billing_email | varchar | N | |
| updated_by | uuid | N, FK→users | |
| created_at / updated_at | timestamp | | |

## project_settings
| Columna | Tipo | N | Descripción |
|---|---|---|---|
| id | uuid | PK | |
| project_id | uuid | U, FK→projects | 1:1 |
| methodology | varchar | | free \| scrum \| feature_based |
| is_public | boolean | | |
| updated_by | uuid | N, FK→users | |
| created_at / updated_at | timestamp | | |

## user_tokens
| Columna | Tipo | N | Descripción |
|---|---|---|---|
| id | uuid | PK | |
| user_id | uuid | FK→users | |
| type | varchar | | password_reset \| email_verification |
| token_hash | varchar | U | Nunca el token en texto plano |
| expires_at | timestamp | | |
| used_at | timestamp | N | NULL = sin usar |
| created_at | timestamp | | |

## invitations
| Columna | Tipo | N | Descripción |
|---|---|---|---|
| id | uuid | PK | |
| scope_type | varchar | | organization \| project |
| scope_id | uuid | | Polimórfico, sin FK real |
| email | varchar | | Invitado puede no tener cuenta |
| role_id | uuid | FK→roles | Rol a asignar al aceptar |
| invited_by | uuid | FK→users | |
| status | varchar | | pending \| accepted \| expired \| revoked |
| token_hash | varchar | U | |
| expires_at | timestamp | | |
| accepted_at | timestamp | N | |
| accepted_by | uuid | N, FK→users | |
| created_at / updated_at | timestamp | | |

## sessions
| Columna | Tipo | N | Descripción |
|---|---|---|---|
| id | uuid | PK | |
| user_id | uuid | FK→users | |
| token_hash | varchar | U | |
| user_agent / ip_address / device_name | varchar | N | Identifican el dispositivo |
| last_activity_at | timestamp | | Actualizado con throttle a nivel app |
| expires_at | timestamp | | |
| revoked_at | timestamp | N | Cubre logout individual y global |
| created_at | timestamp | | |

## user_identities
| Columna | Tipo | N | Descripción |
|---|---|---|---|
| id | uuid | PK | |
| user_id | uuid | FK→users | |
| provider | varchar | | google \| github \| microsoft |
| provider_user_id | varchar | | Único junto con provider |
| email | varchar | N | Email devuelto por el proveedor |
| access_token_encrypted / refresh_token_encrypted | text | N | Cifrado reversible, no hash |
| token_expires_at | timestamp | N | |
| created_at / updated_at | timestamp | | |

## iterations
| Columna | Tipo | N | Descripción |
|---|---|---|---|
| id | uuid | PK | |
| project_id | uuid | FK→projects | |
| created_by | uuid | FK→users | Not null |
| updated_by | uuid | N, FK→users | |
| name | varchar | | Único por proyecto (activos) |
| start_date / end_date | date | N | NULL = milestone sin fecha |
| status | varchar | | planned \| active \| completed |
| goal | text | N | |
| created_at / updated_at / deleted_at | timestamp | N (deleted_at) | |

## work_item_statuses
| Columna | Tipo | N | Descripción |
|---|---|---|---|
| id | uuid | PK | |
| project_id | uuid | FK→projects | |
| created_by | uuid | N, FK→users | NULL si auto-generado |
| updated_by | uuid | N, FK→users | |
| name | varchar | | Nombre custom de la columna |
| category | varchar | | todo \| in_progress \| done (fijo) |
| position | integer | | Orden en el tablero |
| is_default | boolean | | Único activo=true por proyecto |
| created_at / updated_at / deleted_at | timestamp | N (deleted_at) | |

## work_items
| Columna | Tipo | N | Descripción |
|---|---|---|---|
| id | uuid | PK | |
| project_id | uuid | FK→projects | |
| parent_id | uuid | N, FK→work_items | Self-FK, arma la jerarquía |
| iteration_id | uuid | N, FK→iterations | Cualquier nivel puede asignarse |
| status_id | uuid | FK→work_item_statuses | |
| created_by | uuid | FK→users | Not null |
| updated_by | uuid | N, FK→users | |
| type | varchar | | epic \| story \| feature \| task \| subtask |
| title | varchar | | |
| description | text | N | |
| priority | varchar | N | Libre, ej. low/medium/high/urgent |
| due_date | date | N | Propio, distinto de las fechas del iteration |
| estimate | numeric | N | Story points u horas, según la app |
| position | integer | N | Orden manual en el tablero |
| created_at / updated_at / deleted_at | timestamp | N (deleted_at) | |

## work_item_assignees
| Columna | Tipo | N | Descripción |
|---|---|---|---|
| work_item_id | uuid | PK, FK→work_items | |
| user_id | uuid | PK, FK→users | |
| assigned_by | uuid | N, FK→users | NULL si auto-asignación |
| assigned_at | timestamp | | |

## work_item_dependencies
| Columna | Tipo | N | Descripción |
|---|---|---|---|
| id | uuid | PK | |
| source_work_item_id | uuid | FK→work_items | El que bloquea/relaciona |
| target_work_item_id | uuid | FK→work_items | El bloqueado/relacionado |
| type | varchar | | blocks \| relates_to \| duplicates |
| created_by | uuid | N, FK→users | |
| created_at | timestamp | | |

## ceremonies
| Columna | Tipo | N | Descripción |
|---|---|---|---|
| id | uuid | PK | |
| project_id | uuid | FK→projects | |
| iteration_id | uuid | N, FK→iterations | Puede ser ad-hoc |
| created_by | uuid | FK→users | Not null |
| updated_by | uuid | N, FK→users | |
| type | varchar | | daily \| planning \| refinement \| retro \| custom |
| name | varchar | N | Solo relevante si type=custom |
| scheduled_at | timestamp | | |
| held_at | timestamp | N | Cuándo ocurrió realmente |
| status | varchar | | scheduled \| completed \| cancelled |
| notes | text | N | |
| created_at / updated_at / deleted_at | timestamp | N (deleted_at) | |

## ceremony_participants
| Columna | Tipo | N | Descripción |
|---|---|---|---|
| ceremony_id | uuid | PK, FK→ceremonies | |
| user_id | uuid | PK, FK→users | |
| attended | boolean | | |
| created_at | timestamp | | |

## ceremony_work_items
| Columna | Tipo | N | Descripción |
|---|---|---|---|
| id | uuid | PK | |
| ceremony_id | uuid | FK→ceremonies | |
| work_item_id | uuid | FK→work_items | |
| created_by | uuid | N, FK→users | |
| flag | varchar | N | blocked \| discussed \| at_risk \| completed |
| note | text | N | |
| created_at / updated_at | timestamp | | Permite múltiples filas por combinación |

## documents
| Columna | Tipo | N | Descripción |
|---|---|---|---|
| id | uuid | PK | |
| project_id | uuid | FK→projects | |
| created_by | uuid | FK→users | Not null |
| updated_by | uuid | N, FK→users | |
| type | varchar | | native \| file |
| title | varchar | | |
| content | text | N | Solo si type=native |
| file_url | varchar | N | Solo si type=file |
| file_name | varchar | N | Nombre original del archivo |
| file_type | varchar | N | Mimetype/extensión |
| file_size | bigint | N | Bytes |
| created_at / updated_at / deleted_at | timestamp | N (deleted_at) | Sin versionado |

## document_work_items
| Columna | Tipo | N | Descripción |
|---|---|---|---|
| id | uuid | PK | |
| document_id | uuid | FK→documents | |
| work_item_id | uuid | FK→work_items | Único junto con document_id |
| created_by | uuid | N, FK→users | |
| created_at | timestamp | | |

## conversations
| Columna | Tipo | N | Descripción |
|---|---|---|---|
| id | uuid | PK | |
| project_id | uuid | FK→projects | |
| work_item_id | uuid | N, FK→work_items | NULL = conversación general del proyecto |
| created_by | uuid | FK→users | Not null |
| updated_by | uuid | N, FK→users | Cualquier participante puede renombrar |
| title | varchar | N | |
| created_at / updated_at / deleted_at | timestamp | N (deleted_at) | |

## conversation_participants
| Columna | Tipo | N | Descripción |
|---|---|---|---|
| conversation_id | uuid | PK, FK→conversations | |
| user_id | uuid | PK, FK→users | |
| added_by | uuid | N, FK→users | |
| joined_at | timestamp | | |
| left_at | timestamp | N | |
| last_read_at | timestamp | N | Para badge de no leídos |

## messages
| Columna | Tipo | N | Descripción |
|---|---|---|---|
| id | uuid | PK | |
| conversation_id | uuid | FK→conversations | |
| sender_id | uuid | FK→users | |
| content | text | | |
| created_at / updated_at / deleted_at | timestamp | N (deleted_at) | Sin updated_by: solo el autor edita |

## notifications
| Columna | Tipo | N | Descripción |
|---|---|---|---|
| id | uuid | PK | |
| user_id | uuid | FK→users | Destinatario (siempre 1) |
| entity_type | varchar | N | Polimórfico, sin FK real |
| entity_id | uuid | N | |
| type | varchar | | mention \| assignment \| ceremony_reminder \| new_message... |
| title | varchar | | |
| body | text | N | |
| read_at | timestamp | N | NULL = no leída |
| created_at | timestamp | | |

## comments
| Columna | Tipo | N | Descripción |
|---|---|---|---|
| id | uuid | PK | |
| entity_type | varchar | | Polimórfico, sin FK real |
| entity_id | uuid | | work_item \| ceremony \| document |
| author_id | uuid | FK→users | |
| content | text | | |
| created_at / updated_at / deleted_at | timestamp | N (deleted_at) | Plano, sin respuestas anidadas |

## activity_log
| Columna | Tipo | N | Descripción |
|---|---|---|---|
| id | uuid | PK | |
| entity_type | varchar | | Polimórfico, sin FK real |
| entity_id | uuid | | |
| actor_id | uuid | N, FK→users | NULL = cambio automático del sistema |
| field_name | varchar | | status \| iteration \| assignee (solo cambios clave) |
| old_value / new_value | varchar | N | Genérico, interpretado por la app |
| created_at | timestamp | | Append-only, sin updated_at/deleted_at |

---

## Convenciones generales del esquema

- Todas las PK son `uuid` con `gen_random_uuid()` como default.
- Timestamps de auditoría estándar: `created_at`/`updated_at` casi
  siempre presentes; `deleted_at` en entidades con historial de negocio;
  ausente en tablas puente sin contenido mutable.
- `created_by`/`updated_by` presentes cuando la entidad puede ser editada
  por más de una persona; ausentes cuando solo el dueño la edita.
- Todos los FKs usan `ON DELETE RESTRICT`.
- Campos de tipo/estado (`type`, `status`, `category`, `flag`, `plan`,
  `methodology`, `provider`) son `varchar`, con los valores esperados
  documentados en cada tabla. La mayoría lleva `CHECK` en el DDL final
  (ver `pm-tool-schema.sql`). Excepción deliberada: `work_items.type`,
  `ceremonies.type` y `work_item_dependencies.type` quedan sin `CHECK`
  a propósito, para poder agregar nuevos valores (una nueva metodología,
  un nuevo tipo de ceremonia custom) sin requerir una migración.
