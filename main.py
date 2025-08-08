# Root shim so 'uvicorn main:app' works on Render
from MGM_backend.main import app  # re-export FastAPI app