-- ============================================================================
-- Projet RH Analytics - DataLendo
-- 03_dataset_enrichi.sql : dataset employés enrichi de colonnes dérivées
-- ============================================================================
-- Colonnes dérivées ajoutées :
--   - statut               : 'Actif' | 'Parti' (date_depart NULL ou non)
--   - cohorte_embauche     : année d'embauche
--   - anciennete_annees    : (date_depart si parti, sinon date de référence
--                             2026-07-17) - date_embauche, en années
--   - score_moyen          : moyenne de tous les scores de performance de l'employé
--   - categorie_performance: tercile (Faible/Moyen/Eleve) du score_moyen, cf Q14

DROP TABLE IF EXISTS employes_enrichi;

CREATE TABLE employes_enrichi AS
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
    e.id_employe,
    e.nom,
    e.prenom,
    e.poste,
    d.nom_departement,
    e.date_embauche,
    e.date_depart,
    e.salaire,
    CASE WHEN e.date_depart IS NULL THEN 'Actif' ELSE 'Parti' END AS statut,
    strftime('%Y', e.date_embauche) AS cohorte_embauche,
    ROUND(
        (JULIANDAY(COALESCE(e.date_depart, '2026-07-17')) - JULIANDAY(e.date_embauche)) / 365.25,
        2
    ) AS anciennete_annees,
    ROUND(se.score_moyen, 1) AS score_moyen,
    CASE seg.tier WHEN 1 THEN 'Faible' WHEN 2 THEN 'Moyen' ELSE 'Eleve' END AS categorie_performance
FROM employes e
JOIN departements d      ON d.id_departement = e.departement_id
LEFT JOIN score_employe se ON se.id_employe = e.id_employe
LEFT JOIN segments seg     ON seg.id_employe = e.id_employe;

-- Export : SELECT * FROM employes_enrichi; -> data/employes_enrichi.csv
