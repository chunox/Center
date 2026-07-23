from fastapi import APIRouter

api_router = APIRouter()

# Los routers de cada dominio (auth, organizations, projects, work_items...)
# se registran acá a medida que se implementan:
# api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
