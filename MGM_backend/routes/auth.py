from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, EmailStr
import random
from typing import Optional
from models import Patient, Doctor  # Adjust import if needed
from database import get_db  # Adjust import if needed
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

# In-memory store for OTPs (for demo; use DB or cache for production)
otp_store = {}

router = APIRouter()

class RequestResetSchema(BaseModel):
    email: Optional[EmailStr] = None
    phone: Optional[str] = None

class VerifyOtpSchema(BaseModel):
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    otp: str
    new_password: str

@router.post("/auth/request-reset")
async def request_reset(data: RequestResetSchema, db: AsyncSession = Depends(get_db)):
    target = data.email or data.phone
    if not target:
        raise HTTPException(status_code=400, detail="Email or phone required.")

    # Find user by email or phone (check Patient then Doctor)
    user = None
    if data.email:
        stmt = select(Patient).where(Patient.email == data.email)
        result = await db.execute(stmt)
        user = result.scalars().first()
        if not user:
            stmt = select(Doctor).where(Doctor.email == data.email)
            result = await db.execute(stmt)
            user = result.scalars().first()
    else:
        stmt = select(Patient).where(Patient.phone == data.phone)
        result = await db.execute(stmt)
        user = result.scalars().first()
        if not user:
            stmt = select(Doctor).where(Doctor.phone == data.phone)
            result = await db.execute(stmt)
            user = result.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")

    otp = str(random.randint(100000, 999999))
    otp_store[target] = otp

    # --- Send OTP via email or SMS here ---
    try:
        if data.email:
            from utils import send_email
            send_email(data.email, "Your OTP", f"Your OTP code is {otp}")
        else:
            print(f"Send SMS to {data.phone}: OTP code is {otp}")
    except Exception as e:
        print(f"Failed to send OTP: {e}")
        raise HTTPException(status_code=500, detail="Failed to send OTP. Please try again later.")

    return {"message": "OTP sent"}

@router.post("/auth/verify-otp")
async def verify_otp(data: VerifyOtpSchema, db: AsyncSession = Depends(get_db)):
    target = data.email or data.phone
    if not target:
        raise HTTPException(status_code=400, detail="Email or phone required.")

    expected_otp = otp_store.get(target)
    if not expected_otp or data.otp != expected_otp:
        raise HTTPException(status_code=400, detail="Invalid OTP.")

    # Find user (check Patient then Doctor)
    user = None
    if data.email:
        stmt = select(Patient).where(Patient.email == data.email)
        result = await db.execute(stmt)
        user = result.scalars().first()
        if not user:
            stmt = select(Doctor).where(Doctor.email == data.email)
            result = await db.execute(stmt)
            user = result.scalars().first()
    else:
        stmt = select(Patient).where(Patient.phone == data.phone)
        result = await db.execute(stmt)
        user = result.scalars().first()
        if not user:
            stmt = select(Doctor).where(Doctor.phone == data.phone)
            result = await db.execute(stmt)
            user = result.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")

    # Update password (assume set_password hashes it)
    user.set_password(data.new_password)
    await db.commit()

    # Remove OTP after use
    del otp_store[target]

    return {"message": "Password reset successful"}