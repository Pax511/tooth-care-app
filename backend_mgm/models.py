from sqlalchemy import Column, Integer, String, Date, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from database import Base

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

    appointments = relationship("Appointment", back_populates="patient", cascade="all, delete-orphan")
    feedbacks = relationship("Feedback", back_populates="patient", cascade="all, delete-orphan")
    doctor_feedbacks = relationship("DoctorFeedback", back_populates="patient", cascade="all, delete-orphan")

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
