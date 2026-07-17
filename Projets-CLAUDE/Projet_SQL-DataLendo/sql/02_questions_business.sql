-- ============================================================================
-- Projet RH Analytics - DataLendo
-- 02_questions_business.sql : les 15 questions du mail du manager
-- ============================================================================
-- Hypothèses générales (voir README.md pour le détail) :
--   - Date de référence ("aujourd'hui") pour tous les calculs relatifs
--     (ancienneté, statut actif, fenêtres glissantes) : 2026-07-17.
--     -> à remplacer par CURRENT_DATE si vous rejouez ces scripts plus tard
--        et souhaitez une date dynamique.
--   - Un employé est considéré "actif" si date_depart IS NULL. Les quelques
--     date_depart postérieures à la date de référence sont tout de même
--     traitées comme des départs actés (elles sont toutes présentes dans
--     turnover.csv), pas comme des départs "futurs" à ignorer.


-- ----------------------------------------------------------------------------
-- Q1. Combien d'employés sont actuellement actifs ?
-- ----------------------------------------------------------------------------
SELECT COUNT(*) AS nb_employes_actifs
FROM employes
WHERE date_depart IS NULL;
-- Résultat : 1300 employés actifs sur 1500.


-- ----------------------------------------------------------------------------
-- Q2. Combien de départs avons-nous eu sur les 12 derniers mois ?
-- ----------------------------------------------------------------------------
SELECT COUNT(*) AS nb_departs_12_mois
FROM turnover
WHERE date_depart BETWEEN DATE('2026-07-17', '-12 months') AND DATE('2026-07-17');
-- Résultat : 24 départs entre 2025-07-17 et 2026-07-17.


-- ----------------------------------------------------------------------------
-- Q3. Quels départements ont le turnover le plus élevé ?
-- Taux de turnover = départs historiques / effectif total (départs + actifs)
-- ----------------------------------------------------------------------------
SELECT
    d.nom_departement,
    COUNT(DISTINCT CASE WHEN e.date_depart IS NOT NULL THEN e.id_employe END) AS nb_departs,
    COUNT(DISTINCT CASE WHEN e.date_depart IS NULL THEN e.id_employe END)     AS nb_actifs,
    COUNT(DISTINCT e.id_employe)                                             AS effectif_total,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN e.date_depart IS NOT NULL THEN e.id_employe END)
                 / COUNT(DISTINCT e.id_employe), 1)                          AS taux_turnover_pct
FROM employes e
JOIN departements d ON d.id_departement = e.departement_id
GROUP BY d.id_departement, d.nom_departement
ORDER BY taux_turnover_pct DESC;
-- Top 3 : Direction Générale (17.7%), Opérations (15.3%), Juridique (14.9%).


-- ----------------------------------------------------------------------------
-- Q4. Quel est le salaire moyen par département ?
-- Calculé sur les employés actifs uniquement (reflète la masse salariale
-- actuelle, pas les salaires historiques des employés partis).
-- ----------------------------------------------------------------------------
SELECT
    d.nom_departement,
    ROUND(AVG(e.salaire), 0) AS salaire_moyen,
    COUNT(*)                 AS nb_employes_actifs
FROM employes e
JOIN departements d ON d.id_departement = e.departement_id
WHERE e.date_depart IS NULL
GROUP BY d.id_departement, d.nom_departement
ORDER BY salaire_moyen DESC;
-- Finance (3113) et Direction Générale (3086) en tête, Marketing (2691) en bas.


