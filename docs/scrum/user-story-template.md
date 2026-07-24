# US-[N].[X] — [Título corto]

<!--
Plantilla para historias tipo "contract-only" (definición de contratos/
tipos fundacionales, sin comportamiento observable). Ver US-FORMAT-GUIDE.md
en esta misma carpeta para las reglas de cada sección.
Para historias de implementación (endpoints/flujos), conservar las
secciones de checklist y los bloques de regla con nombre, pero reemplazar
"Contracts" por el artefacto real (ver nota al final de la guía).
Borra todos los comentarios HTML antes de publicar la historia final.
-->

## Description

<!--
Igual fórmula que la épica ("As X, I want Y, so that Z") pero partida
en 3 líneas en vez de una sola oración.
-->

As [rol/sistema],

I want to [capacidad principal de esta historia],

so that [resultado que depende de esta historia].

## Scope

<!--
Prosa + lista plana de lo que la historia define.
Cierra SIEMPRE con:
  1. una frase que declara el tipo de historia (ej. "This story is
     contract-only.")
  2. la negación inline de lo que NO implementa (primera de 4 menciones
     del límite de alcance en todo el documento).
-->

This story defines [artefacto/dominio que cubre].

It must define:

[Entidad/Contrato 1]

[Entidad/Contrato 2]

[... una línea por entidad, mismo orden que "Contracts" más abajo]

This story is [contract-only / tipo de historia].

It does not implement [lista corta de exclusiones de esta historia puntual].

## Implementation Location

<!--
Ruta de archivo/módulo sugerida + regla de no-duplicación.
Omitir esta sección si la historia no introduce código con ubicación
física propia.
-->

Suggested location:

[ruta/al/modulo]

[Artefacto] must not be duplicated across [lista de módulos hermanos].

## [Nombre de la Regla Transversal 1, ej. "Core Principle"]

<!--
Bloque de "regla con nombre". Se enuncia UNA vez acá y se cita por
nombre en el resto del documento (o en otras historias) en vez de
repetirse. Usar para cualquier regla que:
  - aplique a más de una sección de este documento, o
  - vaya a ser reusada por historias hermanas de la misma épica.
-->

[Enunciado de la regla en 1-2 oraciones.]

[Implicación operativa directa de la regla.]

## [Nombre de la Regla Transversal 2, ej. "Global Tenant Rule"]

[Enunciado de la regla.]

This means:

- [Implicación 1.]
- [Implicación 2.]

Explicit exceptions ([razón general de por qué existen excepciones]):

- [Excepción 1] — [justificación puntual].
- [Excepción 2] — [justificación puntual].

[Frase de cierre acotando el alcance de esta regla, ej. "This rule exists independently of any specific epic's data model."]

---

<!--
==========================================================================
BLOQUE REPETIBLE: entidad/contrato individual
==========================================================================
Repetir este molde EXACTO por cada entidad listada en "Scope". No variar
el orden interno entre entidades — la rigidez es intencional para poder
escanear muchas entidades sin re-aprender el formato en cada una.
==========================================================================
-->

## Contracts

### [NombreEntidad]

[Una línea describiendo qué representa la entidad.]

Required fields:

- `campo1`
- `campo2`

Optional fields:

- `campoOpcional1`

Allowed `[campoEnum]` values:

- VALOR_A
- VALOR_B

[Reglas de negocio de esta entidad, una por línea.]

<!-- Ejemplo inline opcional, solo si una regla lo requiere -->
```json
{
  "campo1": "valor de ejemplo"
}
```

### [OtraEntidad]

[Repetir el molde anterior...]

---

## [Principio Operativo, ej. "Public Endpoint Principle"]

<!--
Mismo formato que un bloque de regla con nombre, pero enfocado a cómo se
usará este contrato más adelante (forward-reference a historias futuras).
Deja explícito qué NO resuelve todavía esta historia.
-->

This story does not implement [lo que queda para historias futuras].

Later stories must ensure that [expectativa que deben cumplir].

[Lista de casos/endpoints/flujos que sí y que no aplican, si corresponde.]

## Domain Rules

<!--
Lista plana que consolida las invariantes ya mencionadas arriba,
reexpresadas como reglas atómicas. Capa de redundancia deliberada.
Cierra reafirmando el límite de la historia (segunda mención).
-->

[Regla atómica 1, reexpresada de Contracts o de los bloques con nombre.]

[Regla atómica 2.]

[... ]

This story does not implement [repetir la negación de alcance].

## Acceptance Criteria

<!--
Checklist de nivel comportamiento. Mismo orden que "Contracts".
Cierra con la negación de alcance (tercera mención).
-->

[Entidad 1] contract is defined.

[Entidad 2] contract is defined.

[... una línea por entidad]

[Regla cruzada 1] is enforced by validation.

Contract validation exists for all defined contracts.

This story does not implement [repetir la negación de alcance].

## Validation Rules

<!--
Checklist de nivel esquema de campo. Mucho más granular que Acceptance
Criteria: una línea por campo/regla de validación, no por comportamiento.
-->

[Entidad1].[campo] is required.

[Entidad1].[campo] must be valid.

[Entidad1] must not include [campo prohibido].

[... una línea por campo relevante de cada entidad]

## Error Handling

<!--
Mismo molde que en la épica (prosa + lista de error.code +
ejemplo JSON), acotado a los errores de validación de ESTA historia.
-->

Invalid contracts must return deterministic validation errors, using the [ErrorResponse / forma de error del proyecto].

Possible error codes:

INVALID_[ENTIDAD1]_CONTRACT

INVALID_[ENTIDAD2]_CONTRACT

[...]

```json
{
  "error": {
    "code": "INVALID_[ENTIDAD1]_CONTRACT",
    "message": "[mensaje client-safe]",
    "details": {}
  }
}
```

## Tasks

<!--
Checklist imperativo de implementación, mismo orden que "Contracts".
Puente entre el contrato definido arriba y el trabajo de código real.
-->

Create [módulo] structure.

Define [Entidad1] contract.

Define [Entidad2] contract.

[...]

Implement contract validation.

Implement [regla cruzada] validation.

Implement deterministic validation errors.

Add unit tests for valid contracts.

Add unit tests for invalid contracts.

Document contracts under [ruta de docs].

## Tests

<!--
Checklist de casos de prueba en frases declarativas, pares
positivo/negativo por entidad. Cierra con aserciones de AUSENCIA de
efecto — la contraparte ejecutable de la negación de alcance.
-->

Valid [Entidad1] contract passes validation.

[Entidad1] with [campo inválido] fails validation.

Valid [Entidad2] contract passes validation.

[...]

Contract validation does not persist entities.

Contract validation does not call [módulo externo 1].

Contract validation does not call [módulo externo 2].

## Documentation Required

<!--
Correspondencia 1:1 con las entidades de "Contracts".
-->

Create or update:

[ruta/docs/entidad1.md]

[ruta/docs/entidad2.md]

[...]

## Dependencies

<!--
Mismo patrón que en la épica: historias/épicas previas + prerrequisitos
técnicos. Agregar nota de coordinación cruzada si otra épica/historia
debe mapear sus propios campos sobre una regla definida acá.
-->

Existing [módulo] structure.

[Herramienta/convención técnica prerrequisito].

[EPIC/US previa], which must map onto [regla definida en esta historia].

## Definition of Done

<!--
Checklist de cierre, más alto nivel que Acceptance Criteria/Validation
Rules/Tests (resume en líneas de grupo, no campo por campo).
Cierra con la negación explícita de alcance (cuarta y última mención).
-->

[Grupo de entidades 1] contracts are defined.

[Regla transversal 1] is defined.

Contract validation is implemented.

[Regla cruzada] validation is implemented.

Deterministic validation errors are implemented.

Required contract docs are updated.

Tests pass.

Backend checks pass.

No [repetir la lista completa de exclusiones de esta historia] is implemented.
