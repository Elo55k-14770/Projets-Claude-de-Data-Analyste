# ============================================================================
# Analyse Santé - Cameroun
# 02_data_cleaning.R : nettoyage du dataset (NA, doublons, fautes de frappe,
# catégories incohérentes, dates incohérentes, valeurs aberrantes)
# ============================================================================
# Chaque règle ci-dessous est justifiée par les constats de l'exploration
# (01_import_exploration.R). Voir README.md pour le détail des hypothèses.

library(tidyverse)
library(janitor)

raw <- read_csv("data/raw/consultations_sante_cameroun.csv", show_col_types = FALSE)
n_raw <- nrow(raw)

# ----------------------------------------------------------------------------
# 1. Doublons
# ----------------------------------------------------------------------------
# 232 lignes 100% identiques + des conflits supplémentaires sur la même clé
# (patient_id, consultation_date) avec des valeurs différentes sur d'autres
# colonnes (doublons de saisie). On déduplique sur cette clé métier en gardant
# la première occurrence. 11 patient_id ont de VRAIES visites répétées à des
# dates différentes : celles-ci sont conservées (ce ne sont pas des doublons).
before_dedup <- nrow(raw)
clean <- raw %>%
  distinct(patient_id, consultation_date, .keep_all = TRUE)
n_dupes_removed <- before_dedup - nrow(clean)

# ----------------------------------------------------------------------------
# 2. Dates incohérentes : deux formats mélangés dans la même colonne
#    - "2025-05-06" (ISO, YYYY-MM-DD)  -> majorité des lignes
#    - "31/12/2025" (DD/MM/YYYY)        -> 200 lignes
# ----------------------------------------------------------------------------
clean <- clean %>%
  mutate(
    consultation_date = case_when(
      str_detect(consultation_date, "^\\d{4}-\\d{2}-\\d{2}$") ~ as.Date(consultation_date, format = "%Y-%m-%d"),
      str_detect(consultation_date, "^\\d{2}/\\d{2}/\\d{4}$") ~ as.Date(consultation_date, format = "%d/%m/%Y"),
      TRUE ~ as.Date(NA)
    )
  )

# ----------------------------------------------------------------------------
# 3. Genre : variantes de casse / langue (Male, male, M, Masculin, Female,
#    female, F, Feminin) -> standardisé sur Male / Female. Manquant -> explicite.
# ----------------------------------------------------------------------------
clean <- clean %>%
  mutate(
    gender = case_when(
      gender %in% c("Male", "male", "M", "Masculin") ~ "Male",
      gender %in% c("Female", "female", "F", "Feminin") ~ "Female",
      TRUE ~ "Non renseigné"
    )
  )

# ----------------------------------------------------------------------------
# 4. Région : variantes de casse / langue / abréviation, standardisées sur
#    les 10 régions officielles du Cameroun.
# ----------------------------------------------------------------------------
clean <- clean %>%
  mutate(
    region = case_when(
      region %in% c("Sud-Ouest", "SW", "sud ouest") ~ "Sud-Ouest",
      region %in% c("Littoral", "LITTORAL", "litoral") ~ "Littoral",
      region %in% c("Centre", "CENTER", "Ctr", "centre") ~ "Centre",
      region %in% c("Adamaoua", "Extrême-Nord", "Sud", "Est", "Ouest",
                    "Nord-Ouest", "Nord") ~ region,
      TRUE ~ NA_character_
    )
  )

