from dataclasses import dataclass
from typing import Optional
import logging

logger = logging.getLogger(__name__)

@dataclass
class HasilML:
    penyakit: str
    confidence: float
    semua_skor: dict

class MLService:
    """ML inference service. Disabled jika torch tidak terinstall."""

    def __init__(self):
        self._available = False
        try:
            import torch  # noqa: F401
            self._available = True
        except ImportError:
            logger.info("torch tidak terinstall — ML inference dinonaktifkan, hanya Fuzzy Mamdani yang aktif.")

    def predict(self, image_bytes: bytes) -> Optional[HasilML]:
        if not self._available:
            return None
        # Import di sini supaya tidak error saat torch tidak ada
        from app.services.ml._classifier_impl import predict_impl
        return predict_impl(image_bytes)

ml_service = MLService()
