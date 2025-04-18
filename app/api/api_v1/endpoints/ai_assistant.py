from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.api import deps
from app.schemas.user import User
from app.services.ai_service import AIService
from app.schemas.ai import (
    CommandRequest,
    CommandResponse,
    ScriptRequest,
    ScriptResponse,
    AnalysisRequest,
    AnalysisResponse
)

router = APIRouter()
ai_service = AIService()

@router.post("/generate-command", response_model=CommandResponse)
def generate_command(
    *,
    request: CommandRequest,
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db)
) -> Any:
    """
    Generate Linux CLI commands based on user request
    """
    try:
        command = ai_service.generate_command(request.task_description)
        return CommandResponse(command=command)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/generate-script", response_model=ScriptResponse)
def generate_script(
    *,
    request: ScriptRequest,
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db)
) -> Any:
    """
    Generate automation scripts (Bash, Python, Ansible, etc.)
    """
    try:
        script = ai_service.generate_script(
            request.script_type,
            request.task_description,
            request.parameters
        )
        return ScriptResponse(script=script)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/analyze-config", response_model=AnalysisResponse)
def analyze_config(
    *,
    request: AnalysisRequest,
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db)
) -> Any:
    """
    Analyze server configuration files and provide recommendations
    """
    try:
        analysis = ai_service.analyze_configuration(
            request.config_content,
            request.config_type
        )
        return AnalysisResponse(analysis=analysis)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/cpanel-solution", response_model=ScriptResponse)
def get_cpanel_solution(
    *,
    request: ScriptRequest,
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db)
) -> Any:
    """
    Generate cPanel/WHM solutions and commands
    """
    try:
        solution = ai_service.generate_cpanel_solution(
            request.task_description,
            request.parameters
        )
        return ScriptResponse(script=solution)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e)) 