from fastapi import APIRouter
from app.api.api_v1.endpoints import auth, users, ai_assistant, devops_tools

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["authentication"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(ai_assistant.router, prefix="/assistant", tags=["ai-assistant"])
api_router.include_router(devops_tools.router, prefix="/devops", tags=["devops-tools"]) 