from fastapi.testclient import TestClient
from app.main import app
from app.services.fuzzy.mamdani import diagnosa_fuzzy, GejalaInput

client = TestClient(app)


def test_health():
    res = client.get("/")
    assert res.status_code == 200
    assert res.json()["status"] == "ok"


def test_fuzzy_ganoderma():
    """Kondisi batang parah + kekuningan tinggi → Ganoderma."""
    hasil = diagnosa_fuzzy(GejalaInput(
        tingkat_kekuningan=8.0,
        luas_bercak=3.0,
        kondisi_batang=9.0,
        pertumbuhan_terhambat=7.0,
    ))
    assert hasil.penyakit == "Ganoderma"
    assert hasil.confidence > 0


def test_fuzzy_tidak_terdeteksi():
    """Semua gejala rendah → Tidak Terdeteksi."""
    hasil = diagnosa_fuzzy(GejalaInput(
        tingkat_kekuningan=0.0,
        luas_bercak=0.0,
        kondisi_batang=0.0,
        pertumbuhan_terhambat=0.0,
    ))
    assert hasil.penyakit == "Tidak Terdeteksi"


def test_fuzzy_semua_skor_lengkap():
    """Output semua_skor harus berisi 6 penyakit."""
    hasil = diagnosa_fuzzy(GejalaInput(
        tingkat_kekuningan=5.0,
        luas_bercak=5.0,
        kondisi_batang=5.0,
        pertumbuhan_terhambat=5.0,
    ))
    assert len(hasil.semua_skor) == 6


def test_penyakit_list_endpoint():
    res = client.get("/api/v1/diagnosa/penyakit/list")
    assert res.status_code == 200
