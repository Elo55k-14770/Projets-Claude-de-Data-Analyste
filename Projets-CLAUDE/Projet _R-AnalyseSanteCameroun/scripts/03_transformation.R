# ============================================================================
# Analyse Santé - Cameroun
# 03_transformation.R : création de variables dérivées pour préparer
# l'analyse business
# ============================================================================

library(tidyverse)
library(lubridate)

clean <- read_csv("data/clean/consultations_clean.csv", show_col_types = FALSE)

mois_fr <- c("Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
             "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre")
jours_fr <- c("Dimanche", "Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi")

enriched <- clean %>%
  mutate(
    annee = year(consultation_date),
    mois_num = month(consultation_date),
    mois = factor(mois_fr[mois_num], levels = mois_fr),
    trimestre = quarter(consultation_date),
    jour_semaine = factor(jours_fr[wday(consultation_date)], levels = jours_fr),

    tranche_age = case_when(
      is.na(patient_age) ~ NA_character_,
      patient_age < 5 ~ "0-4 ans",
      patient_age < 15 ~ "5-14 ans",
      patient_age < 25 ~ "15-24 ans",
      patient_age < 45 ~ "25-44 ans",
      patient_age < 65 ~ "45-64 ans",
      TRUE ~ "65 ans et +"
    ),
    tranche_age = factor(tranche_age, levels = c("0-4 ans", "5-14 ans", "15-24 ans",
                                                   "25-44 ans", "45-64 ans", "65 ans et +")),

    rupture_stock = medication_available == "Stockout",
    est_urgence = consultation_type == "Emergency",
    est_assure = insurance_status == "Insured",

    cout_connu = !is.na(treatment_cost),
    categorie_cout = case_when(
      is.na(treatment_cost) ~ NA_character_,
      treatment_cost < 10 ~ "Faible (<10)",
      treatment_cost < 20 ~ "Modéré (10-20)",
      treatment_cost < 30 ~ "Élevé (20-30)",
      TRUE ~ "Très élevé (30+)"
    ),
    categorie_cout = factor(categorie_cout, levels = c("Faible (<10)", "Modéré (10-20)",
                                                          "Élevé (20-30)", "Très élevé (30+)"))
  )

cat("=== Aperçu du dataset enrichi ===\n")
glimpse(enriched)

cat("\n=== Répartition tranche_age ===\n")
print(table(enriched$tranche_age, useNA = "ifany"))

cat("\n=== Répartition categorie_cout ===\n")
print(table(enriched$categorie_cout, useNA = "ifany"))

write_csv(enriched, "data/clean/consultations_enrichi.csv")
cat("\nExporté vers data/clean/consultations_enrichi.csv (", nrow(enriched), "lignes,", ncol(enriched), "colonnes)\n")
