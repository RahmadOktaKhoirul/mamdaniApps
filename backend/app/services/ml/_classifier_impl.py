import json
import threading
import torch
import torch.nn as nn
from torchvision import transforms
from torchvision.models import efficientnet_b0
from PIL import Image
import io
from app.core.config import settings
from app.services.ml.classifier import HasilML

_transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225]),
])

_model = None
_class_map: dict = {}
_lock = threading.Lock()

def _load():
    global _model, _class_map
    if _model is not None:
        return
    with _lock:
        if _model is not None:
            return
        map_path = settings.ML_MODEL_PATH.replace('.pt', '').rsplit('/', 1)[0] + '/class_map.json'
        with open(map_path) as f:
            _class_map = json.load(f)
        num_classes = len(_class_map)
        model = efficientnet_b0()
        in_features = model.classifier[1].in_features
        model.classifier = nn.Sequential(nn.Dropout(0.3), nn.Linear(in_features, num_classes))
        model.load_state_dict(torch.load(settings.ML_MODEL_PATH, map_location='cpu'))
        model.eval()
        _model = model

def predict_impl(image_bytes: bytes) -> HasilML:
    _load()
    img    = Image.open(io.BytesIO(image_bytes)).convert('RGB')
    tensor = _transform(img).unsqueeze(0)
    with torch.no_grad():
        probs = torch.softmax(_model(tensor), dim=1)[0]
    semua_skor = {_class_map[str(i)]: round(float(p) * 100, 2) for i, p in enumerate(probs)}
    penyakit   = max(semua_skor, key=semua_skor.get)
    return HasilML(penyakit=penyakit, confidence=semua_skor[penyakit], semua_skor=semua_skor)
