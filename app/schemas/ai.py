from typing import Dict, Any, Optional
from pydantic import BaseModel

class CommandRequest(BaseModel):
    task_description: str

class CommandResponse(BaseModel):
    command: str

class ScriptRequest(BaseModel):
    script_type: str
    task_description: str
    parameters: Optional[Dict[str, Any]] = None

class ScriptResponse(BaseModel):
    script: str

class AnalysisRequest(BaseModel):
    config_content: str
    config_type: str

class AnalysisResponse(BaseModel):
    analysis: str

class CPanelRequest(BaseModel):
    task_description: str
    parameters: Optional[Dict[str, Any]] = None

class CPanelResponse(BaseModel):
    solution: str
    commands: Optional[str] = None
    warnings: Optional[str] = None 