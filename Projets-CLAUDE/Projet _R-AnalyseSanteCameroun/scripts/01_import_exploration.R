# ============================================================================
# Analyse Santé - Cameroun
# 01_import_exploration.R : Import des données + exploration (comprendre
# avant d'agir, cf workflow du document)
# ============================================================================

library(tidyverse)
library(janitor)

# ----------------------------------------------------------------------------
# 1. Import
# ----------------------------------------------------------------------------
raw <- read_csv("data/raw/consultations_sante_cameroun.csv", show_col_types = FALSE)

cat("=== Dimensions ===\n")
print(dim(raw))

cat("\n=== Structure ===\n")
glimpse(raw)

# ----------------------------------------------------------------------------
# 2. Exploration : valeurs manquantes
# ----------------------------------------------------------------------------
cat("\n=== Valeurs manquantes par colonne ===\n")
na_summary <- raw %>%
  summarise(across(everything(), ~ sum(is.na(.) | . == ""))) %>%
  pivot_longer(everything(), names_to = "colonne", values_to = "nb_na") %>%
  mutate(pct_na = round(100 * nb_na / nrow(raw), 2)) %>%
  arrange(desc(nb_na))
print(na_summary, n = 30)

# ----------------------------------------------------------------------------
# 3. Doublons
# ----------------------------------------------------------------------------
cat("\n=== Doublons ===\n")
cat("Lignes 100% identiques :", sum(duplicated(raw)), "\n")
cat("patient_id dupliqués   :", sum(duplicated(raw$patient_id)), "\n")
cat("Nb patient_id uniques  :", n_distinct(raw$patient_id), "/", nrow(raw), "\n")

# ----------------------------------------------------------------------------
# 4. Catégories incohérentes (fautes de frappe, casse, orthographe)
# ----------------------------------------------------------------------------
cat("\n=== Valeurs uniques : gender ===\n")
print(sort(table(raw$gender), decreasing = TRUE))

cat("\n=== Valeurs uniques : region ===\n")
print(sort(table(raw$region), decreasing = TRUE))

cat("\n=== Valeurs uniques : consultation_type ===\n")
print(sort(table(raw$consultation_type), decreasing = TRUE))

cat("\n=== Valeurs uniques : medication_available ===\n")
print(sort(table(raw$medication_available), decreasing = TRUE))

cat("\n=== Valeurs uniques : insurance_status ===\n")
print(sort(table(raw$insurance_status), decreasing = TRUE))

cat("\n=== Valeurs uniques : diagnosis (top 20) ===\n")
print(head(sort(table(raw$diagnosis), decreasing = TRUE), 20))

cat("\n=== Nb districts / facility_name uniques ===\n")
cat("districts :", n_distinct(raw$district), "\n")
cat("facilities:", n_distinct(raw$facility_name), "\n")

# ----------------------------------------------------------------------------
# 5. Dates incohérentes
# ----------------------------------------------------------------------------
cat("\n=== Dates : plage brute (avant parsing) ===\n")
print(range(raw$consultation_date, na.rm = TRUE))

dates_parsed <- suppressWarnings(as.Date(raw$consultation_date))
cat("Dates non parsables (NA après conversion) :", sum(is.na(dates_parsed) & !is.na(raw$consultation_date) & raw$consultation_date != ""), "\n")
cat("Plage de dates valides :\n")
print(range(dates_parsed, na.rm = TRUE))
cat("Dates dans le futur (> aujourd'hui simulé 2026-07-17) :",
    sum(dates_parsed > as.Date("2026-07-17"), na.rm = TRUE), "\n")
cat("Dates très anciennes (< 2000-01-01) :",
    sum(dates_parsed < as.Date("2000-01-01"), na.rm = TRUE), "\n")

# ----------------------------------------------------------------------------
# 6. Valeurs aberrantes numériques
# ----------------------------------------------------------------------------
cat("\n=== patient_age : summary ===\n")
print(summary(raw$patient_age))
cat("Ages negatifs ou nuls :", sum(raw$patient_age <= 0, na.rm = TRUE), "\n")
cat("Ages > 110 :", sum(raw$patient_age > 110, na.rm = TRUE), "\n")

cat("\n=== treatment_cost : summary ===\n")
print(summary(raw$treatment_cost))
cat("Couts negatifs :", sum(raw$treatment_cost < 0, na.rm = TRUE), "\n")
q <- quantile(raw$treatment_cost, c(0.25, 0.75), na.rm = TRUE)
iqr <- q[2] - q[1]
upper <- q[2] + 1.5 * iqr
cat("Seuil aberrant (IQR*1.5) :", round(upper, 2), "\n")
cat("Nb valeurs au-dessus du seuil :", sum(raw$treatment_cost > upper, na.rm = TRUE), "\n")

cat("\n=== Exploration terminee ===\n")
