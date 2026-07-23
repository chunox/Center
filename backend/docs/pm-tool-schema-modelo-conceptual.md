# Modelo conceptual — Herramienta de gestión de proyectos

Este documento describe, en lenguaje llano, qué representa cada parte del
sistema y cómo se relacionan entre sí. No usa sintaxis técnica — está
pensado para cualquier persona del equipo, técnica o no.

## 1. La base: organizaciones, proyectos y personas

Todo en el sistema pertenece a una **organización** (una empresa o equipo
que contrató la herramienta). Dentro de una organización puede haber
varios **proyectos**.

Una **persona** (usuario) puede pertenecer a varias organizaciones a la
vez, y dentro de cada una, a varios proyectos. En cada proyecto o
organización, la persona tiene un **rol** (Admin, Miembro, o un rol
personalizado que el propio equipo defina) que determina qué puede hacer:
crear tareas, invitar gente, cambiar configuración, etc. Los roles no son
fijos — cada organización puede crear los suyos con el conjunto de
permisos que necesite, además de los roles básicos que la aplicación
ofrece por defecto.

## 2. Cómo se organiza el trabajo

Cada proyecto puede seguir una **metodología** distinta: Scrum,
organización por Features (entregables), o un modo libre sin
restricciones. La base de datos no impone reglas de ninguna metodología
en particular — es la aplicación la que decide qué comportamiento aplicar
según la metodología elegida.

El trabajo se organiza en **unidades de trabajo**: épicas, historias,
features, tareas y subtareas. Todas son, en el fondo, el mismo tipo de
entidad — lo que cambia es su nivel dentro de una jerarquía. Una épica
puede contener historias, que contienen tareas, que contienen subtareas
(flujo Scrum); o una feature puede contener directamente tareas y
subtareas (flujo por features). El modo libre solo usa tareas y
subtareas, agrupadas en sprints.

Cada proyecto tiene su propio **tablero** con columnas configurables
(To Do, In Progress, Done, o las que el equipo quiera nombrar), y cada
unidad de trabajo vive en una de esas columnas.

Las unidades de trabajo pueden agruparse en **contenedores de tiempo**:
un sprint (con fecha de inicio y fin) o un milestone (sin fechas,
agrupando por entregable). Cualquier nivel de la jerarquía —una épica, una
tarea, una subtarea— puede asignarse directamente a uno de estos
contenedores.

Las unidades de trabajo también pueden **depender entre sí**: una puede
bloquear a otra, estar simplemente relacionada, o marcarse como
duplicada de otra.

## 3. Ceremonias

El equipo puede registrar sus reuniones de trabajo — daily, planning,
refinement, retro, o cualquier otra que el equipo invente. Cada
ceremonia es un evento puntual con su fecha, sus participantes, y
opcionalmente las unidades de trabajo que se discutieron (por ejemplo,
marcar una tarea como "bloqueada" durante la daily de hoy).

## 4. Documentación

Cada proyecto puede tener documentos asociados — ya sea contenido escrito
directamente en la herramienta (como una wiki) o archivos subidos (PDFs,
imágenes, hojas de cálculo). Un documento puede vincularse a una o varias
unidades de trabajo específicas, por ejemplo la especificación técnica de
una épica.

## 5. Comunicación entre personas

Dentro de un proyecto, las personas pueden conversar entre sí —
conversaciones grupales o de a dos, que pueden ser generales del proyecto
o acotadas a una unidad de trabajo puntual (por ejemplo, discutir una
feature específica). Cada conversación tiene sus mensajes y sus
participantes.

Además, cualquier evento relevante del sistema (que te asignaron una
tarea, que alguien te mencionó, un recordatorio de ceremonia, un mensaje
nuevo) genera una **notificación** personal para el usuario afectado.

Distinto de la conversación general, cada unidad de trabajo, ceremonia o
documento puede tener sus propios **comentarios** — anotaciones puntuales
sobre esa entidad específica.

## 6. Historial y trazabilidad

El sistema registra los cambios más importantes que ocurren en las
unidades de trabajo y otras entidades (cambios de estado, de sprint, de
responsable) para poder reconstruir qué pasó y cuándo — sin necesidad de
guardar cada edición menor.

## 7. Seguridad y acceso

Cada persona se autentica con contraseña, con un proveedor externo
(Google, GitHub, etc.), o ambos. El sistema mantiene un registro de las
sesiones activas de cada persona (pudiendo tener varios dispositivos
conectados a la vez) y siempre valida los permisos en el momento, nunca
confiando en información vieja — así, si a alguien le cambian el rol o lo
sacan de un proyecto, el efecto es inmediato.

Las invitaciones (a una organización o a un proyecto puntual) son su
propio proceso: alguien invita por email, la persona invitada acepta, y
recién ahí se convierte en miembro con el rol que se le asignó.

## 8. Resumen visual de las relaciones principales

```
Organización ──┬── Miembros (personas + rol)
               └── Proyectos ──┬── Miembros (personas + rol)
                                ├── Configuración (metodología, visibilidad)
                                ├── Tablero (columnas configurables)
                                ├── Unidades de trabajo (jerárquicas)
                                │        ├── Dependencias entre sí
                                │        ├── Comentarios
                                │        ├── Documentos vinculados
                                │        └── Asignados (personas)
                                ├── Sprints / Milestones
                                ├── Ceremonias (daily, planning, retro...)
                                ├── Documentos
                                └── Conversaciones ── Mensajes
```
