-- ============================================================================
-- Projet RH Analytics - DataLendo
-- 01_schema.sql : structure des tables et chargement des données sources
-- ============================================================================
-- Moteur cible : SQLite (portable). Adaptations PostgreSQL/MySQL notées en
-- commentaire quand la syntaxe diverge.

CREATE TABLE employes (
    id_employe      INTEGER PRIMARY KEY,
    nom             TEXT NOT NULL,
    prenom          TEXT NOT NULL,
    poste           TEXT NOT NULL,           -- Analyste | Finance | Manager | Developpeur | RH
    departement_id  INTEGER NOT NULL REFERENCES departements(id_departement),
    date_embauche   DATE NOT NULL,
    date_depart     DATE,                    -- NULL = employé toujours en poste
    salaire         NUMERIC NOT NULL
);

CREATE TABLE departements (
    id_departement   INTEGER PRIMARY KEY,
    nom_departement  TEXT NOT NULL,
    manager          TEXT,
    budget           NUMERIC
);

CREATE TABLE performances (
    id_performance      INTEGER PRIMARY KEY,
    id_employe          INTEGER NOT NULL REFERENCES employes(id_employe),
    date_evaluation     DATE NOT NULL,        -- évaluation trimestrielle
    score               INTEGER NOT NULL,     -- 0-100
    objectifs_atteints  INTEGER NOT NULL      -- 0/1 (converti depuis True/False du CSV)
);

CREATE TABLE turnover (
    id_depart     INTEGER PRIMARY KEY,
    id_employe    INTEGER NOT NULL REFERENCES employes(id_employe),
    date_depart   DATE NOT NULL,
    type_depart   TEXT NOT NULL,              -- 'volontaire' | 'involontaire'
    anciennete    INTEGER NOT NULL            -- années d'ancienneté au moment du départ
);

CREATE INDEX idx_emp_dept     ON employes(departement_id);
CREATE INDEX idx_perf_emp     ON performances(id_employe);
CREATE INDEX idx_turnover_emp ON turnover(id_employe);

-- ----------------------------------------------------------------------------
-- Chargement des CSV (exemple SQLite CLI, après avoir créé les tables ci-dessus)
-- ----------------------------------------------------------------------------
-- .mode csv
-- .import --skip 1 employes.csv employes
-- .import --skip 1 performances.csv performances
-- .import --skip 1 turnover.csv turnover
--
-- IMPORTANT : departements.csv est encodé en Windows-1252 (cp1252), pas en UTF-8
-- (accents dans "Opérations", "Fatou Traoré", "Direction Générale"). Le convertir
-- avant import, par exemple :
--   iconv -f CP1252 -t UTF-8 departements.csv > departements_utf8.csv
--   .import --skip 1 departements_utf8.csv departements
--
-- Le champ objectifs_atteints du CSV performances.csv contient les chaînes
-- "True"/"False" : les convertir en 0/1 après import, ex. :
--   UPDATE performances SET objectifs_atteints = CASE lower(objectifs_atteints)
--       WHEN 'true' THEN 1 ELSE 0 END;
