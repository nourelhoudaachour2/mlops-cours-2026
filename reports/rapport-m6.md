# Rapport — Lab 6 : CI/CD/CT

**Binôme :** Nour El Houda Achour et Mohamed Amine Mrad
**Dataset :** german-credit
**Champion :** v13

## 1. Architecture

Notre projet utilise GitHub Actions pour tester le code et publier les images Docker sur GHCR. Argo CD récupère les modifications depuis Git et déploie les modèles avec KServe.

Pour le ré-entraînement, Evidently détecte une dérive, puis le webhook déclenche un pipeline Kubeflow. MLflow conserve les modèles et leurs résultats.

**Flux :**
Evidently → Webhook → KFP → MLflow → GitHub Actions → GHCR → Argo CD → KServe.

## 2. Temps du cycle

| Étape | Durée |
|---|---|
| Détection → lancement KFP | ~1 s |
| Ré-entraînement KFP | ~3 min 48 s |
| Commit du modèle → mise à jour Git staging | 1 min 57 s |
| Publication image → staging servi | Non mesurée |
| Canary 10 % → promotion Git 100 % | 54 s |
| **Cycle complet observé** | **Plus de 39 min** |

Le cycle a pris davantage de temps à cause d'un problème d'accès aux artefacts MLflow/S3, que nous avons corrigé avant de poursuivre.

## 3. Gates et décisions

Evidently a détecté une dérive de 15 % sur les variables `duration`, `credit_amount` et `age`.

| Indicateur | Ancien modèle v12 | Nouveau modèle v13 |
|---|---|---|
| ROC AUC | 0.8050 | 0.8094 |
| Coût métier | 124 | 108 |

Le nouveau modèle a passé les deux critères de validation. Il a donc été promu dans MLflow.

Nous l'avons ensuite testé avec un canary de 10 %, avant de passer à 100 % du trafic en production.

## 4. Points d'attention

Le webhook est protégé par un jeton enregistré dans `.env`. Pour une utilisation réelle, il faudrait renforcer la sécurité, mieux gérer les secrets et prévoir une validation humaine avant certaines promotions.

En cas de problème, GitOps et KServe permettent de revenir à la version précédente.

## 5. Différences avec la production

Pour améliorer notre solution, nous pourrions automatiser davantage les déploiements, ajouter une supervision continue et utiliser des données récentes et fiables.

Il serait aussi préférable d'utiliser des pull requests pour valider les changements importants.

## 6. Captures d'écran

- Argo CD : applications Synced et Healthy.
- KFP : pipeline CT réussi et gate de promotion.
- GitHub Actions : CI réussie.
- KServe : canary 10 %, puis promotion 100 %.

## Conclusion

Nous avons réussi à connecter les différentes étapes CI/CD/CT. Après la détection d'une dérive, le modèle a été ré-entraîné et validé.

La version 13 a finalement été déployée en production avec 100 % du trafic. Cette expérience nous a permis de mieux comprendre l'automatisation du cycle de vie d'un modèle ML.
