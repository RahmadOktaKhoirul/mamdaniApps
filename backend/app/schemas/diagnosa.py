from pydantic import BaseModel, Field
from typing import Optional
from uuid import UUID
from datetime import datetime

class GejalaRequest(BaseModel):
    tingkat_kekuningan: float = Field(..., ge=0, le=10)
    luas_bercak: float        = Field(..., ge=0, le=10)
    kondisi_batang: float     = Field(..., ge=0, le=10)
    pertumbuhan_terhambat: float = Field(..., ge=0, le=10)

class DiagnosaRequest(BaseModel):
    gejala: GejalaRequest
    foto_url: Optional[str] = None  # diisi setelah upload foto ke Storage

class DiagnosaResponse(BaseModel):
    id: UUID
    penyakit: str
    confidence: float
    metode: str
    semua_skor: dict
    treatment: Optional[str] = None
    created_at: datetime

class RiwayatItem(BaseModel):
    id: UUID
    penyakit_nama: str
    confidence_final: float
    metode: str
    foto_url: Optional[str]
    created_at: datetime
