# EPIC [N] — [Nombre de la Épica]

<!--
Plantilla estructural. Ver FORMAT-GUIDE.md en esta misma carpeta para las
reglas de cada sección (qué va, qué nivel de detalle, qué NO repetir de más).
Borra todos los comentarios HTML antes de publicar la épica final.
-->

## Description

<!--
Un único párrafo, formato historia de usuario clásica:
"As a [rol], I want [sistema] to [capacidad principal, lista de verbos],
so that [resultado / propiedad garantizada]."
No es una lista. Es la frase que resume TODA la épica en una oración.
-->

As a [rol], I want [sistema] to [verbo1], [verbo2], [verbo3], so that [resultado final].

## Objective

<!--
Prosa libre, 2-4 párrafos:
1. Qué construye esta épica (el "para qué" en términos de sistema).
2. Qué NO construye — primera mención de las exclusiones (ver Out of Scope).
3. Cualquier restricción externa que condiciona todo el diseño
   (ej: "los secretos los provee infraestructura, no se persisten").
-->

Build the [nombre del sistema/fundación] of [producto].

This epic establishes [lista de fundamentos/capacidades] required before [producto] can safely [siguiente hito].

This epic does not implement [lista corta de exclusiones mayores].

[Restricción externa relevante, si aplica.]

## Scope

<!--
Lista plana de bullets. Cada uno arranca con gerundio:
"Defining...", "Persisting...", "Implementing...", "Enforcing...", "Supporting...".
Es el índice exhaustivo de TODO lo que toca la épica, sin agrupar por historia.
Este nivel es el más alto de granularidad entre Scope → Responsibilities → DoD.
-->

The scope for this epic includes:

Defining [contratos/entidades principales].

Persisting [entidades] in the real database.

Implementing [flujo 1].

Implementing [flujo 2].

Enforcing [regla transversal].

[... continuar con un bullet por capacidad, en el orden en que se explican
después en las secciones "Responsibilities"]

## [Nombre del Modelo de Dominio, ej: "Security Model", "Domain Model"]

<!--
Opcional pero recomendado si la épica introduce entidades o conceptos nuevos.
Mezcla de prosa explicativa + bullets de reglas de negocio.
Explica las relaciones entre entidades ANTES de listar las reglas
operativas (que van en las secciones "Responsibilities").
-->

[Sistema] uses a [tipo de modelo] model.

[Entidad principal] is [rol conceptual].

[Regla de negocio fundamental, ej. cardinalidad, invariantes].

## Roles / Actores

<!--
Si aplica: enumerar roles/actores y sus reglas de alcance.
Formato: lista de roles → luego reglas de qué puede/no puede hacer cada uno.
-->

[Sistema] supports [N] roles:

- ROLE_A
- ROLE_B
- ROLE_C

Role scope:

- ROLE_A is [alcance]-scoped.
- ROLE_B is [alcance]-scoped.

Role rules:

- ROLE_A may [acción].
- ROLE_A may not [restricción].

---

<!--
==========================================================================
BLOQUE REPETIBLE: "<Dominio> Responsibilities"
==========================================================================
Este es el patrón central del documento. Repetir una sección de este tipo
por cada subdominio funcional de la épica (ej: Session, Public Endpoint,
Tenant Isolation, Invitation, Security Audit, Rate Limiting, Error Handling).

Cada bloque sigue el mismo molde interno:
  1. Frase de apertura que ubica el subdominio dentro de la épica.
  2. Lista de reglas de negocio específicas y verificables.
  3. (Opcional) Un ejemplo inline — código, JSON, payload — SOLO si aclara
     una regla no obvia.
  4. Nunca mezclar responsabilidades de dos subdominios en un mismo bloque.

Duplica esta sección tantas veces como subdominios tenga la épica.
==========================================================================
-->

## [Subdominio] Responsibilities

[Frase de apertura ubicando el subdominio.]

[Regla de negocio 1, oración corta y verificable.]

[Regla de negocio 2.]

[Regla de negocio 3.]

<!-- Ejemplo inline opcional, solo si una regla lo requiere -->
```
{
  "campo": "valor de ejemplo"
}
```

## [Otro Subdominio] Responsibilities

[Repetir el molde anterior...]

---

## Out of Scope

<!--
Lista bulleted exhaustiva. Segunda mención de las exclusiones
(la primera fue narrativa, en Objective; esta es completa y plana).
Un ítem por línea, sin agrupar.
-->

The following are out of scope for this epic:

- [Exclusión 1].
- [Exclusión 2].
- [... listar TODO lo que se mencionó en Objective y cualquier exclusión
  adicional relevante]

## Key User Stories

<!--
Resumen narrativo, una línea por historia, SIN IDs.
Es la versión legible-para-humanos. Los IDs formales van en la
siguiente sección, desacoplados a propósito.
-->

- [Verbo] [objeto de la historia 1].
- [Verbo] [objeto de la historia 2].
- [... una línea por historia, mismo orden que la sección siguiente]

## User Stories

<!--
Mismas historias que arriba, ahora SOLO como IDs formales + título corto,
sin descripción inline. Esto es lo que se trackea en el board.
-->

US-[N].1 — [Título corto]

US-[N].2 — [Título corto]

US-[N].3 — [Título corto]

<!-- ... -->

## Implementation Order Note

<!--
Sección de EXCEPCIÓN, no obligatoria. Incluir SOLO si el orden numérico
de las user stories no coincide con el orden real de ejecución.
Declarar explícitamente el desvío y la razón — nunca dejarlo implícito.
Borrar esta sección entera si el orden de ejecución = orden numérico.
-->

Although the numbering keeps US-[N].[X] as [rol], implementation should execute US-[N].[Y] before US-[N].[X].

US-[N].[X] is [razón por la que va al final, ej: la historia de hardening/validación].

Therefore, [dependencia funcional que obliga el reordenamiento].

## Dependencies

<!--
Lista plana, pero mentalmente separada en dos tipos (no hace falta
subtitularlos, solo no mezclar el orden sin criterio):
1. Épicas previas de las que depende esta.
2. Prerrequisitos técnicos/infraestructura ya existentes en el repo.
-->

EPIC [X] — [Nombre]

EPIC [Y] — [Nombre]

Existing [módulo/infra] setup

[Herramienta/convención técnica prerrequisito]

## Definition of Done

<!--
Checklist atómico. Un ítem verificable por línea, SIN subtítulos.
Orden: sigue aproximadamente el mismo orden que las secciones
"Responsibilities" de arriba (contratos → persistencia → flujos →
reglas transversales → endpoints → auditoría/errores → docs → tests).
Cada bullet de "Scope" y cada regla de "Responsibilities" debería
poder mapearse a al menos un ítem de este checklist (trazabilidad
Scope → Responsibilities → DoD).

Cerrar SIEMPRE con una negación explícita de las exclusiones
(tercera mención — la primera fue en Objective, la segunda en
Out of Scope, esta es el criterio de cierre negado).
-->

This epic is complete when:

[Contrato 1] is defined.

[Entidad 1] persistence is implemented.

[Flujo 1] is implemented.

[Regla transversal 1] is enforced.

[Endpoint 1] is implemented.

[Evento de auditoría 1] is emitted.

[Error de seguridad 1] is hardened.

OpenAPI / Swagger includes implemented public endpoints.

Required contracts are documented under docs/contracts/[dominio].

[Flujos principales] are covered by tests.

Backend checks pass.

No [lista de exclusiones mayores, calcada de Out of Scope] is implemented in this epic.
