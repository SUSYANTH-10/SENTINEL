from typing import Optional
from pydantic import BaseModel, Field


class SignupRequest(BaseModel):
    user_id: str = Field(min_length=3, max_length=50)
    password: str = Field(min_length=6, max_length=128)
    safety_password: Optional[str] = Field(default=None, min_length=6, max_length=128)
    balance: float = Field(ge=0)


class LoginRequest(BaseModel):
    user_id: str
    password: str


class LoginResponse(BaseModel):
    message: str
    authenticated: bool
    user_id: str
    login_mode: str  # "normal" | "ghost"
    balance: float