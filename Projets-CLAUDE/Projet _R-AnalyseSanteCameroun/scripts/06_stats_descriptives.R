# ============================================================================
# Analyse Santé - Cameroun
# 06_stats_descriptives.R : résumer les données (moyenne, médiane, variance,
# distribution) pour comprendre les tendances générales
# ============================================================================

library(tidyverse)

df <- read_csv("data/clean/consultations_enrichi.csv", show_col_types = FALSE)
dir.create("outputs/tables", showWarnings = FALSE, recursive = TRUE)

describe_num <- function(x) {
  x <- x[!is.na(x)]
  tibble(
    n = length(x),
    moyenne = mean(x),
    mediane = median(x),
    ecart_type = sd(x),
    variance = var(x),
    min = min(x),
    q1 = quantile(x, 0.25),
    q3 = quantile(x, 0.75),
    max = max(x),
    coeff_variation_pct = round(100 * sd(x) / mean(x), 1)
  )
}

# ----------------------------------------------------------------------------
# 1. Statistiques globales : âge et coût de traitement
# ----------------------------------------------------------------------------
stats_age <- describe_num(df$patient_age) %>% mutate(variable = "patient_age", .before = 1)
stats_cost <- describe_num(df$treatment_cost) %>% mutate(variable = "treatment_cost", .before = 1)

stats_globales <- bind_rows(stats_age, stats_cost) %>%
  mutate(across(where(is.numeric), ~ round(., 2)))

cat("=== Statistiques descriptives globales ===\n")
print(stats_globales)
write_csv(stats_globales, "outputs/tables/stats_globales.csv")

# ----------------------------------------------------------------------------
# 2. Âge et coût par région
# ----------------------------------------------------------------------------
stats_par_region <- df %>%
  group_by(region) %>%
  summarise(
    n = n(),
    age_moyen = round(mean(patient_age, na.rm = TRUE), 1),
    age_median = round(median(patient_age, na.rm = TRUE), 1),
    cout_moyen = round(mean(treatment_cost, na.rm = TRUE), 2),
    cout_ecart_type = round(sd(treatment_cost, na.rm = TRUE), 2)
  ) %>%
  arrange(desc(n))

cat("\n=== Statistiques par région ===\n")
print(stats_par_region, n = 15)
write_csv(stats_par_region, "outputs/tables/stats_par_region.csv")

# ----------------------------------------------------------------------------
# 3. Distribution des variables catégorielles clés (fréquences + %)
# ----------------------------------------------------------------------------
freq_table <- function(data, var) {
  data %>%
    count({{ var }}) %>%
    mutate(pct = round(100 * n / sum(n), 1)) %>%
    arrange(desc(n))
}

cat("\n=== Distribution : gender ===\n")
print(freq_table(df, gender))

cat("\n=== Distribution : tranche_age ===\n")
print(freq_table(df %>% filter(!is.na(tranche_age)), tranche_age))

cat("\n=== Distribution : consultation_type ===\n")
print(freq_table(df, consultation_type))

cat("\n=== Distribution : medication_available ===\n")
print(freq_table(df, medication_available))

cat("\n=== Distribution : insurance_status ===\n")
print(freq_table(df, insurance_status))

# ----------------------------------------------------------------------------
# 4. Test de normalité sommaire (asymétrie) sur le coût - utile pour savoir
#    si la moyenne ou la médiane est le meilleur résumé à communiquer
# ----------------------------------------------------------------------------
cost_vals <- df$treatment_cost[!is.na(df$treatment_cost)]
skewness <- mean((cost_vals - mean(cost_vals))^3) / sd(cost_vals)^3
cat("\n=== Asymétrie (skewness) de treatment_cost :", round(skewness, 2), "===\n")
cat(if (skewness > 0.5) "Distribution étalée vers la droite : la médiane est plus représentative que la moyenne.\n"
    else "Distribution proche de la symétrie.\n")

cat("\n=== Statistiques descriptives terminées : tables exportées dans outputs/tables/ ===\n")
