# AfriMarket

## Projet Python d'analyse et de visualisation pour un e-commerce panafricain

## Présentation
Ce projet contient un pipeline de préparation des données, une analyse exploratoire et un dashboard interactif Streamlit pour explorer les performances commerciales d'AfriMarket.

## Contenu principal
- `data_pipeline.py` : pipeline de nettoyage, d'audit et de feature engineering.
- `Analyse_AfriMarket.ipynb` : notebook d'analyse détaillée et de visualisation.
- `dashboard_afrimarket.py` : application Streamlit interactive.
- `build_notebook.py` / `build_resume_executif.py` : scripts de génération du notebook et du résumé exécutif.
- `afrimarket_dataset_senior.csv` : jeu de données brut.
- `afrimarket_clean.csv` : jeu de données nettoyé, issu du pipeline.
- `resultats_analyses.json` : métriques et résultats d'analyse.
- `Resume_Executif_AfriMarket.docx` / `.pdf` : synthèse exécutive du projet.

## Installation
1. Créez un environnement virtuel Python (3.11+).
2. Activez l'environnement.
3. Installez les bibliothèques utilisées par le projet : `pandas`, `numpy`, `matplotlib`, `seaborn`, `streamlit` (voir les imports en tête de `data_pipeline.py` et `dashboard_afrimarket.py`).

## Usage
### Lancer le dashboard Streamlit
```bash
streamlit run dashboard_afrimarket.py
```

### Lancer le notebook
Ouvrez `Analyse_AfriMarket.ipynb` dans Jupyter Lab / Jupyter Notebook.

## Structure des dossiers
- `figures/` : visualisations et graphiques générés.
- `resultats_analyses.json` : sorties de rapports et métriques.

## Notes
- Le dashboard utilise `data_pipeline.get_full_dataset()` pour charger et préparer les données.
- Le projet est conçu pour fonctionner avec Python 3.11+.

## Licence
Aucune licence explicite n'est fournie dans le projet.
