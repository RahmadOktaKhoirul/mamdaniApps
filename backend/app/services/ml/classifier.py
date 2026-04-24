import json
import threading
import torch
import torch.nn as nn
from torchvision import transforms
from torchvision.models import efficientnet_b0
from PIL import Image
import io
from dataclasses import dataclass
from app.core.config import settings

@dataclass
class HasilML:
    penyakit: str
    confidence: float   # 0-100
    semua_skor: dict

_transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225]),
])

class MLService:
    def __init__(self):
        self._model = None
        self._class_map: dict = {}
        self._lock = threading.Lock()

    def _load(self):
        if self._model is not None:
            return
        with self._lock:
            if self._model is not None:  # double-checked locking
                return
            map_path = settings.ML_MODEL_PATH.replace('.pt', '').rsplit('/', 1)[0] + '/class_map.json'
            with open(map_path) as f:
                self._class_map = json.load(f)

            num_classes = len(self._class_map)
            model = efficientnet_b0()
            in_features = model.classifier[1].in_features
            model.classifier = nn.Sequential(
                nn.Dropout(0.3),
                nn.Linear(in_features, num_classes),
            )
            model.load_state_dict(torch.load(settings.ML_MODEL_PATH, map_location='cpu'))
            model.eval()
            self._model = model

    def predict(self, image_bytes: bytes) -> HasilML:
        self._load()
        img = Image.open(io.BytesIO(image_bytes)).convert('RGB')
        tensor = _transform(img).unsqueeze(0)

        with torch.no_grad():
            logits = self._model(tensor)
            probs  = torch.softmax(logits, dim=1)[0]

        semua_skor = {
            self._class_map[str(i)]: round(float(p) * 100, 2)
            for i, p in enumerate(probs)
        }
        penyakit   = max(semua_skor, key=semua_skor.get)
        confidence = semua_skor[penyakit]

        return HasilML(penyakit=penyakit, confidence=confidence, semua_skor=semua_skor)

ml_service = MLService()
