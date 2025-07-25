from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from passlib.context import CryptContext
from jose import JWTError, jwt
from datetime import datetime, timedelta
from typing import List
import models, schemas
from database import get_db, engine
import smtplib
from email.message import EmailMessage
import os

from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# CORS: Allow requests from Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Or restrict to specific IP if needed
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def startup():
    async with engine.begin() as conn:
        await conn.run_sync(models.Base.metadata.create_all)

SECRET_KEY = os.getenv("SECRET_KEY", "secret")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/login")
doctor_oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/doctor-login")

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)
3
def get_password_hash(password):
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

async def get_current_user(token: str = Depends(oauth2_scheme), db: AsyncSession = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username = payload.get("sub")
        if username is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    result = await db.execute(select(models.Patient).where(models.Patient.username == username))
    user = result.scalar_one_or_none()
    if user is None:
        raise credentials_exception
    return user

async def get_current_doctor(token: str = Depends(doctor_oauth2_scheme), db: AsyncSession = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials (doctor)",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username = payload.get("sub")
        if username is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    result = await db.execute(select(models.Doctor).where(models.Doctor.username == username))
    doctor = result.scalar_one_or_none()
    if doctor is None:
        raise credentials_exception
    return doctor

async def require_admin(user: models.Patient = Depends(get_current_user)):
    if user.username != "admin":
        raise HTTPException(status_code=403, detail="Admin privileges required")
    return user

@app.get("/")
async def root():
    return {"message": "✅ MGM Hospital API is running."}

@app.post("/signup", response_model=schemas.TokenResponse)
async def signup(patient: schemas.PatientCreate, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.Patient).where(models.Patient.username == patient.username))
    existing_user = result.scalar_one_or_none()
    if existing_user:
        raise HTTPException(status_code=400, detail="Username already exists")

    hashed_pw = get_password_hash(patient.password)
    db_patient = models.Patient(**patient.dict(exclude={"password"}), password=hashed_pw)
    db.add(db_patient)
    await db.commit()
    await db.refresh(db_patient)
    access_token = create_access_token(data={"sub": db_patient.username})
    return {"access_token": access_token, "token_type": "bearer"}

@app.post("/login", response_model=schemas.TokenResponse)
async def login(form_data: OAuth2PasswordRequestForm = Depends(), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.Patient).where(models.Patient.username == form_data.username))
    user = result.scalar_one_or_none()
    if not user or not verify_password(form_data.password, user.password):
        raise HTTPException(status_code=401, detail="Incorrect username or password")
    access_token = create_access_token(data={"sub": user.username})
    return {"access_token": access_token, "token_type": "bearer"}

@app.post("/doctor-login", response_model=schemas.TokenResponse)
async def doctor_login(form_data: OAuth2PasswordRequestForm = Depends(), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.Doctor).where(models.Doctor.username == form_data.username))
    doctor = result.scalar_one_or_none()
    if not doctor or not verify_password(form_data.password, doctor.password):
        raise HTTPException(status_code=401, detail="Incorrect username or password")
    access_token = create_access_token(data={"sub": doctor.username})
    return {"access_token": access_token, "token_type": "bearer"}

# ... rest of the original API remains unchanged (patients, doctors, appointments, feedback) ...
from schemas import PatientPublic

@app.get("/patients/me", response_model=PatientPublic)
async def get_my_profile(current_user: models.Patient = Depends(get_current_user)):
    return current_user
