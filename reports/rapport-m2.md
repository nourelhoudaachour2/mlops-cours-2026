# Rapport comparatif — Kubeflow Pipelines vs Airflow (Lab 2)

**Binôme :** Nour El Houda Achour et Mohamed Amine Mrad · **Date :** 26/10/2026 · **Machine :** WSL2 Ubuntu, 15,5 Go de RAM · **Dataset :** german-credit

## 1. Contexte

Nous avons repris le pipeline du Lab 1 et nous l'avons fait tourner avec Kubeflow Pipelines (KFP) et avec Airflow. Il a six étapes : ingest, validate, prepare, train, evaluate, register. Chaque étape est un pod sur notre cluster kind, avec la même image Docker qui contient le code du Lab 1. Le résultat est identique des deux côtés : roc_auc = 0,8094.

## 2. Résultats quantitatifs

| Mesure | KFP | Airflow |
|---|---|---|
| Installation de zéro (min) | non mesuré | non mesuré |
| Temps jusqu'au premier run réussi (min) | non mesuré | non mesuré |
| Durée d'un run complet (min) | 2,1 (3,5 au premier run) | 1,3 |
| Relance avec les mêmes paramètres (min) | 2,1 | 1,3 |
| Hot-reload : modifier un step (min) | non mesuré | non mesuré |
| Lignes de code propres à l'orchestrateur | 282 | 70 |
| Mémoire utilisée (Go) | environ 4,8 (cluster entier) | environ 2,0 (7 conteneurs) |

Le chiffre de mémoire de KFP inclut tout le cluster (MLflow et S3 aussi) : la comparaison n'est pas tout à fait juste.

## 3. Analyse qualitative

### Developer experience

KFP demande plus de code (composants typés), mais l'interface montre directement les métriques, la matrice de confusion et les artefacts. Airflow est plus court (70 lignes), mais ne transporte aucun fichier : nous avons dû passer par S3, et seules de petites valeurs passent par XCom.

### Scaling

Les deux outils lancent un pod par étape. KFP règle mémoire, retries et timeouts dans le pipeline ; Airflow le fait task par task. Le cache de KFP n'a pas réduit la durée dans notre test (2,1 min), car les étapes en cache sont très courtes face à l'entraînement.

### Debugging

Dans KFP, un clic sur une étape donne logs, entrées et sorties. Dans Airflow, les logs sont aussi dans l'interface, mais retrouver un fichier oblige à chercher dans le dossier S3 du run.

### Erreurs rencontrées

- **`make kfp-ui` ne lançait pas le port-forward** : le `pkill` du Makefile tuait la commande `make` elle-même. Solution : lancer le `kubectl port-forward` directement.
- **Sélecteur de fichier de l'UI KFP sous WSL** : le fichier du projet était difficile à trouver. Solution : envoyer le pipeline avec le SDK Python (`upload_pipeline`).
- **Test MLflow depuis un pod** : avec `--rm -i`, la sortie `b'OK'` n'apparaissait pas. Solution : lancer le pod sans `--rm`, lire les logs, puis le supprimer.
- **Mauvais terminal** : le second terminal n'était ni dans le bon dossier ni dans le venv. Solution : `cd`, `source .venv/bin/activate` et `source .env`.
- **DAG absent de la liste Airflow** : le scan n'était pas encore fait. Solution : `airflow dags reserialize`.
- **DAG déclenché deux fois** (UI et terminal) : deux runs parallèles et deux versions de modèle en plus, sans conséquence.
- **`make check-m2` bloqué** : le check Airflow « live » restait en attente et Ctrl-C ne marchait pas. Solution : `pkill`, puis arrêter Airflow avant de relancer le check.
- **Rapport en échec au check** : le fichier était resté le modèle avec ses champs à remplir, car la commande avait été collée dans un terminal bloqué.

## 4. Recommandation

KFP convient à une équipe ML qui échange beaucoup d'artefacts, car le suivi des données et des modèles est prêt. Airflow convient si l'entreprise l'utilise déjà pour d'autres traitements. Dans les deux cas, une image versionnée garantit le même code partout.

## 5. Limites de la comparaison

Petit dataset, cluster local sans vrai cloud, Airflow en Docker Compose et non sur Kubernetes, pas de KubernetesExecutor. Installation et hot-reload non mesurés, pas de test de charge ni de parallélisme.
