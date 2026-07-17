# Insights RH — DataLendo

Synthèse des résultats obtenus par l'exécution réelle des 15 requêtes SQL
(`sql/02_questions_business.sql`) sur `hr_datalendo.db`. Hypothèses et
définitions détaillées dans `README.md`.

## Vue d'ensemble des effectifs

- **1300 employés actifs** sur 1500 recrutés depuis 2019 (Q1).
- **24 départs** sur les 12 derniers mois (Q2), à comparer aux ~200 départs
  cumulés depuis 2019 — le rythme de départ récent est cohérent avec la
  moyenne historique (~40-50 départs/an sur 7 ans).
- Répartition des départs quasi **50/50 volontaire (49.5%) / involontaire
  (50.5%)** (Q11) : pas de signal d'alerte particulier sur l'un ou l'autre
  motif, mais la part involontaire mérite un suivi (coût de recrutement de
  remplacement + risque de contentieux si mal documentée).

## Turnover par département (Q3)

| Département | Taux de turnover cumulé |
|---|---|
| Direction Générale | **17.7%** |
| Opérations | 15.3% |
| Juridique | 14.9% |
| Informatique | 14.5% |
| Data & Analytics | 13.8% |
| Marketing | 13.3% |
| Service Client | 11.8% |
| Finance | 11.5% |
| Ressources Humaines | 11.0% |
| Ventes | 10.1% |

**Direction Générale et Opérations sont les deux départements les plus
exposés au turnover** — près de deux fois le taux de Ventes. À creuser en
priorité : conditions de poste, charge, management.

## Rémunération (Q4)

Salaire moyen (employés actifs) le plus élevé en **Finance (3113)** et
**Direction Générale (3086)**, le plus bas en **Marketing (2691)** et
**Opérations (2711)**. Point notable : Opérations combine à la fois un
turnover élevé (15.3%, 2e position) et une rémunération basse (2711, 2e plus
bas) — corrélation à investiguer en priorité, c'est le département le plus à
risque sur le plan RH.

## Ancienneté (Q5, Q12)

**653 employés actifs (50.2%)** ont plus de 5 ans d'ancienneté — une base de
collaborateurs expérimentés conséquente à fidéliser. La distribution par
poste (Q12) montre qu'aucun poste actif n'a moins d'1 an d'ancienneté
(cohérent avec le dernier recrutement du dataset en décembre 2023), et que
tous les postes ont une majorité de collaborateurs en tranche 5 ans et plus.

## Rétention par cohorte d'embauche (Q9)

| Cohorte | Effectif initial | Rétention |
|---|---|---|
| 2019 | 280 | 87.5% |
| 2020 | 288 | 85.4% |
| 2021 | 331 | 88.5% |
| 2022 | 317 | 85.5% |
| 2023 | 284 | 86.3% |

Rétention **stable dans un corridor étroit (85-88.5%)** selon la cohorte,
sans tendance de dégradation dans le temps — bon signal de stabilité
structurelle du recrutement, indépendamment de l'année d'embauche.

## Recrutement (Q10)

Ressources Humaines (164) et Juridique (161) recrutent le plus, Direction
Générale (130) le moins — cohérent avec des équipes de direction
naturellement plus restreintes.

## Performance (Q6, Q7, Q8, Q14)

- **Performance très homogène entre départements** (Q6) : scores moyens
  compris entre 73.8 (Marketing) et 74.9 (Opérations), un écart de seulement
  1.1 point. La performance individuelle ne semble pas structurée par
  département — les leviers d'amélioration sont probablement individuels
  plutôt qu'organisationnels.
- **Top 10 employés (3 derniers trimestres, Q7)** : scores de 94.0 à 98.3,
  répartis sur 7 départements différents (Direction Générale, RH, Data &
  Analytics, Opérations, Ventes, Marketing, Juridique) — la haute performance
  n'est concentrée dans aucun département en particulier.
- **10 employés les moins performants (Q8)** : scores de 59.4 à 64.1,
  concentrés sur Informatique (3), Ventes (2), Service Client (2), Marketing
  (2), Opérations (1).
- **Segmentation en tercile (Q14)** : Faible (≤72.8, 500 employés), Moyen
  (72.8-76.3, 500), Élevé (>76.3, 500) — par construction équilibrée à 1/3,
  cette segmentation sert de base de suivi continu plutôt que d'alerte en
  l'état.

## Feedback (Q13)

**0 employé actif sans évaluation en 2024** (dernière année disponible dans
les données) : le processus d'évaluation trimestrielle semble appliqué de
façon exhaustive, sans trou de couverture. Point de vigilance méthodologique
: cette donnée devra être recontrôlée dès que des évaluations 2025/2026
seront disponibles, la couverture 100% actuelle reflétant peut-être
simplement la génération du jeu de données plutôt qu'un processus réel.

## Tableau KPI département × cohorte (Q15)

Voir la sortie complète de la requête dans `sql/02_questions_business.sql`
(Q15) ou en régénérant la requête contre `hr_datalendo.db`. Les écarts de
rétention par cohorte au sein d'un même département vont jusqu'à ~20 points
(ex. Direction Générale 2022 : 70.8% contre Direction Générale 2021 : 90.0%),
ce qui suggère des effets ponctuels (managers, réorganisations) plutôt
qu'une tendance structurelle.

---

## Recommandations RH

1. **Prioriser Opérations et Direction Générale** pour un audit qualitatif du
   turnover (entretiens de départ, enquête de climat) : ce sont les deux
   départements cumulant le taux de turnover le plus élevé, et pour
   Opérations, une rémunération parmi les plus basses.
2. **Revoir la grille salariale de Marketing et Opérations**, les deux
   départements les moins bien rémunérés, en particulier si l'objectif est de
   réduire le turnover d'Opérations.
3. **Capitaliser sur les 653 employés à plus de 5 ans d'ancienneté** :
   programme de mentorat, plan de succession — c'est une population clé pour
   la transmission de compétences vu l'homogénéité de la performance entre
   départements.
4. **Suivre la part de départs involontaires (50.5%)** dans le temps : à ce
   niveau, un audit RH du processus disciplinaire/performance-improvement-plan
   en amont des départs involontaires est recommandé pour vérifier qu'il est
   bien documenté et cohérent d'un département à l'autre.
5. **Utiliser la segmentation de performance (Faible/Moyen/Élevé)** comme
   base d'un programme structuré : plans de développement ciblés pour le
   tercile Faible, reconnaissance/rétention ciblée pour le tercile Élevé —
   en gardant à l'esprit que cette segmentation est relative (terciles) et
   devra être recalculée à mesure que de nouvelles données arrivent.
6. **Fiabiliser la donnée d'ancienneté au moment du départ** (`turnover.csv`)
   et la cohérence des dates de départ avec la date du jour au moment de
   l'analyse, pour éviter toute ambiguïté sur le statut réel d'un employé.
