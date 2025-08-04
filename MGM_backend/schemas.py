from pydantic import BaseModel, EmailStr, ConfigDict
from datetime import datetime, date, time
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

    # Persistent onboarding/treatment fields
    department: Optional[str] = None
    doctor: Optional[str] = None
    treatment: Optional[str] = None
    treatment_subtype: Optional[str] = None
    procedure_date: Optional[date] = None
    procedure_time: Optional[time] = None
    procedure_completed: Optional[bool] = None   # <-- Added this line

class PatientCreate(PatientBase):
    password: str

class PatientUpdate(BaseModel):
    phone: Optional[str] = None
    email: Optional[EmailStr] = None
    password: Optional[str] = None

    # Persistent onboarding/treatment fields
    department: Optional[str] = None
    doctor: Optional[str] = None
    treatment: Optional[str] = None
    treatment_subtype: Optional[str] = None
    procedure_date: Optional[date] = None
    procedure_time: Optional[time] = None
    procedure_completed: Optional[bool] = None   # <-- Added this line

class Patient(BaseModel):
    id: int
    name: str
    dob: date
    gender: str
    phone: str
    email: EmailStr
    username: str
    password: str  # For internal use only

    # Persistent onboarding/treatment fields
    department: Optional[str] = None
    doctor: Optional[str] = None
    treatment: Optional[str] = None
    treatment_subtype: Optional[str] = None
    procedure_date: Optional[date] = None
    procedure_time: Optional[time] = None
    procedure_completed: Optional[bool] = None   # <-- Added this line

    model_config = ConfigDict(from_attributes=True)

class PatientPublic(BaseModel):
    id: int
    name: str
    dob: date
    gender: str
    phone: str
    email: EmailStr
    username: str

    # Persistent onboarding/treatment fields
    department: Optional[str] = None
    doctor: Optional[str] = None
    treatment: Optional[str] = None
    treatment_subtype: Optional[str] = None
    procedure_date: Optional[date] = None
    procedure_time: Optional[time] = None
    procedure_completed: Optional[bool] = None   # <-- Added this line

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

class FeedbackCreate(BaseModel):
    message: str

class FeedbackResponse(BaseModel):
    message: str
    status: str = "success"

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
# ✅ Progress Schemas
# -------------------

class ProgressCreate(BaseModel):
    message: str

class ProgressEntry(BaseModel):
    id: int
    message: str
    timestamp: datetime

    model_config = ConfigDict(from_attributes=True)

# -------------------
# ✅ Instruction Status Schemas
# -------------------

class InstructionStatusItem(BaseModel):
    date: date
    treatment: str
    subtype: Optional[str] = None
    group: str        # "dos" or "donts"
    instruction_index: int
    instruction_text: str
    followed: bool

class InstructionStatusBulkCreate(BaseModel):
    items: List[InstructionStatusItem]

class InstructionStatusResponse(InstructionStatusItem):
    id: int
    patient_id: int

    model_config = ConfigDict(from_attributes=True)

# -------------------
# ✅ Department/Doctor Selection Schemas (NEW)
# -------------------

class DepartmentDoctorSelection(BaseModel):
    department: str
    doctor: str

# -------------------
# ✅ TreatmentInfo Schemas (NEW)
# -------------------

class TreatmentInfoCreate(BaseModel):
    username: str
    treatment: str
    subtype: Optional[str] = None
    procedure_date: date
    procedure_time: time

class TreatmentInfoResponse(BaseModel):
    id: int
    patient_id: int
    treatment: str
    subtype: Optional[str] = None
    procedure_date: date
    procedure_time: time

    model_config = ConfigDict(from_attributes=True)