-- ----------------------------------------------------------------------------
-- Q5. Quels employés ont plus de 5 ans d'ancienneté ?
-- Parmi les employés actifs uniquement (ancienneté = date de référence - date d'embauche).
-- ----------------------------------------------------------------------------
SELECT
    e.id_employe, e.nom, e.prenom, d.nom_departement, e.poste, e.date_embauche,
    ROUND((JULIANDAY('2026-07-17') - JULIANDAY(e.date_embauche)) / 365.25, 1) AS anciennete_annees
FROM employes e
JOIN departements d ON d.id_departement = e.departement_id
WHERE e.date_depart IS NULL
  AND (JULIANDAY('2026-07-17') - JULIANDAY(e.date_embauche)) / 365.25 > 5
ORDER BY anciennete_annees DESC;
-- Résultat : 653 employés actifs sur 1300 (50.2%) ont plus de 5 ans d'ancienneté
-- (cohérent : les embauches du dataset s'étalent de 2019 à 2023).


-- ----------------------------------------------------------------------------
-- Q6. Classez les départements par performance moyenne trimestrielle.
-- Moyenne de tous les scores d'évaluation (2022-2024) par département.
-- ----------------------------------------------------------------------------
SELECT
    d.nom_departement,
    ROUND(AVG(p.score), 1)          AS score_moyen,
    COUNT(DISTINCT p.id_employe)    AS nb_employes_evalues,
    COUNT(*)                        AS nb_evaluations
FROM performances p
JOIN employes e     ON e.id_employe = p.id_employe
JOIN departements d ON d.id_departement = e.departement_id
GROUP BY d.id_departement, d.nom_departement
ORDER BY score_moyen DESC;
-- Écarts très faibles entre départements (~73-75), la performance est homogène.


-- ----------------------------------------------------------------------------
-- Q7. Identifier les 10 meilleurs employés sur les 3 derniers trimestres.
-- "3 derniers trimestres" = les 3 dates d'évaluation les plus récentes
-- présentes dans les données (calcul dynamique, pas de date en dur).
-- ----------------------------------------------------------------------------
WITH derniers_trimestres AS (
    SELECT DISTINCT date_evaluation
    FROM performances
    ORDER BY date_evaluation DESC
    LIMIT 3
)
SELECT
    e.id_employe, e.nom, e.prenom, d.nom_departement,
    ROUND(AVG(p.score), 1) AS score_moyen_3T,
    COUNT(*)               AS nb_evaluations
FROM performances p
JOIN employes e     ON e.id_employe = p.id_employe
JOIN departements d ON d.id_departement = e.departement_id
WHERE p.date_evaluation IN (SELECT date_evaluation FROM derniers_trimestres)
GROUP BY e.id_employe, e.nom, e.prenom, d.nom_departement
ORDER BY score_moyen_3T DESC
LIMIT 10;
-- Trimestres retenus : 2024-04-01, 2024-07-01, 2024-10-01.


-- ----------------------------------------------------------------------------
-- Q8. Identifier les employés les moins performants et leur département.
-- Score moyen sur l'ensemble de l'historique (2022-2024), 10 plus bas scores.
-- Cohérent avec la segmentation "Faible" de la Q14.
-- ----------------------------------------------------------------------------
WITH score_employe AS (
    SELECT id_employe, AVG(score) AS score_moyen
    FROM performances
    GROUP BY id_employe
)
SELECT
    e.id_employe, e.nom, e.prenom, d.nom_departement,
    ROUND(se.score_moyen, 1) AS score_moyen
FROM score_employe se
JOIN employes e     ON e.id_employe = se.id_employe
JOIN departements d ON d.id_departement = e.departement_id
ORDER BY se.score_moyen ASC
LIMIT 10;


-- ----------------------------------------------------------------------------
-- Q9. Calculer la rétention moyenne par cohorte d'embauche.
-- Cohorte = année d'embauche. Rétention = % de la cohorte encore actif aujourd'hui.
-- ----------------------------------------------------------------------------
SELECT
    strftime('%Y', date_embauche)                                      AS cohorte_embauche,
    COUNT(*)                                                           AS effectif_cohorte,
    SUM(CASE WHEN date_depart IS NULL THEN 1 ELSE 0 END)               AS toujours_actifs,
    ROUND(100.0 * SUM(CASE WHEN date_depart IS NULL THEN 1 ELSE 0 END)
                 / COUNT(*), 1)                                        AS taux_retention_pct
FROM employes
GROUP BY cohorte_embauche
ORDER BY cohorte_embauche;
-- Rétention stable entre 85% et 88.5% selon la cohorte, pas de dégradation
-- nette dans le temps.


-- ----------------------------------------------------------------------------
-- Q10. Quels départements recrutent le plus souvent ?
-- Nombre total d'embauches historiques (tous employés confondus) par département.
-- ----------------------------------------------------------------------------
SELECT
    d.nom_departement,
    COUNT(*) AS nb_recrutements
FROM employes e
JOIN departements d ON d.id_departement = e.departement_id
GROUP BY d.id_departement, d.nom_departement
ORDER BY nb_recrutements DESC;
-- Ressources Humaines (164) et Juridique (161) recrutent le plus,
-- Direction Générale (130) le moins.


-- ----------------------------------------------------------------------------
-- Q11. Quelle proportion des départs est volontaire vs involontaire ?
-- ----------------------------------------------------------------------------
SELECT
    type_depart,
    COUNT(*)                                              AS nb_departs,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM turnover), 1) AS pct
FROM turnover
GROUP BY type_depart
ORDER BY nb_departs DESC;
-- Quasi 50/50 : 101 involontaires (50.5%) vs 99 volontaires (49.5%).


-- ----------------------------------------------------------------------------
-- Q12. Quelle est la distribution des postes par ancienneté ?
-- Employés actifs uniquement, répartis en tranches d'ancienneté.
-- ----------------------------------------------------------------------------
WITH emp_anciennete AS (
    SELECT
        id_employe, poste,
        (JULIANDAY('2026-07-17') - JULIANDAY(date_embauche)) / 365.25 AS anciennete_annees
    FROM employes
    WHERE date_depart IS NULL
)
SELECT
    poste,
    CASE
        WHEN anciennete_annees < 1 THEN '< 1 an'
        WHEN anciennete_annees < 3 THEN '1-3 ans'
        WHEN anciennete_annees < 5 THEN '3-5 ans'
        ELSE '5 ans et +'
    END AS tranche_anciennete,
    COUNT(*) AS nb_employes
