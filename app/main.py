from fastapi import FastAPI, Request, Response, HTTPException, status, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from fastapi.responses import HTMLResponse
from pathlib import Path
import os

from app.core.config import settings
from app.core.auth import authenticate_passkey
from app.api.deps import get_current_user
from app.services.ai_service import AIService

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="Sumiya - AI DevOps Assistant for Linux System Administration"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Static files
app.mount("/static", StaticFiles(directory="app/static"), name="static")

# Templates
templates = Jinja2Templates(directory="app/templates")

# Initialize AI service
ai_service = AIService()

@app.get("/", response_class=HTMLResponse)
async def root(request: Request):
    """Render the main page or login page based on authentication status."""
    try:
        user = await get_current_user(request)
        return templates.TemplateResponse("index.html", {"request": request, "user": user})
    except HTTPException:
        return templates.TemplateResponse("login.html", {"request": request})

@app.post("/auth/login")
async def login(request: Request, response: Response):
    """Authenticate user with passkey."""
    form = await request.form()
    passkey = form.get("passkey")
    
    if not passkey:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Passkey is required"
        )
    
    if not authenticate_passkey(passkey):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid passkey"
        )
    
    response = Response(status_code=status.HTTP_302_FOUND)
    response.headers["Location"] = "/"
    response.set_cookie(
        key="passkey",
        value=passkey,
        httponly=True,
        secure=True,
        samesite="lax"
    )
    return response

@app.get("/auth/logout")
async def logout(response: Response):
    """Clear the passkey cookie and redirect to login."""
    response = Response(status_code=status.HTTP_302_FOUND)
    response.headers["Location"] = "/"
    response.delete_cookie("passkey")
    return response

@app.get("/api/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "version": settings.VERSION,
        "model": settings.AI_MODEL_NAME
    }

@app.post("/api/v1/assistant/chat")
async def chat(
    request: Request,
    current_user: dict = Depends(get_current_user)
):
    """Chat endpoint for the AI assistant."""
    data = await request.json()
    message = data.get("message")
    
    if not message:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Message is required"
        )
    
    try:
        response = ai_service.get_completion(message)
        return {"response": response}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@app.post("/api/v1/assistant/command")
async def generate_command(
    request: Request,
    current_user: dict = Depends(get_current_user)
):
    """Generate Linux command based on description."""
    data = await request.json()
    description = data.get("description")
    
    if not description:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Description is required"
        )
    
    try:
        command = ai_service.generate_command(description)
        return {"command": command}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@app.post("/api/v1/assistant/script")
async def generate_script(
    request: Request,
    current_user: dict = Depends(get_current_user)
):
    """Generate shell script based on requirements."""
    data = await request.json()
    requirements = data.get("requirements")
    
    if not requirements:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Requirements are required"
        )
    
    try:
        script = ai_service.generate_script(requirements)
        return {"script": script}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@app.post("/api/v1/assistant/analyze")
async def analyze_config(
    request: Request,
    current_user: dict = Depends(get_current_user)
):
    """Analyze system configuration file."""
    data = await request.json()
    config = data.get("config")
    config_type = data.get("type", "general")
    
    if not config:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Configuration is required"
        )
    
    try:
        analysis = ai_service.analyze_config(config, config_type)
        return {"analysis": analysis}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        ) 