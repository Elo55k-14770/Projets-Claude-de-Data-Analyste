# ============================================================================
# Analyse Santé - Cameroun
# 04_analyse_business.R : répondre aux questions métier de santé publique
# ============================================================================

library(tidyverse)

df <- read_csv("data/clean/consultations_enrichi.csv", show_col_types = FALSE)
dir.create("outputs/tables", showWarnings = FALSE, recursive = TRUE)

save_tbl <- function(tbl, name) {
  write_csv(tbl, file.path("outputs/tables", paste0(name, ".csv")))
  cat("\n---", name, "---\n")
  print(tbl, n = 30)
}

# ----------------------------------------------------------------------------
# Q1. Volume de consultations par région
# ----------------------------------------------------------------------------
q1 <- df %>%
  count(region, name = "nb_consultations") %>%
  mutate(pct = round(100 * nb_consultations / sum(nb_consultations), 1)) %>%
  arrange(desc(nb_consultations))
save_tbl(q1, "q1_consultations_par_region")

# ----------------------------------------------------------------------------
# Q2. Évolution mensuelle des consultations (tendance/saisonnalité)
# ----------------------------------------------------------------------------
q2 <- df %>%
  count(annee, mois_num, mois, name = "nb_consultations") %>%
  arrange(annee, mois_num)
save_tbl(q2, "q2_evolution_mensuelle")

# ----------------------------------------------------------------------------
# Q3. Top diagnostics (pathologies les plus fréquentes)
# ----------------------------------------------------------------------------
q3 <- df %>%
  filter(diagnosis != "Non renseigné") %>%
  count(diagnosis, name = "nb_cas") %>%
  mutate(pct = round(100 * nb_cas / sum(nb_cas), 1)) %>%
  arrange(desc(nb_cas))
save_tbl(q3, "q3_top_diagnostics")

# ----------------------------------------------------------------------------
# Q4. Taux de rupture de stock de médicaments par région (KPI accès aux soins)
# ----------------------------------------------------------------------------
q4 <- df %>%
  group_by(region) %>%
  summarise(
    nb_consultations = n(),
    nb_rupture = sum(rupture_stock),
    taux_rupture_pct = round(100 * mean(rupture_stock), 1)
  ) %>%
  arrange(desc(taux_rupture_pct))
save_tbl(q4, "q4_rupture_stock_par_region")

# ----------------------------------------------------------------------------
# Q5. Coût moyen de traitement par diagnostic
# ----------------------------------------------------------------------------
q5 <- df %>%
  filter(diagnosis != "Non renseigné", cout_connu) %>%
  group_by(diagnosis) %>%
  summarise(
    nb_cas = n(),
    cout_moyen = round(mean(treatment_cost), 2),
    cout_median = round(median(treatment_cost), 2)
  ) %>%
  arrange(desc(cout_moyen))
save_tbl(q5, "q5_cout_moyen_par_diagnostic")

# ----------------------------------------------------------------------------
# Q6. Taux de couverture d'assurance par région
# ----------------------------------------------------------------------------
q6 <- df %>%
  filter(insurance_status != "Non renseigné") %>%
  group_by(region) %>%
  summarise(
    nb_consultations = n(),
    taux_assures_pct = round(100 * mean(est_assure), 1)
  ) %>%
  arrange(taux_assures_pct)
save_tbl(q6, "q6_couverture_assurance_par_region")

# ----------------------------------------------------------------------------
# Q7. Répartition démographique (âge, genre) par diagnostic
# ----------------------------------------------------------------------------
q7 <- df %>%
  filter(diagnosis != "Non renseigné", !is.na(tranche_age)) %>%
  count(diagnosis, tranche_age) %>%
  group_by(diagnosis) %>%
  mutate(pct = round(100 * n / sum(n), 1)) %>%
  ungroup() %>%
  arrange(diagnosis, tranche_age)
save_tbl(q7, "q7_diagnostic_par_tranche_age")

# ----------------------------------------------------------------------------
# Q8. Type de consultation dominant par région
# ----------------------------------------------------------------------------
q8 <- df %>%
  count(region, consultation_type) %>%
  group_by(region) %>%
  mutate(pct = round(100 * n / sum(n), 1)) %>%
  slice_max(n, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  arrange(desc(pct))
save_tbl(q8, "q8_consultation_dominante_par_region")

# ----------------------------------------------------------------------------
# Q9. Rupture de stock x diagnostic (quelles pathologies sont le plus
#     touchées par les ruptures de médicaments)
# ----------------------------------------------------------------------------
q9 <- df %>%
  filter(diagnosis != "Non renseigné") %>%
  group_by(diagnosis) %>%
  summarise(
    nb_cas = n(),
    taux_rupture_pct = round(100 * mean(rupture_stock), 1)
  ) %>%
  arrange(desc(taux_rupture_pct))
save_tbl(q9, "q9_rupture_stock_par_diagnostic")

# ----------------------------------------------------------------------------
# Q10. Qualité de la donnée par région (taux de valeurs manquantes, mesuré
#      sur le dataset dédupliqué mais AVANT remplacement par "Non renseigné"/
#      imputation, région déjà standardisée) -> permet d'identifier les
#      régions qui sous-déclarent, un signal actionable pour le ministère.
# ----------------------------------------------------------------------------
q10 <- df %>%
  group_by(region) %>%
  summarise(
    nb_lignes = n(),
    pct_diagnosis_manquant = round(100 * mean(diagnosis == "Non renseigné"), 1),
    pct_cost_manquant = round(100 * mean(!cout_connu), 1),
    pct_insurance_manquant = round(100 * mean(insurance_status == "Non renseigné"), 1)
  ) %>%
  arrange(desc(pct_diagnosis_manquant))
save_tbl(q10, "q10_qualite_donnee_par_region")

cat("\n=== Analyse business terminée : 10 tables exportées dans outputs/tables/ ===\n")
