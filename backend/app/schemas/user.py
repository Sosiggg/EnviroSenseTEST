from pydantic import BaseModel, EmailStr
from typing import Optional

class UserBase(BaseModel):
    username: str
    email: EmailStr

class UserCreate(UserBase):
    password: str

class UserLogin(BaseModel):
    username: str
    password: str

class UserUpdate(UserBase):
    pass

class PasswordChange(BaseModel):
    current_password: str
    new_password: str

class User(UserBase):
    id: int
    is_active: bool

    class Config:
        from_attributes = True
