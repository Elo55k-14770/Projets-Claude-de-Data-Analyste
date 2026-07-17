# ============================================================================
# Analyse Santé - Cameroun
# 05_visualisation.R : graphiques clés (ggplot2), exportés en PNG
# ============================================================================

library(tidyverse)
library(scales)

df <- read_csv("data/clean/consultations_enrichi.csv", show_col_types = FALSE)
dir.create("outputs/plots", showWarnings = FALSE, recursive = TRUE)

theme_set(
  theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(color = "grey40"),
      panel.grid.minor = element_blank(),
      legend.position = "bottom"
    )
)

save_plot <- function(p, name, width = 9, height = 6) {
  ggsave(file.path("outputs/plots", paste0(name, ".png")), p,
         width = width, height = height, dpi = 120, bg = "white")
  cat("Saved:", name, "\n")
}

# 1. Consultations par région
p1 <- df %>%
  count(region) %>%
  mutate(region = fct_reorder(region, n)) %>%
  ggplot(aes(region, n)) +
  geom_col(fill = "#2c7fb8") +
  coord_flip() +
  labs(title = "Consultations par région", subtitle = "Cameroun, 2025",
       x = NULL, y = "Nombre de consultations")
save_plot(p1, "01_consultations_par_region")

# 2. Évolution mensuelle des consultations
p2 <- df %>%
  count(mois_num, mois) %>%
  ggplot(aes(mois_num, n)) +
  geom_line(color = "#2c7fb8", linewidth = 1) +
  geom_point(color = "#2c7fb8", size = 2) +
  scale_x_continuous(breaks = 1:12, labels = levels(df$mois)) +
  labs(title = "Évolution mensuelle des consultations", subtitle = "2025",
       x = NULL, y = "Nombre de consultations") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
save_plot(p2, "02_evolution_mensuelle")

# 3. Top diagnostics
p3 <- df %>%
  filter(diagnosis != "Non renseigné") %>%
  count(diagnosis) %>%
  mutate(diagnosis = fct_reorder(diagnosis, n)) %>%
  ggplot(aes(diagnosis, n)) +
  geom_col(fill = "#d95f02") +
  coord_flip() +
  labs(title = "Répartition des diagnostics", x = NULL, y = "Nombre de cas")
save_plot(p3, "03_top_diagnostics")

# 4. Taux de rupture de stock par région
p4 <- df %>%
  group_by(region) %>%
  summarise(taux = mean(rupture_stock)) %>%
  mutate(region = fct_reorder(region, taux)) %>%
  ggplot(aes(region, taux)) +
  geom_col(fill = "#e34a33") +
  coord_flip() +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(title = "Taux de rupture de stock de médicaments par région",
       x = NULL, y = "Taux de rupture")
save_plot(p4, "04_rupture_stock_par_region")

# 5. Coût moyen par diagnostic (avec barre d'erreur = écart-type)
p5 <- df %>%
  filter(diagnosis != "Non renseigné", cout_connu) %>%
  group_by(diagnosis) %>%
  summarise(moyenne = mean(treatment_cost), ecart_type = sd(treatment_cost)) %>%
  mutate(diagnosis = fct_reorder(diagnosis, moyenne)) %>%
  ggplot(aes(diagnosis, moyenne)) +
  geom_col(fill = "#31a354") +
  geom_errorbar(aes(ymin = moyenne - ecart_type, ymax = moyenne + ecart_type), width = 0.3) +
  coord_flip() +
  labs(title = "Coût moyen de traitement par diagnostic", subtitle = "± 1 écart-type",
       x = NULL, y = "Coût moyen (unité monétaire locale)")
save_plot(p5, "05_cout_moyen_par_diagnostic")

# 6. Distribution des âges
p6 <- df %>%
  filter(!is.na(patient_age)) %>%
  ggplot(aes(patient_age)) +
  geom_histogram(binwidth = 5, fill = "#756bb1", color = "white") +
  labs(title = "Distribution de l'âge des patients", subtitle = "Valeurs aberrantes déjà exclues",
       x = "Âge", y = "Nombre de consultations")
save_plot(p6, "06_distribution_age")

# 7. Répartition par type de consultation et genre
p7 <- df %>%
  filter(gender != "Non renseigné") %>%
  count(consultation_type, gender) %>%
  ggplot(aes(consultation_type, n, fill = gender)) +
  geom_col(position = "dodge") +
  scale_fill_manual(values = c("Male" = "#3182bd", "Female" = "#de77ae")) +
  labs(title = "Type de consultation par genre", x = NULL, y = "Nombre de consultations", fill = "Genre")
save_plot(p7, "07_consultation_par_genre")

# 8. Couverture d'assurance par région
p8 <- df %>%
  filter(insurance_status != "Non renseigné") %>%
  count(region, insurance_status) %>%
  group_by(region) %>%
  mutate(pct = n / sum(n)) %>%
  ggplot(aes(fct_reorder(region, pct * (insurance_status == "Insured")), pct, fill = insurance_status)) +
  geom_col(position = "fill") +
  coord_flip() +
  scale_y_continuous(labels = percent_format()) +
  scale_fill_manual(values = c("Insured" = "#2ca25f", "Uninsured" = "#de2d26")) +
  labs(title = "Couverture d'assurance par région", x = NULL, y = "Proportion", fill = "Statut")
save_plot(p8, "08_couverture_assurance_par_region")

# 9. Boxplot du coût par tranche d'âge
p9 <- df %>%
  filter(cout_connu, !is.na(tranche_age)) %>%
  ggplot(aes(tranche_age, treatment_cost)) +
  geom_boxplot(fill = "#fdae6b") +
  labs(title = "Coût de traitement par tranche d'âge", x = NULL, y = "Coût")
save_plot(p9, "09_cout_par_tranche_age")

# 10. Heatmap diagnostic x region (volume)
p10 <- df %>%
  filter(diagnosis != "Non renseigné") %>%
  count(region, diagnosis) %>%
  ggplot(aes(diagnosis, region, fill = n)) +
  geom_tile() +
  scale_fill_gradient(low = "#fee8c8", high = "#b30000") +
  labs(title = "Volume de cas par diagnostic et région", x = NULL, y = NULL, fill = "Nb cas") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
save_plot(p10, "10_heatmap_diagnostic_region")

cat("\n=== 10 graphiques exportés dans outputs/plots/ ===\n")
