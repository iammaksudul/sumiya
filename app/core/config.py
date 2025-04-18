from typing import List
import os
from pydantic_settings import BaseSettings
from dotenv import load_dotenv

load_dotenv()

class Settings(BaseSettings):
    PROJECT_NAME: str = "Sumiya - AI DevOps Assistant"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    # Security
    SECRET_KEY: str = os.getenv("SECRET_KEY", os.urandom(32).hex())
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # Database
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./sumiya.db")
    
    # Passkey
    DEFAULT_PASSKEY: str = os.getenv("DEFAULT_PASSKEY", "sinbad")
    
    # CORS
    CORS_ORIGINS: List[str] = os.getenv("CORS_ORIGINS", "http://localhost:8000,http://127.0.0.1:8000,http://195.201.21.145:8000,http://195.201.21.145").split(",")
    
    # Rate Limiting
    RATE_LIMIT_PER_MINUTE: int = 60
    
    # AI Model
    AI_MODEL_NAME: str = os.getenv("AI_MODEL_NAME", "facebook/opt-350m")
    AI_MODEL_CACHE_DIR: str = os.getenv("AI_MODEL_CACHE_DIR", "./model_cache")
    
    # Server
    HOST: str = os.getenv("HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PORT", "8000"))
    
    # Logging
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")
    LOG_FILE: str = os.getenv("LOG_FILE", "sumiya.log")
    
    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings() 