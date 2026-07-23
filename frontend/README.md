# PM Tool — Frontend

Cliente React + Vite + TypeScript para la API en [`../backend`](../backend).
Esta carpeta hoy solo tiene la estructura planeada — el scaffold real
(`package.json`, `vite.config.ts`, `tsconfig.json`, `index.html`,
`src/main.tsx`, etc.) se genera con:

```bash
npm create vite@latest . -- --template react-ts
```

corriendo **dentro de `frontend/`**. Como ya existen carpetas (`src/api`,
`src/components`, etc.), Vite va a preguntar cómo proceder con el directorio
no vacío — elegir la opción de ignorar/conservar los archivos existentes en
vez de borrar todo.

## Estructura de carpetas

```
src/
├── api/            # cliente HTTP + un archivo por dominio (llamadas a /api/v1/<dominio>)
├── components/     # componentes UI reutilizables, sin lógica de negocio ni fetch
├── features/       # una carpeta por dominio — componentes, hooks y páginas propias de esa feature
│   ├── auth/
│   ├── organizations/
│   ├── projects/
│   ├── work-items/
│   ├── iterations/
│   ├── ceremonies/
│   ├── documents/
│   ├── conversations/
│   └── notifications/
├── hooks/          # hooks compartidos entre features (no específicos de una)
├── lib/            # utilidades y config (cliente axios/fetch, formateo de fechas, etc.)
├── routes/         # definición de rutas / router
├── store/          # estado global (contexto, zustand, redux — lo que se elija)
├── types/          # tipos TS que reflejan los schemas del backend (`app/schemas/` allá)
└── styles/         # estilos globales
```

Las carpetas de `features/` reflejan 1:1 los routers de
[`../backend/app/api/v1`](../backend/app/api/v1) y sus schemas en
[`../backend/app/schemas`](../backend/app/schemas) — al agregar un dominio
nuevo en el backend, sumar su carpeta acá también.

### Convenciones

- **`api/`** habla HTTP puro (fetch/axios + tipos de `types/`) — no importa
  componentes ni conoce de UI.
- **`features/<dominio>/`** es dueño de su propia UI y hooks; si algo se
  reutiliza en más de una feature, sube a `components/` o `hooks/`.
- **`types/`** se mantiene alineado a mano con los Pydantic schemas del
  backend (mismos campos y nullability) hasta que se decida generar tipos
  automáticamente desde el OpenAPI del backend (`/docs` expone el schema).
