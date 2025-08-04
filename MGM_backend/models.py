from sqlalchemy import Column, Integer, String, Date, DateTime, ForeignKey, Boolean, Time
from sqlalchemy.orm import relationship
from database import Base
from datetime import datetime

# ✅ Patient Table
class Patient(Base):
    __tablename__ = "patients"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, index=True)
    dob = Column(Date, nullable=False)
    gender = Column(String, nullable=False)
    phone = Column(String, unique=True, nullable=False)
    email = Column(String, unique=True, nullable=False)
    username = Column(String, unique=True, index=True, nullable=False)
    password = Column(String, nullable=False)

    # Persistent onboarding/treatment fields
    department = Column(String, nullable=True)
    doctor = Column(String, nullable=True)
    treatment = Column(String, nullable=True)
    treatment_subtype = Column(String, nullable=True)
    procedure_date = Column(Date, nullable=True)
    procedure_time = Column(Time, nullable=True)
    procedure_completed = Column(Boolean, nullable=True, default=None)  # <-- Added for new feature

    appointments = relationship("Appointment", back_populates="patient", cascade="all, delete-orphan")
    feedbacks = relationship("Feedback", back_populates="patient", cascade="all, delete-orphan")
    doctor_feedbacks = relationship("DoctorFeedback", back_populates="patient", cascade="all, delete-orphan")
    progress_entries = relationship("Progress", back_populates="patient", cascade="all, delete-orphan")
    instruction_statuses = relationship("InstructionStatus", back_populates="patient", cascade="all, delete-orphan")
    # REMOVE treatment_infos, we don't want to use the separate treatment_info table for live onboarding/treatment storage

# ✅ Doctor Table
class Doctor(Base):
    __tablename__ = "doctors"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, index=True)
    specialty = Column(String, nullable=False)
    username = Column(String, unique=True, index=True, nullable=False)
    password = Column(String, nullable=False)

    appointments = relationship("Appointment", back_populates="doctor", cascade="all, delete-orphan")
    doctor_feedbacks = relationship("DoctorFeedback", back_populates="doctor", cascade="all, delete-orphan")

# ✅ Appointment Table
class Appointment(Base):
    __tablename__ = "appointments"

    id = Column(Integer, primary_key=True, index=True)
    patient_id = Column(Integer, ForeignKey("patients.id"), nullable=False)
    doctor_id = Column(Integer, ForeignKey("doctors.id"), nullable=False)
    appointment_time = Column(DateTime, nullable=False)

    patient = relationship("Patient", back_populates="appointments")
    doctor = relationship("Doctor", back_populates="appointments")

# ✅ Feedback Table (Patient -> Hospital)
class Feedback(Base):
    __tablename__ = "feedback"

    id = Column(Integer, primary_key=True, index=True)
    patient_id = Column(Integer, ForeignKey("patients.id"), nullable=False)
    message = Column(String, nullable=False)

    patient = relationship("Patient", back_populates="feedbacks")

# ✅ DoctorFeedback Table (Doctor -> Patient)
class DoctorFeedback(Base):
    __tablename__ = "doctor_feedback"

    id = Column(Integer, primary_key=True, index=True)
    doctor_id = Column(Integer, ForeignKey("doctors.id"), nullable=False)
    patient_id = Column(Integer, ForeignKey("patients.id"), nullable=False)
    message = Column(String, nullable=False)

    doctor = relationship("Doctor", back_populates="doctor_feedbacks")
    patient = relationship("Patient", back_populates="doctor_feedbacks")

# ✅ Progress Table (Patient recovery feedback)
class Progress(Base):
    __tablename__ = "progress"

    id = Column(Integer, primary_key=True, index=True)
    patient_id = Column(Integer, ForeignKey("patients.id"), nullable=False)
    message = Column(String, nullable=False)
    timestamp = Column(DateTime, default=datetime.utcnow)

    patient = relationship("Patient", back_populates="progress_entries")

# ✅ InstructionStatus Table (NEW)
class InstructionStatus(Base):
    __tablename__ = "instruction_status"

    id = Column(Integer, primary_key=True, index=True)
    patient_id = Column(Integer, ForeignKey("patients.id"), nullable=False)
    date = Column(Date, nullable=False)
    treatment = Column(String, nullable=False)
    subtype = Column(String, nullable=True)
    group = Column(String, nullable=False)  # e.g., "dos" or "donts"
    instruction_index = Column(Integer, nullable=False)
    instruction_text = Column(String, nullable=False)
    followed = Column(Boolean, default=False)

    patient = relationship("Patient", back_populates="instruction_statuses")

# Remove TreatmentInfo Table for main onboarding/treatment storage!
# If you want to keep historical records, you can keep this table,
# but for current onboarding/treatment info, use the Patient table only.