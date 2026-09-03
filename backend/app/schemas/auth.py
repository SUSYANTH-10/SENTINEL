from pydantic import BaseModel, Field


class SignupRequest(BaseModel):
    user_id: str = Field(min_length=3, max_length=50)
    password: str = Field(min_length=6, max_length=128)
    balance: float = Field(ge=0)


class LoginRequest(BaseModel):
    user_id: str
    password: str