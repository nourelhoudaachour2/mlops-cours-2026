# Rapport — Lab 5 : serving avec KServe

Binôme : Amine · Dataset : german-credit · Modèle : scoring-model v12 · Seuil servi : 0.3182

## 1. Résumé

On a déployé l'image du Lab 4 (FastAPI + ONNX) sur KServe en mode Knative, derrière la
passerelle Kourier (localhost:30080). L'autoscaling suit le débit : de 0 à 5 pods, cible de
200 requêtes/s par pod. À la fin du lab, la version 2.0.0 sert 100 % du trafic, après un
canary 90/10.

## 2. Benchmark de latence

| Run | Requêtes | RPS | P50 (ms) | P95 (ms) | P99 (ms) | Erreurs (%) |
|---|---|---|---|---|---|---|
| run_100 | 54272 | 469.6 | 8 | 31 | 74 | 0.00 |
| run_500 | 169971 | 978.6 | 240 | 380 | 470 | 0.00 |
| run_1000 | 215413 | 1234.8 | 620 | 910 | 1100 | 0.00 |

Point de saturation : autour de 1000 req/s avec 5 pods. Entre 500 et 1000 utilisateurs, le
débit ne gagne que 26 %, mais le P99 passe de 470 à 1100 ms. Locust a aussi signalé un CPU
élevé : les chiffres sont probablement un peu en dessous du vrai plafond.

## 3. Scale-up observé

| Run | Pods (max observé) | CPU moyen par pod | Temps pour atteindre ce nombre de pods |
|---|---|---|---|
| run_100 | 5 | 520 m | 38 s |
| run_500 | 5 | 544 m | 20 s |
| run_1000 | 5 | 696 m | 0 s (déjà 5 pods au départ) |

Scale-to-zero : environ 100 s sans trafic avant 0 pod. Démarrage à froid : 3.77 s (puis
0.005 s pour l'appel suivant).

## 4. Analyse canary

- Sur 200 requêtes : 186 × 1.0.0 et 14 × 2.0.0.
- C'est cohérent avec 90/10 : on attendait 180 / 20, l'écart de 6 reste dans la variance normale.
- Petit incident : au début, une dizaine de requêtes sur 200 échouaient, car la passerelle
  gardait d'anciennes adresses de pods. Redémarrer le contrôleur net-kourier-controller a
  réglé le problème.
- Décision : promotion à 100 %. Même modèle (v12), même seuil, plus d'erreurs après la
  correction. La décision reste manuelle.

## 5. Points d'amélioration

- Mieux répartir la charge de test (plusieurs processus ou une autre machine) pour mesurer le
  vrai plafond.
- Tester plusieurs workers uvicorn ou le batching : un seul worker est probablement le goulot.
- Monter maxReplicas ou baisser la cible de l'autoscaler pour réagir plus tôt.
- Garder minReplicas à 1 en journée pour éviter les 3.8 s de démarrage à froid.
