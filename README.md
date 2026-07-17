<h1><span style="color:#ff66b2">AfriMarket</span></h1>

<h2><span style="color:#4da6ff">Projet Python d'analyse et de visualisation pour un e-commerce panafricain</span></h2>

## Présentation
Ce projet contient un pipeline de préparation des données, une analyse exploratoire et un dashboard interactif Streamlit pour explorer les performances commerciales d'AfriMarket.

## Contenu principal
- `data_pipeline.py` : pipeline de nettoyage, d'audit et de feature engineering.
- `Analyse_AfriMarket.ipynb` : notebook d'analyse détaillée et de visualisation.
- `dashboard_afrimarket.py` : application Streamlit interactive.
- `afrimarket_dataset_senior.csv` : jeu de données principal.
- `requirements.txt` : dépendances Python.
- `scripts/` : scripts auxiliaires pour le nettoyage, l'audit et la génération de rapports.

## Installation
1. Créez un environnement virtuel Python.
2. Activez l'environnement.
3. Installez les dépendances :

```bash
pip install -r requirements.txt
```

## Usage
### Lancer le dashboard Streamlit
```bash
streamlit run dashboard_afrimarket.py
```

### Lancer le notebook
Ouvrez `Analyse_AfriMarket.ipynb` dans Jupyter Lab / Jupyter Notebook.

## Structure des dossiers
- `figures/` : visualisations et graphiques générés.
- `scripts/` : scripts de traitement et génération d'analyses.
- `resultats_analyses*.json` : sorties de rapports et métriques.

## Notes
- Le dashboard utilise `data_pipeline.get_full_dataset()` pour charger et préparer les données.
- Le projet est conçu pour fonctionner avec Python 3.11+ et les bibliothèques listées dans `requirements.txt`.

## Licence
Aucune licence explicite n'est fournie dans le projet.
