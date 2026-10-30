# Benchmark de latence — german-credit, modèle v12

1000 appels par backend, après 10 appels de chauffe · x86_64 · Python 3.12.15

| Backend | P50 (ms) | P95 (ms) | P99 (ms) |
|---|---|---|---|
| sklearn_pipeline | 3.510 | 4.314 | 4.990 |
| onnx_python | 0.076 | 0.098 | 0.153 |
| onnx_batch_100 | 0.288 | 0.387 | 0.571 |

Accélération ONNX vs scikit-learn (P50, 1 ligne) : x46.4
