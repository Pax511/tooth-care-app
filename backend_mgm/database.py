import os
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker, declarative_base
from dotenv import load_dotenv

# ✅ Load environment variables from .env file
load_dotenv()

# ✅ Read database connection details from environment
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT", "5432")  # PostgreSQL default port
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")

# ✅ Ensure all required variables are set
required_vars = [DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD]
if not all(required_vars):
    raise EnvironmentError("⚠️ One or more required DB environment variables are missing.")

# ✅ Construct database URL for asyncpg
DATABASE_URL = f"postgresql+asyncpg://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

# ✅ Create async SQLAlchemy engine
engine = create_async_engine(DATABASE_URL, echo=True, future=True)

# ✅ Configure async session factory
AsyncSessionLocal = sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
    autocommit=False,
)

# ✅ Base class for SQLAlchemy models
Base = declarative_base()

# ✅ Dependency for FastAPI routes to access DB session
async def get_db():
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()