FROM emp_anciennete
GROUP BY poste, tranche_anciennete
ORDER BY poste,
    CASE tranche_anciennete
        WHEN '< 1 an' THEN 1 WHEN '1-3 ans' THEN 2 WHEN '3-5 ans' THEN 3 ELSE 4
    END;
-- Aucun employé actif avec moins d'1 an d'ancienneté : cohérent, la dernière
-- embauche du dataset date de 2023-12-30 et la date de référence est 2026-07-17.


-- ----------------------------------------------------------------------------
-- Q13. Quels employés n'ont pas encore reçu de feedback cette année ?
-- Le référentiel performances.csv s'arrête en 2024 (aucune donnée 2025/2026).
-- "Cette année" est donc interprétée comme la dernière année disponible dans
-- les données (calcul dynamique via MAX(strftime('%Y', date_evaluation))),
-- plutôt que l'année calendaire réelle - sinon la réponse serait triviale
-- (tout le monde, faute de données 2026).
-- ----------------------------------------------------------------------------
WITH derniere_annee AS (
    SELECT MAX(strftime('%Y', date_evaluation)) AS annee FROM performances
)
SELECT e.id_employe, e.nom, e.prenom, d.nom_departement
FROM employes e
JOIN departements d ON d.id_departement = e.departement_id
WHERE e.date_depart IS NULL
  AND e.id_employe NOT IN (
        SELECT p.id_employe FROM performances p, derniere_annee da
        WHERE strftime('%Y', p.date_evaluation) = da.annee
  )
ORDER BY d.nom_departement, e.nom;
-- Résultat : 0 ligne. Le dataset attribue une évaluation trimestrielle à
-- 100% des employés chaque année ; aucun "trou" de feedback n'existe en 2024.


-- ----------------------------------------------------------------------------
-- Q14. Segmentez les employés par niveau de performance : faible / moyen / élevé.
-- Segmentation en tercile (NTILE 3) sur le score moyen de chaque employé,
-- plutôt que des seuils fixes arbitraires : les scores moyens par employé
-- sont très resserrés (74.5 +/- 4.2), des seuils fixes auraient été peu
-- discriminants ou dépendants du dataset.
-- ----------------------------------------------------------------------------
WITH score_employe AS (
    SELECT id_employe, AVG(score) AS score_moyen
    FROM performances
    GROUP BY id_employe
),
segments AS (
    SELECT
        id_employe, score_moyen,
        NTILE(3) OVER (ORDER BY score_moyen) AS tier
    FROM score_employe
)
SELECT
    CASE tier WHEN 1 THEN 'Faible' WHEN 2 THEN 'Moyen' ELSE 'Eleve' END AS categorie_performance,
    COUNT(*)                    AS nb_employes,
    ROUND(MIN(score_moyen), 1)  AS score_min,
    ROUND(MAX(score_moyen), 1)  AS score_max,
    ROUND(AVG(score_moyen), 1)  AS score_moyen_segment
FROM segments
GROUP BY tier
ORDER BY tier;
-- Faible: <=72.8 (500 employés) | Moyen: 72.8-76.3 (500) | Eleve: >76.3 (500).


-- ----------------------------------------------------------------------------
-- Q15. Générer un tableau résumé avec KPIs par département et par cohorte.
-- NB : le score moyen est pré-agrégé par employé (CTE perf_agg) avant la
-- jointure, pour éviter que les 12 évaluations/employé ne faussent les
-- comptages d'effectif et de rétention (effet de multiplication de lignes).
-- ----------------------------------------------------------------------------
WITH perf_agg AS (
    SELECT id_employe, AVG(score) AS score_moyen
    FROM performances
    GROUP BY id_employe
)
SELECT
    d.nom_departement,
    strftime('%Y', e.date_embauche)                          AS cohorte_embauche,
    COUNT(*)                                                 AS effectif,
    SUM(CASE WHEN e.date_depart IS NULL THEN 1 ELSE 0 END)   AS actifs,
    ROUND(100.0 * SUM(CASE WHEN e.date_depart IS NULL THEN 1 ELSE 0 END)
                 / COUNT(*), 1)                               AS taux_retention_pct,
    ROUND(AVG(e.salaire), 0)                                  AS salaire_moyen,
    ROUND(AVG(pa.score_moyen), 1)                             AS score_moyen
FROM employes e
JOIN departements d      ON d.id_departement = e.departement_id
LEFT JOIN perf_agg pa     ON pa.id_employe = e.id_employe
GROUP BY d.id_departement, d.nom_departement, cohorte_embauche
ORDER BY d.nom_departement, cohorte_embauche;
