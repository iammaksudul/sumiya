from typing import Generator, Optional
from fastapi import Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from app.core.config import settings
from app.db.session import SessionLocal
from app.core.auth import verify_passkey

def get_db() -> Generator:
    try:
        db = SessionLocal()
        yield db
    finally:
        db.close()

def get_current_user(request: Request):
    """Verify that the user is authenticated with a valid passkey"""
    passkey = request.cookies.get("passkey")
    
    if not passkey:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
        )
    
    if not verify_passkey(passkey):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid passkey",
        )
    
    return {"username": "Kh maksudul alam"} 