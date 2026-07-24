# Formato de Épica — Guía de estructura

Documenta el patrón estructural detectado en las épicas de este proyecto
(ej. la épica de Security Foundation), para poder reproducirlo de forma
consistente. Esto describe **forma**, no contenido — cada épica nueva
llena la plantilla (`epic-template.md`) con su propio dominio.

## Esqueleto de secciones (orden fijo)

1. **Description** — un único párrafo, historia de usuario clásica
   ("As a X, I want Y, so that Z"). Resume toda la épica en una oración.
2. **Objective** — prosa libre: qué construye la épica + qué NO construye
   (primera mención de exclusiones).
3. **Scope** — lista plana de bullets en gerundio ("Defining...",
   "Persisting...", "Implementing..."). Índice exhaustivo de alto nivel.
4. **Modelo de dominio** (ej. "Security Model", "Roles") — prosa
   explicativa + bullets de reglas de negocio fundamentales.
5. **Bloques repetidos "`<Subdominio> Responsibilities`"** — el patrón
   más distintivo. Uno por subdominio funcional. Molde interno fijo:
   frase de apertura → lista de reglas verificables → ejemplo inline
   opcional. Nunca mezclar dos subdominios en un mismo bloque.
6. **Out of Scope** — lista bulleted exhaustiva (segunda mención de
   exclusiones, ahora completa en vez de narrativa).
7. **Key User Stories** — resumen narrativo, una línea por historia,
   sin IDs. Versión legible para humanos.
8. **User Stories** — mismas historias, ahora solo como IDs formales
   (US-N.1...) + título corto, sin descripción inline. Desacoplada a
   propósito de la lista narrativa anterior.
9. **Implementation Order Note** (opcional) — solo si el orden numérico
   de las US no coincide con el orden real de ejecución. Declara el
   desvío explícitamente y explica por qué. Se omite si no aplica.
10. **Dependencies** — lista plana que mezcla dos tipos de dependencia
    sin necesidad de subtitularlos: épicas previas + prerrequisitos
    técnicos/infraestructura ya existentes.
11. **Definition of Done** — checklist atómico, un ítem verificable por
    línea, sin subtítulos, en el mismo orden que las secciones
    "Responsibilities". Cierra con una negación explícita de las
    exclusiones (tercera mención).

## Reglas estructurales clave

- **Redundancia intencional en 3 capas**: cada exclusión se dice tres
  veces en formatos distintos — prosa (Objective) → lista (Out of Scope)
  → checklist negado (cierre del DoD). Es trazabilidad por repetición,
  no descuido. No lo elimines al escribir una épica nueva.
- **Granularidad decreciente hacia abajo**: Scope (alto nivel) →
  Responsibilities (regla de negocio) → Definition of Done (criterio
  atómico). Cada capa reexpresa lo mismo con más detalle. Todo bullet
  de Scope debería poder rastrearse hasta al menos un ítem del DoD.
- **Narrativa separada de tracking**: "Key User Stories" (para leer) vs
  "User Stories" (para gestionar, con ID) son dos listas paralelas del
  mismo contenido — no fusionarlas.
- **Excepciones siempre explícitas**: si algo se desvía de la
  convención (ej. orden de ejecución ≠ orden numérico), se documenta
  con su propia sección en vez de dejarlo implícito.
- **Listas planas, sin anidamiento profundo**: todo bullet es de un
  solo nivel. Prioriza legibilidad línea por línea sobre jerarquía
  visual. El documento resultante es largo por diseño, no por exceso.
- **Sin metadata de planificación**: no incluye story points,
  estimaciones, asignados ni fechas — es un contrato funcional/de
  alcance, no una herramienta de planificación operativa. Esa
  información vive en el board (Jira/Linear/etc.), no en el documento.

## Cuándo usar este formato

Épicas grandes que:
- introducen un subsistema nuevo con varias entidades y reglas
  transversales (seguridad, tenancy, auditoría, etc.);
- necesitan trazabilidad clara entre alcance declarado y criterios de
  cierre verificables;
- van a ser implementadas por varias historias de usuario relacionadas
  que comparten el mismo dominio.

Para historias de usuario individuales o tareas chicas, este formato es
excesivo — usar una plantilla de US simple en su lugar.
