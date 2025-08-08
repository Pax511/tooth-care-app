from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from passlib.context import CryptContext
from jose import JWTError, jwt
from datetime import datetime, timedelta, date
from typing import List, Optional
from routes import episodes
import models, schemas
from schemas import (
    PatientPublic, FeedbackCreate, FeedbackResponse,
    ProgressCreate, ProgressEntry,
    InstructionStatusBulkCreate, InstructionStatusResponse,
    TreatmentInfoCreate,
    EpisodeResponse, CurrentEpisodeResponse, MarkCompleteRequest, RotateIfDueResponse
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

# -------------------
# Internals for Episodes
# -------------------

async def _get_or_create_open_episode(db: AsyncSession, patient_id: int) -> models.TreatmentEpisode:
    stmt = (
        select(models.TreatmentEpisode)
        .where(
            models.TreatmentEpisode.patient_id == patient_id,
            models.TreatmentEpisode.locked == False,  # noqa: E712
        )
        .order_by(models.TreatmentEpisode.id.desc())
    )
    res = await db.execute(stmt)
    ep = res.scalar_one_or_none()
    if ep:
        return ep
    # Create first episode
    new_ep = models.TreatmentEpisode(
        patient_id=patient_id,
        department=None,
        doctor=None,
        treatment=None,
        subtype=None,
        procedure_completed=False,
        locked=False,
        procedure_date=None,
        procedure_time=None,
    )
    db.add(new_ep)
    await db.commit()
    await db.refresh(new_ep)
    return new_ep

async def _mirror_episode_to_patient(db: AsyncSession, patient: models.Patient, episode: models.TreatmentEpisode) -> None:
    patient.department = episode.department
    patient.doctor = episode.doctor
    patient.treatment = episode.treatment
    patient.treatment_subtype = episode.subtype
    patient.procedure_date = episode.procedure_date
    patient.procedure_time = episode.procedure_time
    patient.procedure_completed = episode.procedure_completed
    db.add(patient)
    await db.commit()
    await db.refresh(patient)

async def _rotate_if_due(db: AsyncSession, patient: models.Patient) -> Optional[int]:
    """
    If the open episode is completed and 15+ days have passed since procedure_date,
    lock it, create a new open episode, and clear patient mirror fields.
    Returns new episode id if rotated, else None.
    """
    ep = await _get_or_create_open_episode(db, patient.id)

    # If already locked, there should already be a new episode elsewhere; return None.
    if ep.locked:
        return None

    if not ep.procedure_completed or not ep.procedure_date:
        return None

    days_elapsed = (date.today() - ep.procedure_date).days
    if days_elapsed < 15:
        return None

    # Lock current episode
    ep.locked = True
    db.add(ep)
    await db.commit()

    # Create new episode
    new_ep = models.TreatmentEpisode(
        patient_id=patient.id,
        department=None,
        doctor=None,
        treatment=None,
        subtype=None,
        procedure_completed=False,
        locked=False,
        procedure_date=None,
        procedure_time=None,
    )
    db.add(new_ep)
    await db.commit()
    await db.refresh(new_ep)

    # Mirror cleared values to patient (represents "fresh start")
    await _mirror_episode_to_patient(db, patient, new_ep)

    return new_ep.id

# -------------------
# Auth
# -------------------

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

    # Create initial episode and mirror to patient
    ep = await _get_or_create_open_episode(db, db_patient.id)
    await _mirror_episode_to_patient(db, db_patient, ep)

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

# -------------------
# Patient profile
# -------------------

@app.get("/patients/me", response_model=PatientPublic)
async def get_my_profile(current_user: models.Patient = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    # Ensure rotation if due so mirrored fields reflect the current episode
    await _rotate_if_due(db, current_user)
    return current_user

# -------------------
# Feedback
# -------------------

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

# -------------------
# Progress
# -------------------

@app.post("/progress", response_model=ProgressEntry)
async def submit_progress(
    progress: ProgressCreate,
    db: AsyncSession = Depends(get_db),
    current_user: models.Patient = Depends(get_current_user)
):
    # Rotate episode if due before recording new progress
    await _rotate_if_due(db, current_user)

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

# -------------------
# Instruction Status
# -------------------

@app.post("/instruction-status", response_model=List[InstructionStatusResponse])
async def save_instruction_status(
    payload: InstructionStatusBulkCreate,
    db: AsyncSession = Depends(get_db),
    current_user: models.Patient = Depends(get_current_user),
):
    # Rotate episode if due before recording new instruction statuses
    await _rotate_if_due(db, current_user)

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

# -------------------
# Department / Doctor
# -------------------

class DepartmentDoctorUpdate(BaseModel):
    department: str
    doctor: str

@app.post("/department-doctor")
async def save_department_doctor(
    data: DepartmentDoctorUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: models.Patient = Depends(get_current_user)
):
    # Rotate if due and get open episode
    await _rotate_if_due(db, current_user)
    ep = await _get_or_create_open_episode(db, current_user.id)

    # If somehow locked, block writes
    if ep.locked:
        raise HTTPException(status_code=423, detail="Episode is locked and cannot be modified.")

    # Write to episode and mirror to patient
    ep.department = data.department
    ep.doctor = data.doctor
    db.add(ep)
    await db.commit()
    await db.refresh(ep)

    await _mirror_episode_to_patient(db, current_user, ep)

    return {"status": "success", "department": data.department, "doctor": data.doctor, "current_episode_id": ep.id}

# -------------------
# Treatment Info
# -------------------

# ✅ Treatment Info SAVE Endpoint (now writes to Episode and mirrors to Patient)
@app.post("/treatment-info", response_model=PatientPublic)
async def save_treatment_info(
    info: TreatmentInfoCreate,
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(models.Patient).where(models.Patient.username == info.username))
    patient = result.scalar_one_or_none()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    # Rotate if due and get open episode
    await _rotate_if_due(db, patient)
    ep = await _get_or_create_open_episode(db, patient.id)
    if ep.locked:
        raise HTTPException(status_code=423, detail="Episode is locked and cannot be modified.")

    # Update episode fields
    ep.treatment = info.treatment
    ep.subtype = info.subtype
    ep.procedure_date = info.procedure_date
    ep.procedure_time = info.procedure_time
    db.add(ep)
    await db.commit()
    await db.refresh(ep)

    # Mirror back to patient for backward compatibility with existing client views
    await _mirror_episode_to_patient(db, patient, ep)
    return patient

# -------------------
# Episodes APIs (NEW)
# -------------------

@app.get("/episodes/current", response_model=CurrentEpisodeResponse)
async def get_current_episode(
    db: AsyncSession = Depends(get_db),
    current_user: models.Patient = Depends(get_current_user)
):
    await _rotate_if_due(db, current_user)
    ep = await _get_or_create_open_episode(db, current_user.id)
    return CurrentEpisodeResponse.model_validate(ep, from_attributes=True)

@app.get("/episodes/history", response_model=List[EpisodeResponse])
async def get_episode_history(
    db: AsyncSession = Depends(get_db),
    current_user: models.Patient = Depends(get_current_user)
):
    stmt = (
        select(models.TreatmentEpisode)
        .where(models.TreatmentEpisode.patient_id == current_user.id)
        .order_by(models.TreatmentEpisode.id.desc())
    )
    res = await db.execute(stmt)
    episodes = res.scalars().all()
    return [EpisodeResponse.model_validate(e, from_attributes=True) for e in episodes]

@app.post("/episodes/mark-complete", response_model=EpisodeResponse)
async def mark_episode_complete(
    payload: MarkCompleteRequest,
    db: AsyncSession = Depends(get_db),
    current_user: models.Patient = Depends(get_current_user),
):
    ep = await _get_or_create_open_episode(db, current_user.id)
    if ep.locked:
        raise HTTPException(status_code=423, detail="Episode is locked and cannot be modified.")
    ep.procedure_completed = bool(payload.procedure_completed)
    if payload.procedure_date is not None:
        ep.procedure_date = payload.procedure_date
    if payload.procedure_time is not None:
        ep.procedure_time = payload.procedure_time
    db.add(ep)
    await db.commit()
    await db.refresh(ep)

    # Mirror to patient
    await _mirror_episode_to_patient(db, current_user, ep)

    return EpisodeResponse.model_validate(ep, from_attributes=True)

@app.post("/episodes/rotate-if-due", response_model=RotateIfDueResponse)
async def rotate_if_due_endpoint(
    db: AsyncSession = Depends(get_db),
    current_user: models.Patient = Depends(get_current_user),
):
    new_id = await _rotate_if_due(db, current_user)
    if new_id is None:
        return RotateIfDueResponse(rotated=False, new_episode_id=None)
    return RotateIfDueResponse(rotated=True, new_episode_id=new_id)

app = FastAPI()
app.include_router(episodes.router)