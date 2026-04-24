import os
import uuid
import logging
from fastapi import APIRouter, HTTPException, Header, UploadFile, File
from typing import Optional
from uuid import UUID

from app.schemas.diagnosa import DiagnosaRequest, DiagnosaResponse, RiwayatItem
from app.services.fuzzy.mamdani import diagnosa_fuzzy, GejalaInput
from app.services.ml.classifier import ml_service
from app.core.supabase import supabase

logger = logging.getLogger(__name__)

router = APIRouter()
riwayat_router = APIRouter()

ML_WEIGHT    = 0.6
FUZZY_WEIGHT = 0.4

def _get_user_id(authorization: str) -> str:
    token = authorization.replace("Bearer ", "")
    user = supabase.auth.get_user(token)
    if not user or not user.user:
        raise HTTPException(status_code=401, detail="Token tidak valid")
    return user.user.id

def _get_treatment(penyakit_nama: str) -> Optional[str]:
    if penyakit_nama == "Tidak Terdeteksi":
        return None
    res = supabase.table("penyakit").select("treatment").eq("nama", penyakit_nama).maybeSingle().execute()
    return res.data["treatment"] if res.data else None

def _hybrid_score(fuzzy_skor: dict, ml_skor: dict) -> tuple[str, float, dict]:
    all_keys = set(fuzzy_skor) | set(ml_skor)
    combined = {
        k: round(fuzzy_skor.get(k, 0) * FUZZY_WEIGHT + ml_skor.get(k, 0) * ML_WEIGHT, 2)
        for k in all_keys
    }
    penyakit   = max(combined, key=combined.get)
    confidence = combined[penyakit]
    return penyakit, confidence, combined

@router.post("/", response_model=DiagnosaResponse)
def buat_diagnosa(body: DiagnosaRequest, authorization: str = Header(...)):
    user_id = _get_user_id(authorization)

    hasil_fuzzy = diagnosa_fuzzy(GejalaInput(
        tingkat_kekuningan=body.gejala.tingkat_kekuningan,
        luas_bercak=body.gejala.luas_bercak,
        kondisi_batang=body.gejala.kondisi_batang,
        pertumbuhan_terhambat=body.gejala.pertumbuhan_terhambat,
    ))

    metode           = "fuzzy"
    confidence_ml    = None
    penyakit_final   = hasil_fuzzy.penyakit
    confidence_final = hasil_fuzzy.confidence
    semua_skor_final = hasil_fuzzy.semua_skor

    if body.foto_url:
        try:
            path       = body.foto_url.split("/foto-diagnosa/")[-1]
            foto_bytes = supabase.storage.from_("foto-diagnosa").download(path)
            hasil_ml   = ml_service.predict(foto_bytes)
            confidence_ml = hasil_ml.confidence
            penyakit_final, confidence_final, semua_skor_final = _hybrid_score(
                hasil_fuzzy.semua_skor, hasil_ml.semua_skor
            )
            metode = "hybrid"
        except Exception as e:
            logger.warning("ML inference gagal, fallback ke fuzzy: %s", e)

    res = supabase.table("riwayat_diagnosa").insert({
        "user_id": user_id,
        "penyakit_nama": penyakit_final,
        "confidence_fuzzy": hasil_fuzzy.confidence,
        "confidence_ml": confidence_ml,
        "confidence_final": confidence_final,
        "metode": metode,
        "foto_url": body.foto_url,
        "semua_skor": semua_skor_final,
    }).execute()

    if not res.data:
        raise HTTPException(status_code=500, detail="Gagal menyimpan diagnosa")

    diagnosa_id = res.data[0]["id"]

    supabase.table("gejala_input").insert({
        "diagnosa_id": diagnosa_id,
        "tingkat_kekuningan": body.gejala.tingkat_kekuningan,
        "luas_bercak": body.gejala.luas_bercak,
        "kondisi_batang": body.gejala.kondisi_batang,
        "pertumbuhan_terhambat": body.gejala.pertumbuhan_terhambat,
    }).execute()

    return DiagnosaResponse(
        id=diagnosa_id,
        penyakit=penyakit_final,
        confidence=confidence_final,
        metode=metode,
        semua_skor=semua_skor_final,
        treatment=_get_treatment(penyakit_final),
        created_at=res.data[0]["created_at"],
    )

@router.post("/upload-foto")
async def upload_foto(file: UploadFile = File(...), authorization: str = Header(...)):
    _get_user_id(authorization)

    ext = os.path.splitext(file.filename)[-1].lower()
    if ext not in {".jpg", ".jpeg", ".png", ".webp"}:
        raise HTTPException(status_code=400, detail="Format file tidak didukung")

    contents = await file.read()
    if len(contents) > 5 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="Ukuran file maksimal 5MB")

    path = f"{uuid.uuid4()}{ext}"
    supabase.storage.from_("foto-diagnosa").upload(path, contents, {"content-type": file.content_type})
    url = supabase.storage.from_("foto-diagnosa").get_public_url(path)
    return {"foto_url": url}

@riwayat_router.get("/", response_model=list[RiwayatItem])
def get_riwayat(authorization: str = Header(...)):
    user_id = _get_user_id(authorization)
    res = supabase.table("riwayat_diagnosa") \
        .select("id, penyakit_nama, confidence_final, metode, foto_url, created_at") \
        .eq("user_id", user_id) \
        .order("created_at", desc=True) \
        .execute()
    return res.data or []

@router.get("/{diagnosa_id}", response_model=DiagnosaResponse)
def get_detail_diagnosa(diagnosa_id: UUID, authorization: str = Header(...)):
    user_id = _get_user_id(authorization)
    res = supabase.table("riwayat_diagnosa") \
        .select("*") \
        .eq("id", str(diagnosa_id)) \
        .eq("user_id", user_id) \
        .single() \
        .execute()
    if not res.data:
        raise HTTPException(status_code=404, detail="Diagnosa tidak ditemukan")
    d = res.data
    return DiagnosaResponse(
        id=d["id"],
        penyakit=d["penyakit_nama"],
        confidence=d["confidence_final"],
        metode=d["metode"],
        semua_skor=d["semua_skor"] or {},
        treatment=_get_treatment(d["penyakit_nama"]),
        created_at=d["created_at"],
    )

@router.get("/penyakit/list")
def get_penyakit():
    res = supabase.table("penyakit").select("kode, nama, deskripsi, gejala_umum, treatment").execute()
    return res.data or []
