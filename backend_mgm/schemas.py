from pydantic import BaseModel, EmailStr, ConfigDict
from datetime import datetime, date
from typing import Optional, List

# -------------------
# ✅ Auth Schemas
# -------------------

class LoginRequest(BaseModel):
    username: str
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"

# -------------------
# ✅ Patient Schemas
# -------------------

class PatientBase(BaseModel):
    name: str
    dob: date
    gender: str
    phone: str
    email: EmailStr
    username: str

class PatientCreate(PatientBase):
    password: str

class PatientUpdate(BaseModel):
    phone: Optional[str] = None
    email: Optional[EmailStr] = None
    password: Optional[str] = None

class Patient(BaseModel):
    id: int
    name: str
    dob: date
    gender: str
    phone: str
    email: EmailStr
    username: str
    password: str  # For internal use only

    model_config = ConfigDict(from_attributes=True)

class PatientPublic(BaseModel):
    id: int
    name: str
    dob: date
    gender: str
    phone: str
    email: EmailStr
    username: str

    model_config = ConfigDict(from_attributes=True)

# -------------------
# ✅ Doctor Schemas
# -------------------

class DoctorBase(BaseModel):
    name: str
    specialty: str

class DoctorCreate(DoctorBase):
    username: str
    password: str

class Doctor(DoctorBase):
    id: int
    username: str
    password: str

    model_config = ConfigDict(from_attributes=True)

# -------------------
# ✅ Appointment Schemas
# -------------------

class AppointmentBase(BaseModel):
    patient_id: int
    doctor_id: int
    appointment_time: datetime

class AppointmentCreate(AppointmentBase):
    pass

class Appointment(AppointmentBase):
    id: int

    model_config = ConfigDict(from_attributes=True)

# -------------------
# ✅ Feedback Schema (Patient -> Hospital)
# -------------------

class Feedback(BaseModel):
    message: str

# -------------------
# ✅ Doctor Feedback Schemas (Doctor -> Patient)
# -------------------

class DoctorFeedbackCreate(BaseModel):
    patient_id: int
    message: str

class DoctorFeedback(BaseModel):
    id: int
    doctor_id: int
    patient_id: int
    message: str

    model_config = ConfigDict(from_attributes=True)

# -------------------
# 🔧 Future: Treatment Instructions
# -------------------

class Treatment(BaseModel):
    name: str
    subtype: Optional[str] = None
    dos: List[str]