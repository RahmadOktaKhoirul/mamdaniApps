from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1.endpoints import diagnosa
from app.core.config import settings

app = FastAPI(title="Sawit Diagnosa API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_methods=["GET", "POST"],
    allow_headers=["Authorization", "Content-Type"],
)

app.include_router(diagnosa.router, prefix="/api/v1/diagnosa", tags=["diagnosa"])
app.include_router(diagnosa.riwayat_router, prefix="/api/v1/riwayat", tags=["riwayat"])

@app.get("/")
def root():
    return {"status": "ok", "message": "Sawit Diagnosa API"}
