# Projet RH Analytics — DataLendo

Analyse SQL des effectifs, de la performance et du turnover de DataLendo, à
partir de 4 tables sources fournies par le service RH.

## Contenu du dossier

```
SQL/
├── employes.csv, departements.csv, performances.csv, turnover.csv   (sources)
├── hr_datalendo.db                 base SQLite construite à partir des CSV
├── sql/
│   ├── 01_schema.sql               structure des tables + notes de chargement
│   ├── 02_questions_business.sql   les 15 requêtes du mail du manager
│   └── 03_dataset_enrichi.sql      création de la table employes_enrichi
├── data/
│   └── employes_enrichi.csv        dataset employés + colonnes dérivées
├── INSIGHTS.md                     synthèse des résultats + recommandations RH
└── README.md                       ce fichier
```

Toutes les requêtes ont été **réellement exécutées** contre `hr_datalendo.db`
(SQLite), pas seulement rédigées : les chiffres cités dans `INSIGHTS.md` et en
commentaire de `02_questions_business.sql` sont les résultats obtenus.

## 1. Les tables

| Table | Grain | Colonnes clés |
|---|---|---|
| `employes` (1500 lignes) | 1 ligne / employé | `id_employe`, `poste`, `departement_id`, `date_embauche`, `date_depart` (NULL si actif), `salaire` |
| `departements` (10 lignes) | 1 ligne / département | `id_departement`, `nom_departement`, `manager`, `budget` |
| `performances` (18 000 lignes) | 1 ligne / évaluation trimestrielle | `id_employe`, `date_evaluation`, `score` (0-100), `objectifs_atteints` |
| `turnover` (200 lignes) | 1 ligne / départ | `id_employe`, `date_depart`, `type_depart` (volontaire/involontaire), `anciennete` |

Intégrité vérifiée : tous les `id_employe` de `performances` et `turnover`
existent dans `employes` ; les 200 lignes de `turnover` correspondent
exactement aux 200 employés de `employes` ayant un `date_depart` non nul.

## 2. Transformations et particularités des données

- **Encodage** : `departements.csv` est encodé en **Windows-1252** (cp1252),
  pas en UTF-8 — les accents (« Opérations », « Fatou Traoré », « Direction
  Générale ») sont corrompus si le fichier est lu en UTF-8 brut. Les 3 autres
  CSV sont en UTF-8. Voir la note de conversion dans `01_schema.sql`.
- **Booléens** : `performances.objectifs_atteints` contient les chaînes
  `True`/`False` (pas 0/1) dans le CSV source ; converties en entier 0/1 au
  chargement.
- **Dates de départ « futures »** : certaines valeurs de `date_depart` (dans
  `employes` et `turnover`) sont postérieures à la date d'exécution de
  l'analyse. Elles sont néanmoins traitées comme des départs actés (chaque
  `id_employe` concerné a une ligne miroir dans `turnover.csv`), pas comme des
  départs "à venir" à ignorer — voir hypothèse ci-dessous.

## 3. Hypothèses posées (à valider avec le service RH)

1. **Date de référence ("aujourd'hui")** : fixée à **2026-07-17** pour tous
   les calculs relatifs (ancienneté, statut actif, fenêtre "12 derniers
   mois"). Codée en dur dans les requêtes pour la reproductibilité du livrable
   ; à remplacer par `CURRENT_DATE` (ou une variable de session) si les
   scripts sont rejoués plus tard sur des données rafraîchies.
2. **Employé actif** = `date_depart IS NULL`. 1300 employés actifs / 1500.
3. **Salaire moyen (Q4)**, **ancienneté (Q5)** et **distribution ancienneté/poste (Q12)** :
   calculés sur les employés **actifs uniquement**, pour refléter la masse
   salariale et la structure d'effectif actuelles plutôt que l'historique.
4. **Taux de turnover par département (Q3)** = départs historiques cumulés /
   effectif total historique (départs + actifs actuels) du département. C'est
   un taux "cumulé depuis toujours", pas un taux annualisé, faute de date
   d'entrée dans le département dans les données.
5. **Cohorte d'embauche (Q9, Q15)** = année de `date_embauche`.
6. **"3 derniers trimestres" (Q7)** = les 3 valeurs de `date_evaluation` les
   plus récentes **présentes dans les données** (calcul dynamique via
   `MAX`/`ORDER BY ... LIMIT 3`, pas une date en dur) : 2024-04-01, 2024-07-01,
   2024-10-01.
7. **"Cette année" pour le feedback manquant (Q13)** : le référentiel
   `performances` s'arrête en 2024 (aucune ligne 2025/2026). Interprété comme
   "la dernière année disponible dans les données" (calcul dynamique), sinon
   la question serait triviale (100% des actifs, faute de données récentes).
   Résultat : 0 employé actif sans évaluation en 2024 — le dataset couvre
   100% des employés chaque année.
8. **Segmentation de performance faible/moyen/élevé (Q14)** : répartition en
   **terciles** (`NTILE(3)`) du score moyen par employé, plutôt que des seuils
   fixes arbitraires. Les scores moyens par employé sont resserrés autour de
   74.5 (écart-type 4.2, car chaque employé a 12 évaluations dont la moyenne
   lisse la variance individuelle) : des seuils fixes auraient été peu
   discriminants. Seuils obtenus : Faible ≤ 72.8, Moyen 72.8-76.3, Élevé > 76.3.

## 4. Méthodologie

1. Chargement des 4 CSV dans une base SQLite (`hr_datalendo.db`) via pandas,
   avec l'encodage correct par fichier.
2. Écriture et **exécution réelle** de chaque requête des 15 questions
   business (`sql/02_questions_business.sql`), validation manuelle de la
   cohérence des résultats (sommes de contrôle : effectifs par cohorte,
   par tranche d'ancienneté, par type de départ).
3. Un bug de jointure a été détecté et corrigé pendant les tests : dans le
   tableau KPI final (Q15), joindre `performances` directement (12 lignes par
   employé) avant d'agréger gonflait artificiellement les comptages
   d'effectifs et de rétention. Corrigé en pré-agrégeant le score moyen par
   employé dans un CTE avant la jointure finale.
4. Construction de la table `employes_enrichi` (`sql/03_dataset_enrichi.sql`)
   et export vers `data/employes_enrichi.csv`.
5. Synthèse des résultats et recommandations RH dans `INSIGHTS.md`.

## 5. Dataset enrichi (`data/employes_enrichi.csv`)

1500 lignes (1 par employé), colonnes du fichier `employes` source +
4 colonnes dérivées :

| Colonne | Description |
|---|---|
| `statut` | `Actif` / `Parti` |
| `cohorte_embauche` | Année de `date_embauche` |
| `anciennete_annees` | Ancienneté en années (jusqu'à `date_depart` si parti, sinon jusqu'à la date de référence) |
| `score_moyen` | Moyenne de tous les scores de performance de l'employé |
| `categorie_performance` | `Faible` / `Moyen` / `Eleve` (tercile du score moyen, cf hypothèse 8) |
