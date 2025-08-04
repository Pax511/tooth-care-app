from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from passlib.context import CryptContext
from jose import JWTError, jwt
from datetime import datetime, timedelta, date
from typing import List, Optional
import models, schemas
from schemas import (
    PatientPublic, FeedbackCreate, FeedbackResponse,
    ProgressCreate, ProgressEntry,
    InstructionStatusBulkCreate, InstructionStatusResponse,
    TreatmentInfoCreate
)
from database import get_db, engine
import os
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI()

# CORS for Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
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
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")
doctor_oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/doctor-login")

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

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
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(), 
    db: AsyncSession = Depends(get_db)
):
    try:
        result = await db.execute(select(models.Patient).where(models.Patient.username == form_data.username))
        user = result.scalar_one_or_none()
        if not user or not verify_password(form_data.password, user.password):
            raise HTTPException(status_code=401, detail="Incorrect username or password")

        access_token = create_access_token(data={"sub": user.username})
        return {"access_token": access_token, "token_type": "bearer"}

    except Exception as e:
        print("❌ Login error:", e)
        raise HTTPException(status_code=500, detail="Internal Server Error")

@app.post("/doctor-login", response_model=schemas.TokenResponse)
async def doctor_login(form_data: OAuth2PasswordRequestForm = Depends(), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.Doctor).where(models.Doctor.username == form_data.username))
    doctor = result.scalar_one_or_none()
    if not doctor or not verify_password(form_data.password, doctor.password):
        raise HTTPException(status_code=401, detail="Incorrect username or password")
    access_token = create_access_token(data={"sub": doctor.username})
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/patients/me", response_model=PatientPublic)
async def get_my_profile(current_user: models.Patient = Depends(get_current_user)):
    return current_user

@app.post("/feedback", response_model=FeedbackResponse)
async def submit_feedback(
    feedback: FeedbackCreate,
    db: AsyncSession = Depends(get_db),
    current_user: models.Patient = Depends(get_current_user)
):
    new_feedback = models.Feedback(
        patient_id=current_user.id,
        message=feedback.message
    )
    db.add(new_feedback)
    await db.commit()
    await db.refresh(new_feedback)
    return {"message": feedback.message, "status": "success"}

@app.get("/feedback", response_model=List[FeedbackResponse])
async def get_my_feedbacks(
    db: AsyncSession = Depends(get_db),
    current_user: models.Patient = Depends(get_current_user)
):
    result = await db.execute(
        select(models.Feedback).where(models.Feedback.patient_id == current_user.id)
    )
    feedbacks = result.scalars().all()
    return [{"message": f.message, "status": "success"} for f in feedbacks]

@app.post("/progress", response_model=ProgressEntry)
async def submit_progress(
    progress: ProgressCreate,
    db: AsyncSession = Depends(get_db),
    current_user: models.Patient = Depends(get_current_user)
):
    db_entry = models.Progress(
        patient_id=current_user.id,
        message=progress.message
    )
    db.add(db_entry)
    await db.commit()
    await db.refresh(db_entry)
    return db_entry

@app.get("/progress", response_model=List[ProgressEntry])
async def get_progress(
    db: AsyncSession = Depends(get_db),
    current_user: models.Patient = Depends(get_current_user)
):
    result = await db.execute(
        select(models.Progress)
        .where(models.Progress.patient_id == current_user.id)
        .order_by(models.Progress.timestamp.desc())
    )
    return result.scalars().all()

@app.post("/instruction-status", response_model=List[InstructionStatusResponse])
async def save_instruction_status(
    payload: InstructionStatusBulkCreate,
    db: AsyncSession = Depends(get_db),
    current_user: models.Patient = Depends(get_current_user),
):
    saved = []
    for item in payload.items:
        row = models.InstructionStatus(
            patient_id=current_user.id,
            date=item.date,
            treatment=item.treatment,
            subtype=item.subtype,
            group=item.group,
            instruction_index=item.instruction_index,
            instruction_text=item.instruction_text,
            followed=item.followed,
        )
        db.add(row)
        saved.append(row)
    await db.commit()
    for r in saved:
        await db.refresh(r)
    return saved

@app.get("/instruction-status", response_model=List[InstructionStatusResponse])
async def list_instruction_status(
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
    db: AsyncSession = Depends(get_db),
    current_user: models.Patient = Depends(get_current_user),
):
    q = select(models.InstructionStatus).where(
        models.InstructionStatus.patient_id == current_user.id
    )
    if date_from:
        q = q.where(models.InstructionStatus.date >= date_from)
    if date_to:
        q = q.where(models.InstructionStatus.date <= date_to)

    result = await db.execute(q.order_by(
        models.InstructionStatus.date.desc(),
        models.InstructionStatus.group.asc(),
        models.InstructionStatus.instruction_index.asc()
    ))
    return result.scalars().all()

class DepartmentDoctorUpdate(BaseModel):
    department: str
    doctor: str

@app.post("/department-doctor")
async def save_department_doctor(
    data: DepartmentDoctorUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: models.Patient = Depends(get_current_user)
):
    current_user.department = data.department
    current_user.doctor = data.doctor
    db.add(current_user)
    await db.commit()
    await db.refresh(current_user)
    return {"status": "success", "department": data.department, "doctor": data.doctor}

# -------------------------------------------------
# ✅ Treatment Info SAVE Endpoint (Updates Patient Table Directly)
# -------------------------------------------------
@app.post("/treatment-info", response_model=PatientPublic)
async def save_treatment_info(
    info: TreatmentInfoCreate,
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(models.Patient).where(models.Patient.username == info.username))
    patient = result.scalar_one_or_none()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    # Update treatment info directly in patients table
    patient.treatment = info.treatment
    patient.treatment_subtype = info.subtype
    patient.procedure_date = info.procedure_date
    patient.procedure_time = info.procedure_time
    # patient.procedure_completed = info.procedure_completed  # If you want to support this, add to schema

    db.add(patient)
    await db.commit()
    await db.refresh(patient)
    return patient