# Région manquante (valeur vide OU non reconnue) : on tente une imputation
# via le district, car chaque district appartient à une seule région (une
# fois les variantes ci-dessus standardisées, la relation district -> région
# est 1:1 dans les données observées).
district_region_map <- clean %>%
  filter(!is.na(region)) %>%
  distinct(district, region) %>%
  count(district, region) %>%
  group_by(district) %>%
  slice_max(n, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  select(district, region_from_district = region)

clean <- clean %>%
  left_join(district_region_map, by = "district") %>%
  mutate(
    region_imputed = is.na(region) & !is.na(region_from_district),
    region = coalesce(region, region_from_district),
    region = if_else(is.na(region), "Non renseigné", region)
  ) %>%
  select(-region_from_district)

# ----------------------------------------------------------------------------
# 5. Diagnosis / insurance_status manquants : pas de règle d'imputation
#    fiable -> catégorie explicite "Non renseigné" (on ne fabrique pas de
#    diagnostic ou de statut d'assurance).
# ----------------------------------------------------------------------------
clean <- clean %>%
  mutate(
    diagnosis = if_else(is.na(diagnosis) | diagnosis == "", "Non renseigné", diagnosis),
    insurance_status = if_else(is.na(insurance_status) | insurance_status == "", "Non renseigné", insurance_status)
  )

# ----------------------------------------------------------------------------
# 6. patient_age : valeurs aberrantes
#    - négatif (-5, 17 lignes) : impossible -> NA
#    - > 110 (valeurs 140 et 222, 33 lignes) : impossible -> NA
#    - == 0 (537 lignes, 5.2%) : traité comme sentinelle de valeur manquante,
#      pas comme des nourrissons réels. Justification : la proportion
#      d'age==0 est quasi identique (~4.5%-6.3%) dans TOUS les types de
#      consultation, y compris "Prenatal" (consultations prénatales de
#      femmes enceintes, où un patient de 0 an n'a cliniquement aucun sens).
#      Un vrai effet nourrisson serait concentré sur Vaccination/Emergency,
#      pas uniforme -> confirme une sentinelle de saisie, pas une donnée réelle.
# ----------------------------------------------------------------------------
clean <- clean %>%
  mutate(
    patient_age = if_else(patient_age < 0 | patient_age > 110 | patient_age == 0,
                           NA_real_, patient_age)
  )

# ----------------------------------------------------------------------------
# 7. treatment_cost : valeurs aberrantes
#    - négatif (16 lignes) : impossible -> NA
#    - valeurs sentinelles 9999 et 50000 (20 + 14 = 34 lignes) : un vrai coût
#      continu ne produit pas EXACTEMENT ces deux valeurs rondes à répétition
#      pendant que le reste de la distribution est à 5-45 -> ce sont des
#      codes d'erreur/placeholder de saisie, pas des coûts réels -> NA.
#    NA existants (516) conservés tels quels, non imputés (on ne fabrique pas
#    de coût ; les analyses financières les excluent explicitement).
# ----------------------------------------------------------------------------
clean <- clean %>%
  mutate(
    treatment_cost = if_else(
      treatment_cost < 0 | treatment_cost %in% c(9999, 50000),
      NA_real_, treatment_cost
    )
  )

# ----------------------------------------------------------------------------
# 8. medication_available, consultation_type : déjà propres (2 et 5
#    catégories cohérentes), aucune action nécessaire.
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
# Rapport de nettoyage
# ----------------------------------------------------------------------------
cat("=== Rapport de nettoyage ===\n")
cat("Lignes brutes                         :", n_raw, "\n")
cat("Doublons (patient_id+date) supprimés  :", n_dupes_removed, "\n")
cat("Lignes après dédoublonnage            :", nrow(clean), "\n")
cat("Régions imputées via district         :", sum(clean$region_imputed, na.rm = TRUE), "\n")
cat("Ages mis à NA (aberrants/sentinelle)   :", sum(is.na(clean$patient_age)), "\n")
cat("Coûts mis à NA (aberrants+sentinelle)  :", sum(is.na(clean$treatment_cost)) - 516, "(nouveaux) +516 (déjà manquants)\n")
cat("\n=== Contrôle : valeurs region après nettoyage ===\n")
print(sort(table(clean$region), decreasing = TRUE))
cat("\n=== Contrôle : valeurs gender après nettoyage ===\n")
print(sort(table(clean$gender), decreasing = TRUE))

clean <- clean %>% select(-region_imputed)

# ----------------------------------------------------------------------------
# Export
# ----------------------------------------------------------------------------
write_csv(clean, "data/clean/consultations_clean.csv")
cat("\nExporté vers data/clean/consultations_clean.csv (", nrow(clean), "lignes,", ncol(clean), "colonnes)\n")
