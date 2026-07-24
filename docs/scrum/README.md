# Plantillas de documentación Scrum

Formatos estructurales reutilizables para épicas y user stories de este
proyecto. Documentan **forma**, no contenido — cada épica/historia nueva
llena la plantilla correspondiente con su propio dominio.

## Jerarquía

- **Épica** — define un dominio completo (ej. Security Foundation): qué
  problema resuelve, sus subdominios funcionales, y el checklist de cierre
  de todo el conjunto.
  - [EPIC-FORMAT-GUIDE.md](EPIC-FORMAT-GUIDE.md) — reglas del formato.
  - [epic-template.md](epic-template.md) — plantilla rellenable.
- **User Story** — aterriza una porción de la épica (ej. definir los
  contratos base). Formato hijo del de la épica: mismos principios de
  redundancia trazable, con más capas de checklist.
  - [US-FORMAT-GUIDE.md](US-FORMAT-GUIDE.md) — reglas del formato.
  - [user-story-template.md](user-story-template.md) — plantilla
    rellenable (variante "contract-only"; ver nota al final de la guía
    para historias de implementación).

## Cómo usar

1. Copiar la plantilla correspondiente.
2. Rellenar siguiendo los comentarios `<!-- -->` de cada sección.
3. Borrar los comentarios antes de publicar la versión final.
4. Ante la duda de qué va en cada sección, consultar la guía de formato
   correspondiente — ahí está el razonamiento detrás de cada bloque.
