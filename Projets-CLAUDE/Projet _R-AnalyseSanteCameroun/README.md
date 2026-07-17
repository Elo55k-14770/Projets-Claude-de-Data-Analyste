# Analyse Santé Publique — Cameroun

Projet d'analyse de données en R : de la donnée brute (consultations dans des
centres de santé camerounais) au dashboard interactif, en suivant le workflow
complet d'un data analyst (import → exploration → nettoyage → transformation
→ analyse business → visualisation → statistiques descriptives → dashboard →
reporting → recommandations).

## Contenu du dossier

```
R/
├── R - Analyse Santé - Cameroun.docx   énoncé du projet
├── data/
│   ├── raw/consultations_sante_cameroun.csv     données brutes (téléchargées, 10300 lignes)
│   └── clean/
│       ├── consultations_clean.csv              après nettoyage (10011 lignes)
│       └── consultations_enrichi.csv            + variables dérivées (23 colonnes)
├── scripts/
│   ├── 01_import_exploration.R      chargement + diagnostic qualité des données
│   ├── 02_data_cleaning.R           nettoyage (voir hypothèses ci-dessous)
│   ├── 03_transformation.R          variables dérivées
│   ├── 04_analyse_business.R        10 questions métier -> outputs/tables/
│   ├── 05_visualisation.R           10 graphiques ggplot2 -> outputs/plots/
│   └── 06_stats_descriptives.R      moyenne, médiane, écart-type, distribution
├── outputs/
│   ├── tables/                      10 tables business + stats (CSV)
│   └── plots/                       10 graphiques (PNG)
├── app/app.R                        dashboard interactif Shiny
├── README.md                        ce fichier
└── INSIGHTS.md                      synthèse des résultats + recommandations
```

## Source des données

Fichier `consultations_sante_cameroun.csv` téléchargé depuis le lien Google
Drive fourni dans le document Word (10 300 lignes, 12 colonnes : identité du
patient, date et lieu de consultation, âge, genre, diagnostic, coût du
traitement, disponibilité des médicaments, type de consultation, statut
d'assurance). Dataset volontairement "sale", simulé pour l'exercice.

## Comment exécuter

```bash
Rscript scripts/01_import_exploration.R
Rscript scripts/02_data_cleaning.R
Rscript scripts/03_transformation.R
Rscript scripts/04_analyse_business.R
Rscript scripts/05_visualisation.R
Rscript scripts/06_stats_descriptives.R

# Dashboard (depuis le dossier app/) :
R -e "shiny::runApp('app', launch.browser = TRUE)"
```

Packages requis : `tidyverse`, `shiny`, `janitor`, `DT`, `scales` (installés
depuis CRAN pour ce projet).

## Problèmes de qualité détectés et hypothèses de nettoyage

Chaque règle a été vérifiée quantitativement avant application (voir
`scripts/01_import_exploration.R` pour le diagnostic complet).

| Problème | Constat | Traitement retenu |
|---|---|---|
| Doublons | 232 lignes 100% identiques + doublons de saisie sur la clé (patient_id, date) : 289 patient_id concernés au total. 11 patient_id ont de vraies visites répétées à des dates différentes (conservées). | Déduplication sur (patient_id, consultation_date), on garde la 1ère occurrence. |
| Dates incohérentes | Deux formats mélangés dans la même colonne : ISO `YYYY-MM-DD` (10 100 lignes) et `DD/MM/YYYY` (200 lignes). | Détection du format par regex, parsing dédié à chacun. |
| Genre | 8 variantes : Male/male/M/Masculin, Female/female/F/Feminin. | Standardisé sur `Male`/`Female`. Manquant -> `Non renseigné`. |
| Région | Variantes de casse/langue/abréviation sur 3 régions : Sud-Ouest/SW/sud ouest, Littoral/LITTORAL/litoral, Centre/CENTER/Ctr/centre. Les 7 autres régions étaient déjà propres. | Standardisé sur les 10 régions officielles du Cameroun. |
| Région manquante | 518 valeurs manquantes (5.03%). | Imputée via une table de correspondance district → région (1:1 une fois les variantes de région standardisées) : 500 valeurs récupérées, le reste `Non renseigné`. |
| Diagnostic manquant | 800 valeurs manquantes (7.77%), pas de règle fiable pour inférer. | Catégorie explicite `Non renseigné` (non fabriqué). |
| Assurance manquante | 520 valeurs manquantes (5.05%). | Catégorie explicite `Non renseigné`. |
| Âge négatif | Valeur unique -5, 17 lignes. | Mis à `NA` (impossible). |
| Âge > 110 ans | Valeurs sentinelles 140 et 222, 33 lignes. | Mis à `NA` (impossible). |
| Âge == 0 | 537 lignes (5.2%). Distribution quasi uniforme (4.5%-6.3%) sur **tous** les types de consultation, y compris "Prenatal" (femmes enceintes : un patient de 0 an n'a cliniquement aucun sens). | Traité comme sentinelle de valeur manquante -> `NA`, pas comme nourrissons réels. |
| Coût négatif | 16 lignes. | Mis à `NA` (impossible). |
| Coût sentinelle | Exactement 9999 (20 lignes) et 50000 (14 lignes), alors que la distribution normale va de ~2 à ~45. Deux valeurs rondes répétées à l'identique = codes d'erreur de saisie, pas des coûts réels. | Mis à `NA`. |
| Coût déjà manquant | 516 lignes (5.01%). | Conservé `NA`, **non imputé** : les analyses financières l'excluent explicitement (`cout_connu`) plutôt que de fabriquer une valeur. |

Après nettoyage : **10 011 lignes** (289 doublons supprimés sur 10 300), 0
valeur région manquante, catégories 100% cohérentes.

## Variables dérivées (transformation)

`consultations_enrichi.csv` ajoute : `annee`, `mois`, `mois_num`,
`trimestre`, `jour_semaine`, `tranche_age` (0-4, 5-14, 15-24, 25-44, 45-64,
65+), `rupture_stock` (booléen), `est_urgence`, `est_assure`, `cout_connu`,
`categorie_cout` (Faible/Modéré/Élevé/Très élevé).

## Méthodologie

Workflow suivi (cf. document source) : Import → Exploration → Data
cleaning → Transformation → Analyse business → Visualisation → Statistiques
descriptives → Dashboard → Reporting → Recommandations. Chaque étape est un
script R autonome et reproductible ; chaque règle de nettoyage a été
vérifiée par une exploration quantitative préalable plutôt que décidée a
priori (cf. tableau ci-dessus).
