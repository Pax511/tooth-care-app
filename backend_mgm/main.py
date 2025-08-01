import os
from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.security import OAuth2PasswordRequestForm, OAuth2PasswordBearer
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.exc import IntegrityError
from pydantic import BaseModel, EmailStr
from passlib.context import CryptContext
from jose import JWTError, jwt
from datetime import datetime, timedelta, date
from typing import Optional

from database import get_db, Base, engine
from sqlalchemy import Column, Integer, String, Date

# --- JWT & Security Settings ---
SECRET_KEY = os.getenv("SECRET_KEY", "mysecretkey")  # Use env in production!
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

# --- SQLAlchemy Patient model ---
class Patient(Base):
    __tablename__ = 'patients'
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    dob = Column(Date, nullable=False)
    gender = Column(String, nullable=False)
    phone = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    username = Column(String, unique=True, index=True, nullable=False)
    password = Column(String, nullable=False)

# --- Pydantic schemas ---
class PatientCreate(BaseModel):
    name: str
    dob: date
    gender: str
    phone: str
    email: EmailStr
    username: str
    password: str

class PatientOut(BaseModel):
    id: int
    name: str
    dob: date
    gender: str
    phone: str
    email: EmailStr
    username: str

    class Config:
        orm_mode = True

class Token(BaseModel):
    access_token: str
    token_type: str

# --- JWT utility functions ---
def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

async def get_current_user(token: str = Depends(oauth2_scheme), db: AsyncSession = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    result = await db.execute(select(Patient).where(Patient.username == username))
    user = result.scalar_one_or_none()
    if user is None:
        raise credentials_exception
    return user

# --- FastAPI app setup ---
app = FastAPI()

@app.on_event("startup")
async def on_startup():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

# --- Signup endpoint ---
@app.post("/signup", status_code=201)
async def signup(user: PatientCreate, db: AsyncSession = Depends(get_db)):
    # Check for duplicate email
    res = await db.execute(select(Patient).where(Patient.email == user.email))
    if res.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Email already registered")
    # Check for duplicate username
    res = await db.execute(select(Patient).where(Patient.username == user.username))
    if res.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Username already taken")
    # Hash password
    hashed_password = pwd_context.hash(user.password)
    # Create and add new Patient
    new_patient = Patient(
        name=user.name,
        dob=user.dob,
        gender=user.gender,
        phone=user.phone,
        email=user.email,
        username=user.username,
        password=hashed_password
    )
    db.add(new_patient)
    try:
        await db.commit()
        return {"msg": "Signup successful"}
    except IntegrityError:
        await db.rollback()
        raise HTTPException(status_code=400, detail="Email or Username already exists")

# --- Login endpoint ---
@app.post("/login", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends(), db: AsyncSession = Depends(get_db)):
    # Allow login with username OR email
    res = await db.execute(select(Patient).where(Patient.username == form_data.username))
    user = res.scalar_one_or_none()
    if not user:
        res = await db.execute(select(Patient).where(Patient.email == form_data.username))
        user = res.scalar_one_or_none()
    if not user or not pwd_context.verify(form_data.password, user.password):
        raise HTTPException(status_code=400, detail="Incorrect username/email or password")
    access_token = create_access_token(
        data={"sub": user.username},
        expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    return {"access_token": access_token, "token_type": "bearer"}

# --- Protected profile endpoint ---
@app.get("/patients/me", response_model=PatientOut)
async def read_users_me(current_user: Patient = Depends(get_current_user)):
    return current_user

# --- Health check route (optional) ---
@app.get("/")
async def root():
    return {"status": "ok"}
