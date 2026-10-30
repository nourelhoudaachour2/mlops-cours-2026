# Rapport — Lab 4 : packaging du modèle

Binôme : Nour El Houda Achour & Mohamed Amine · Dataset : german-credit · Modèle : `scoring-model` v12

## 1. Comparatif des tailles

| Image | Taille | CVE HIGH + CRITICAL |
|---|---|---|
| `scoring-api:naive` | 2,19 Go | 469 (453 HIGH, 16 CRITICAL) |
| `scoring-api:optimized` | 457 Mo | 44 (44 HIGH, 0 CRITICAL) |
| `scoring-api:bentoml` | 1,41 Go | 122 (121 HIGH, 1 CRITICAL) |

## 2. Comparatif des latences

Source : `reports/benchmark.md` (1000 appels par backend, 10 appels de chauffe, x86_64, Python 3.12).

| Backend | P50 (ms) | P95 (ms) | P99 (ms) |
|---|---|---|---|
| sklearn_pipeline | 3.510 | 4.314 | 4.990 |
| onnx_python | 0.076 | 0.098 | 0.153 |
| onnx_batch_100 | 0.288 | 0.387 | 0.571 |

Accélération ONNX vs scikit-learn (P50, 1 ligne) : x46,4.

## 3. Interprétation

- **Taille de l'image optimisée** : base `python:3.12-slim` au lieu de `python:3.12` complet, build multi-stage (les outils de build restent dans le premier stage), et seulement les dépendances d'inférence (onnxruntime, FastAPI, sans scikit-learn ni SciPy). Résultat : 457 Mo contre 2,19 Go.
- **ONNX plus rapide que scikit-learn** : onnxruntime exécute un graphe statique compilé en C++ et optimisé, alors que le pipeline scikit-learn passe par la couche Python/pandas (imputation, encodage, modèle) à chaque appel. En batch de 100 lignes, un appel coûte 0,288 ms, soit environ 0,003 ms par ligne.
- **Scans** : Trivy montre que moins de paquets signifie moins de CVE (469 pour naive, 122 pour bentoml, 44 pour optimized, aucune CRITICAL). ModelScan ne trouve rien sur l'ONNX, mais ne le lit pas : il est sûr par construction (graphe protobuf sans code). Il détecte bien le pickle piégé (`CRITICAL`, `posix.system`), ce qui montre le risque d'un pickle d'origine non maîtrisée. Le modèle du Registry (skops) n'est pas un pickle, et skops ne signale que `numpy.dtype`, un type inoffensif. Limite : ModelScan 0.8.8 génère des erreurs `_check_version` avec NumPy 2 (sans effet sur le résultat).
- **BentoML** : image plus lourde (1,41 Go), modèle stocké en pickle (`saved_model.pkl`), et renvoie 400 (au lieu de 422) sur une requête invalide.

## 4. Choix recommandé

**`scoring-api:optimized`** (FastAPI + ONNX) : la plus petite (457 Mo, < 500 Mo), la moins vulnérable (44 CVE, 0 CRITICAL), la plus rapide (P50 0,076 ms), non-root avec HEALTHCHECK, schéma d'entrée généré depuis `dataset.yaml` et 422 sur requête invalide. Le modèle ONNX est un format sans code exécutable, contrairement au pickle de BentoML. Elle est taguée `1.0.0` dans le registry local et prête pour KServe (Lab 5).

## 5. Pistes d'amélioration

- Quantization INT8 du modèle ONNX pour réduire encore la latence et la taille.
- Image distroless (ou `python:3.12-slim` épinglée par digest) pour réduire les CVE restantes.
- Préchargement du modèle via un Init Container.
- Scan Trivy automatisé dans la CI (Module 6), avec échec si CVE CRITICAL.
- Mettre à jour régulièrement les paquets Debian et les dépendances (la base de CVE évolue chaque semaine).
