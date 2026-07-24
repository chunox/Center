# Formato de User Story — Guía de estructura

Documenta el patrón estructural detectado en las user stories "contract-only"
de este proyecto (ej. US-4.1 — Define Identity, Tenant and Security
Contracts), para reproducirlo de forma consistente. Describe **forma**, no
contenido. Es el nivel hijo de [EPIC-FORMAT-GUIDE.md](EPIC-FORMAT-GUIDE.md):
la épica define el dominio completo, cada US aterriza una porción con este
formato.

> Nota de alcance: el ejemplo analizado es específicamente una historia
> **de definición de contratos** (no implementa lógica, solo tipos y
> validación de forma). Historias de **implementación** (endpoints, flujos)
> probablemente necesiten variantes de este esqueleto — mismo espíritu,
> pero con secciones distintas donde hoy dice "Contracts". Ajustar sin
> perder los principios de abajo.

## Esqueleto de secciones (orden fijo)

1. **Description** — igual que en la épica pero partida en 3 líneas en vez
   de una sola oración: "As [rol/sistema]," / "I want [capacidad]," /
   "so that [resultado]." Misma fórmula, formato más espaciado.
2. **Scope** — prosa + lista plana de lo que la historia define. Cierra
   siempre con una frase explícita de tipo de historia (ej. "This story is
   contract-only.") seguida de la negación de lo que NO implementa. Esta
   negación aparece inline, no en sección aparte (a diferencia de la épica,
   que le da su propia sección "Out of Scope").
3. **Implementation Location** — sección nueva sin equivalente directo en
   la épica. Dos partes: (a) ruta de archivo/módulo sugerida, (b) regla de
   no-duplicación contra otros módulos. Úsala cuando la historia introduce
   código/contratos físicos con una ubicación concreta en el repo.
4. **Bloques de "regla con nombre"** (ej. "Core Principle", "Global Tenant
   Rule", "Password/Session/Invitation Token and Secret Rules") — el
   patrón más distintivo de este nivel. Cada uno:
   - Enuncia una regla transversal una sola vez, con nombre propio.
   - La desarrolla con sub-bullets ("This means:") y, si aplica,
     excepciones explícitas con su justificación individual.
   - Otras secciones del mismo documento (o de otras historias) la citan
     por nombre en vez de repetirla ("see Global Tenant Rule above",
     "reuse AuthorizationDecision.reasonCode rather than inventing an
     equivalent"). Esto evita reglas duplicadas/divergentes entre
     historias hermanas de la misma épica.
5. **Contracts** (o el nombre que corresponda al artefacto que define la
   historia) — el bloque repetible central, análogo a las secciones
   "Responsibilities" de la épica pero para definición de datos. Molde
   fijo por entidad:
   - Nombre de la entidad como subtítulo.
   - Una línea de descripción.
   - `Required fields:` (lista).
   - `Optional fields:` (lista, si aplica).
   - `Allowed <campo> values:` (enum cerrado, si aplica).
   - Reglas en prosa, una por línea.
   - Ejemplo JSON inline, solo si aclara algo no obvio.
   Repetir este molde exacto por cada entidad/contrato — no variar el
   orden interno entre entidades.
6. **Principios operativos** (ej. "Public Endpoint Principle") — igual
   forma que un bloque de regla con nombre, pero enfocado a cómo se
   usará el contrato más adelante (forward-reference a historias
   futuras). Deja explícito qué NO resuelve esta historia todavía.
7. **Domain Rules** — lista plana que consolida las invariantes ya
   mencionadas en "Contracts" y en los bloques con nombre, reexpresadas
   como reglas atómicas. Es una capa de redundancia deliberada (ver
   abajo). Cierra reafirmando el límite de la historia.
8. **Acceptance Criteria** — checklist de nivel *comportamiento*: qué debe
   ser cierto para considerar la historia lista, uno por línea, en el
   mismo orden que "Contracts". Termina con la negación de alcance otra
   vez.
9. **Validation Rules** — checklist de nivel *esquema de campo*, mucho más
   granular que Acceptance Criteria: `Entidad.campo is required`,
   `Entidad.campo must be valid`. Una línea por campo/regla de validación,
   no por comportamiento.
10. **Error Handling** — mismo molde que en la épica (prosa + lista de
    `error.code` en SCREAMING_SNAKE_CASE + ejemplo JSON), pero acotado a
    los errores de validación de contrato de esta historia en particular,
    no a los errores operacionales de toda la épica.
11. **Tasks** — checklist imperativo de implementación ("Define X
    contract.", "Implement Y validation.", "Add unit tests for..."), en
    el mismo orden que "Contracts". Es el puente entre el contrato
    definido arriba y el trabajo de código real.
12. **Tests** — checklist de casos de prueba en frases declarativas
    ("Valid X passes validation.", "X without Y fails validation."),
    exhaustivo, con pares positivo/negativo por entidad. Cierra con casos
    de **ausencia de efecto** (no persiste, no llama a otros módulos) —
    prueba explícitamente los límites declarados en Scope.
13. **Documentation Required** — lista de rutas de archivo de
    documentación a crear/actualizar, en correspondencia 1:1 con las
    entidades de "Contracts".
14. **Dependencies** — igual patrón que en la épica (historias/épicas
    previas + prerrequisitos técnicos), más una nota de coordinación
    cruzada si otra épica debe mapear sus propios campos sobre una regla
    definida acá.
15. **Definition of Done** — checklist de cierre, más alto nivel que
    Acceptance Criteria/Validation Rules/Tests (los resume en líneas de
    grupo, no campo por campo). Cierra, una vez más, con la negación
    explícita de alcance.

## Reglas estructurales clave

- **Cuatro capas de checklist, no una**: Acceptance Criteria (comportamiento)
  → Validation Rules (esquema/campo) → Tests (casos de prueba) →
  Definition of Done (cierre agrupado). Cada capa tiene una audiencia y
  granularidad distinta; no colapsarlas en una sola lista.
- **La negación de alcance se repite 4 veces**: Scope → Domain Rules →
  Acceptance Criteria → Definition of Done. Más redundante que la épica
  (3 capas) porque una historia "contract-only" necesita dejar clarísimo,
  en cada nivel de lectura, que no hay efectos secundarios (persistencia,
  endpoints, llamadas a otros módulos).
- **Reglas con nombre propio, citables por referencia**: a diferencia de
  la épica (que no nombra sus reglas), la US nombra bloques transversales
  ("Global Tenant Rule", "Core Principle") para que otras secciones —o
  historias hermanas— los citen sin duplicar el texto. Si una regla se va
  a repetir más de una vez dentro del documento o va a ser referenciada
  por otra historia, dale nombre propio y sección propia.
- **Molde de entidad rígido y mecánico**: a diferencia de los bloques
  "Responsibilities" de la épica (que varían en forma), cada entidad en
  "Contracts" sigue exactamente el mismo orden interno
  (descripción → required → optional → enums → reglas → ejemplo). Esta
  rigidez es intencional: permite escanear 15 entidades sin re-aprender
  el formato en cada una.
- **Tasks y Documentation Required son espejos de Contracts**: ambas
  listas siguen el mismo orden que la sección "Contracts", una línea por
  entidad. Si se agrega una entidad nueva, se agrega su línea en las
  cuatro secciones (Contracts, Tasks, Documentation Required, y el
  checklist de Tests) para no romper la correspondencia 1:1.
- **Tests prueba también lo que NO pasa**: además de casos positivos/
  negativos de validación, cierra con aserciones de ausencia de efecto
  ("Contract validation does not persist entities.", "...does not call
  Reasoning."). Es la contraparte ejecutable de la negación de alcance
  declarada en prosa.
- **Ubicación física explícita**: a diferencia de la épica (que no baja a
  nivel de archivo), la US sí declara dónde vive el código
  ("Implementation Location") y una regla anti-duplicación contra otros
  módulos del mismo repo.

## Cuándo usar este formato

Historias que:
- definen contratos/tipos de datos fundacionales que otras historias van
  a consumir (alta necesidad de precisión de esquema y cero ambigüedad);
- no implementan comportamiento observable todavía (contract-only,
  scaffolding, definición de interfaces);
- pertenecen a una épica grande donde varias historias hermanas van a
  reutilizar las mismas reglas con nombre (roles, tenant scope, formato
  de error).

Para historias que sí implementan comportamiento (endpoints, flujos de
negocio), reusar las secciones de checklist (Acceptance Criteria,
Validation Rules, Tests, DoD) y los bloques de regla con nombre, pero
reemplazar "Contracts" por la sección que corresponda al artefacto real
que se está construyendo (ej. "Endpoints", "Flows").
