from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.api import deps
from app.schemas.user import User
from app.services.ai_service import AIService
from app.schemas.ai import ScriptRequest, ScriptResponse, AnalysisRequest, AnalysisResponse

router = APIRouter()
ai_service = AIService()

@router.post("/generate-pipeline", response_model=ScriptResponse)
def generate_pipeline(
    *,
    request: ScriptRequest,
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db)
) -> Any:
    """
    Generate CI/CD pipeline configurations (GitHub Actions, GitLab CI, Jenkins)
    """
    try:
        script = ai_service.generate_script(
            script_type="pipeline",
            task_description=request.task_description,
            parameters=request.parameters
        )
        return ScriptResponse(script=script)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/generate-dockerfile", response_model=ScriptResponse)
def generate_dockerfile(
    *,
    request: ScriptRequest,
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db)
) -> Any:
    """
    Generate Dockerfile and docker-compose configurations
    """
    try:
        script = ai_service.generate_script(
            script_type="dockerfile",
            task_description=request.task_description,
            parameters=request.parameters
        )
        return ScriptResponse(script=script)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/generate-kubernetes", response_model=ScriptResponse)
def generate_kubernetes(
    *,
    request: ScriptRequest,
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db)
) -> Any:
    """
    Generate Kubernetes manifests and configurations
    """
    try:
        script = ai_service.generate_script(
            script_type="kubernetes",
            task_description=request.task_description,
            parameters=request.parameters
        )
        return ScriptResponse(script=script)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/analyze-infrastructure", response_model=AnalysisResponse)
def analyze_infrastructure(
    *,
    request: AnalysisRequest,
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db)
) -> Any:
    """
    Analyze infrastructure configurations and provide recommendations
    """
    try:
        analysis = ai_service.analyze_configuration(
            request.config_content,
            request.config_type
        )
        return AnalysisResponse(analysis=analysis)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/monitoring-setup", response_model=ScriptResponse)
def generate_monitoring_config(
    *,
    request: ScriptRequest,
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db)
) -> Any:
    """
    Generate monitoring and alerting configurations (Prometheus, Grafana, etc.)
    """
    try:
        script = ai_service.generate_script(
            script_type="monitoring",
            task_description=request.task_description,
            parameters=request.parameters
        )
        return ScriptResponse(script=script)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e)) 