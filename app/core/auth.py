import os
import json
from pathlib import Path
from app.core.config import settings

# File to store the authenticated passkey
AUTH_FILE = Path("auth.json")

def get_stored_passkey():
    """Get the stored passkey from the auth file"""
    if AUTH_FILE.exists():
        with open(AUTH_FILE, "r") as f:
            data = json.load(f)
            return data.get("passkey")
    return None

def store_passkey(passkey):
    """Store the passkey in the auth file"""
    with open(AUTH_FILE, "w") as f:
        json.dump({"passkey": passkey}, f)

def verify_passkey(passkey):
    """Verify if the provided passkey is correct"""
    stored_passkey = get_stored_passkey()
    
    # If no passkey is stored, use the default one
    if not stored_passkey:
        return passkey == settings.DEFAULT_PASSKEY
    
    # Otherwise, check against the stored passkey
    return passkey == stored_passkey

def authenticate_passkey(passkey):
    """Authenticate with the passkey and store it if correct"""
    if verify_passkey(passkey):
        # Store the passkey for future use
        store_passkey(passkey)
        return True
    return False 