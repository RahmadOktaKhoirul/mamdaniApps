import numpy as np
import skfuzzy as fuzz
from skfuzzy import control as ctrl
from dataclasses import dataclass

@dataclass
class GejalaInput:
    tingkat_kekuningan: float    # 0-10
    luas_bercak: float           # 0-10
    kondisi_batang: float        # 0-10
    pertumbuhan_terhambat: float # 0-10

@dataclass
class HasilFuzzy:
    penyakit: str
    confidence: float            # 0-100
    semua_skor: dict

PENYAKIT_CONFIG = {
    "Ganoderma": {
        "bobot": {"kondisi_batang": 0.5, "tingkat_kekuningan": 0.3, "pertumbuhan_terhambat": 0.2},
        "threshold": 5.5,
    },
    "Blight": {
        "bobot": {"luas_bercak": 0.5, "tingkat_kekuningan": 0.4, "pertumbuhan_terhambat": 0.1},
        "threshold": 5.0,
    },
    "Crown Disease": {
        "bobot": {"pertumbuhan_terhambat": 0.5, "tingkat_kekuningan": 0.3, "kondisi_batang": 0.2},
        "threshold": 5.0,
    },
    "Pestalotiopsis": {
        "bobot": {"luas_bercak": 0.6, "tingkat_kekuningan": 0.3, "kondisi_batang": 0.1},
        "threshold": 4.5,
    },
    "Basal Stem Rot": {
        "bobot": {"kondisi_batang": 0.7, "pertumbuhan_terhambat": 0.2, "tingkat_kekuningan": 0.1},
        "threshold": 6.0,
    },
    "Spear Rot": {
        "bobot": {"pertumbuhan_terhambat": 0.6, "kondisi_batang": 0.3, "luas_bercak": 0.1},
        "threshold": 5.5,
    },
}

def _build_fuzzy_system() -> ctrl.ControlSystemSimulation:
    """Build reusable fuzzy control system."""
    x = np.arange(0, 11, 0.1)

    # Antecedents
    kekuningan = ctrl.Antecedent(x, "kekuningan")
    bercak     = ctrl.Antecedent(x, "bercak")
    batang     = ctrl.Antecedent(x, "batang")
    terhambat  = ctrl.Antecedent(x, "terhambat")
    skor       = ctrl.Consequent(x, "skor")

    for var in [kekuningan, bercak, batang, terhambat]:
        var["rendah"]  = fuzz.trimf(var.universe, [0, 0, 5])
        var["sedang"]  = fuzz.trimf(var.universe, [2, 5, 8])
        var["tinggi"]  = fuzz.trimf(var.universe, [5, 10, 10])

    skor["rendah"]  = fuzz.trimf(skor.universe, [0, 0, 4])
    skor["sedang"]  = fuzz.trimf(skor.universe, [3, 5, 7])
    skor["tinggi"]  = fuzz.trimf(skor.universe, [6, 10, 10])

    rules = [
        ctrl.Rule(batang["tinggi"] & kekuningan["tinggi"], skor["tinggi"]),
        ctrl.Rule(bercak["tinggi"] & kekuningan["sedang"], skor["tinggi"]),
        ctrl.Rule(terhambat["tinggi"] & batang["sedang"], skor["tinggi"]),
        ctrl.Rule(bercak["sedang"] & kekuningan["sedang"], skor["sedang"]),
        ctrl.Rule(batang["sedang"] & terhambat["sedang"], skor["sedang"]),
        ctrl.Rule(kekuningan["rendah"] & bercak["rendah"], skor["rendah"]),
        ctrl.Rule(batang["rendah"] & terhambat["rendah"], skor["rendah"]),
    ]

    system = ctrl.ControlSystem(rules)
    return ctrl.ControlSystemSimulation(system)

def _fuzzy_score(gejala: GejalaInput) -> float:
    """Get base fuzzy output score — new sim instance per call (thread-safe)."""
    sim = _build_fuzzy_system()
    sim.input["kekuningan"] = gejala.tingkat_kekuningan
    sim.input["bercak"]     = gejala.luas_bercak
    sim.input["batang"]     = gejala.kondisi_batang
    sim.input["terhambat"]  = gejala.pertumbuhan_terhambat
    sim.compute()
    return float(sim.output["skor"])

def _disease_score(gejala: GejalaInput, config: dict, base_score: float) -> float:
    """Weighted score per disease using fuzzy base + disease-specific weights."""
    gejala_map = {
        "tingkat_kekuningan": gejala.tingkat_kekuningan,
        "luas_bercak": gejala.luas_bercak,
        "kondisi_batang": gejala.kondisi_batang,
        "pertumbuhan_terhambat": gejala.pertumbuhan_terhambat,
    }
    weighted = sum(gejala_map[k] * v for k, v in config["bobot"].items())
    return (base_score * 0.4) + (weighted * 0.6)

def diagnosa_fuzzy(gejala: GejalaInput) -> HasilFuzzy:
    base_score = _fuzzy_score(gejala)

    skor_penyakit = {
        nama: _disease_score(gejala, cfg, base_score)
        for nama, cfg in PENYAKIT_CONFIG.items()
    }

    # Normalize to confidence 0-100
    max_skor = max(skor_penyakit.values())
    total    = sum(skor_penyakit.values())
    confidence_map = {k: round((v / total) * 100, 2) for k, v in skor_penyakit.items()}

    penyakit_terdeteksi = max(skor_penyakit, key=skor_penyakit.get)
    threshold = PENYAKIT_CONFIG[penyakit_terdeteksi]["threshold"]

    if max_skor < threshold:
        penyakit_terdeteksi = "Tidak Terdeteksi"

    return HasilFuzzy(
        penyakit=penyakit_terdeteksi,
        confidence=confidence_map.get(penyakit_terdeteksi, 0.0),
        semua_skor=confidence_map,
    )
