# ============================================================================
# Analyse Santé - Cameroun
# Dashboard interactif Shiny
# ============================================================================

library(shiny)
library(tidyverse)
library(DT)
library(scales)

df <- read_csv("../data/clean/consultations_enrichi.csv", show_col_types = FALSE) %>%
  mutate(
    mois = factor(mois, levels = c("Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
                                     "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre")),
    tranche_age = factor(tranche_age, levels = c("0-4 ans", "5-14 ans", "15-24 ans",
                                                   "25-44 ans", "45-64 ans", "65 ans et +"))
  )

regions <- sort(unique(df$region))
types_consult <- sort(unique(df$consultation_type))
tranches <- levels(df$tranche_age)

# ----------------------------------------------------------------------------
# UI
# ----------------------------------------------------------------------------
ui <- fluidPage(
  tags$head(tags$style(HTML("
    .kpi-box { background:#f7f9fb; border-left:5px solid #2c7fb8; border-radius:6px;
               padding:14px 18px; margin-bottom:14px; }
    .kpi-value { font-size:26px; font-weight:700; color:#1a1a1a; }
    .kpi-label { font-size:13px; color:#555; text-transform:uppercase; letter-spacing:0.03em; }
    .title-banner { background:#2c7fb8; color:white; padding:16px 20px; border-radius:6px; margin-bottom:16px; }
  "))),

  div(class = "title-banner",
      h2("Dashboard Santé Publique - Cameroun", style = "margin:0;"),
      p("Consultations dans les centres de santé - 2025", style = "margin:0;")
  ),

  sidebarLayout(
    sidebarPanel(
      width = 3,
      h4("Filtres"),
      selectInput("region", "Région", choices = c("Toutes" = "", regions), multiple = TRUE),
      selectInput("consult_type", "Type de consultation", choices = c("Tous" = "", types_consult), multiple = TRUE),
      selectInput("tranche", "Tranche d'âge", choices = c("Toutes" = "", tranches), multiple = TRUE),
      dateRangeInput("dates", "Période",
                      start = min(df$consultation_date), end = max(df$consultation_date),
                      min = min(df$consultation_date), max = max(df$consultation_date)),
      hr(),
      helpText("Les filtres s'appliquent à tous les onglets.")
    ),

    mainPanel(
      width = 9,
      fluidRow(
        column(3, div(class = "kpi-box", div(class = "kpi-label", "Consultations"), textOutput("kpi_total", inline = TRUE))),
        column(3, div(class = "kpi-box", div(class = "kpi-label", "Taux rupture stock"), textOutput("kpi_rupture", inline = TRUE))),
        column(3, div(class = "kpi-box", div(class = "kpi-label", "Coût moyen"), textOutput("kpi_cout", inline = TRUE))),
        column(3, div(class = "kpi-box", div(class = "kpi-label", "Taux assurés"), textOutput("kpi_assur", inline = TRUE)))
      ),

      tabsetPanel(
        tabPanel("Vue régionale",
                 plotOutput("plot_region", height = 380),
                 plotOutput("plot_rupture", height = 380)),
        tabPanel("Tendance temporelle",
                 plotOutput("plot_temps", height = 420)),
        tabPanel("Diagnostics",
                 plotOutput("plot_diag", height = 380),
                 plotOutput("plot_cout_diag", height = 380)),
        tabPanel("Démographie",
                 plotOutput("plot_age", height = 380),
                 plotOutput("plot_genre", height = 380)),
        tabPanel("Données",
                 DTOutput("table_donnees"))
      )
    )
  )
)

# ----------------------------------------------------------------------------
# Server
# ----------------------------------------------------------------------------
server <- function(input, output, session) {

  filtered <- reactive({
    d <- df %>%
      filter(consultation_date >= input$dates[1], consultation_date <= input$dates[2])
    if (!is.null(input$region) && length(input$region) > 0) d <- d %>% filter(region %in% input$region)
    if (!is.null(input$consult_type) && length(input$consult_type) > 0) d <- d %>% filter(consultation_type %in% input$consult_type)
    if (!is.null(input$tranche) && length(input$tranche) > 0) d <- d %>% filter(tranche_age %in% input$tranche)
    d
  })

  output$kpi_total <- renderText({
    format(nrow(filtered()), big.mark = " ")
  })
  output$kpi_rupture <- renderText({
    d <- filtered()
    if (nrow(d) == 0) return("-")
    percent(mean(d$rupture_stock), accuracy = 0.1)
  })
  output$kpi_cout <- renderText({
    d <- filtered() %>% filter(cout_connu)
    if (nrow(d) == 0) return("-")
    paste0(round(mean(d$treatment_cost), 1))
  })
  output$kpi_assur <- renderText({
    d <- filtered() %>% filter(insurance_status != "Non renseigné")
    if (nrow(d) == 0) return("-")
    percent(mean(d$est_assure), accuracy = 0.1)
  })

  output$plot_region <- renderPlot({
    filtered() %>%
      count(region) %>%
      mutate(region = fct_reorder(region, n)) %>%
      ggplot(aes(region, n)) +
      geom_col(fill = "#2c7fb8") +
      coord_flip() +
      labs(title = "Consultations par région", x = NULL, y = "Nombre de consultations") +
      theme_minimal(base_size = 13)
  })

  output$plot_rupture <- renderPlot({
    filtered() %>%
      group_by(region) %>%
      summarise(taux = mean(rupture_stock)) %>%
      mutate(region = fct_reorder(region, taux)) %>%
      ggplot(aes(region, taux)) +
      geom_col(fill = "#e34a33") +
      coord_flip() +
      scale_y_continuous(labels = percent_format(accuracy = 1)) +
      labs(title = "Taux de rupture de stock par région", x = NULL, y = "Taux de rupture") +
      theme_minimal(base_size = 13)
  })

  output$plot_temps <- renderPlot({
    filtered() %>%
      count(annee, mois_num, mois) %>%
      ggplot(aes(mois_num, n)) +
      geom_line(color = "#2c7fb8", linewidth = 1) +
      geom_point(color = "#2c7fb8", size = 2) +
      scale_x_continuous(breaks = 1:12,
                          labels = c("Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
                                     "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre")) +
      labs(title = "Évolution mensuelle des consultations", x = NULL, y = "Nombre de consultations") +
      theme_minimal(base_size = 13) +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })

  output$plot_diag <- renderPlot({
    filtered() %>%
      filter(diagnosis != "Non renseigné") %>%
      count(diagnosis) %>%
      mutate(diagnosis = fct_reorder(diagnosis, n)) %>%
      ggplot(aes(diagnosis, n)) +
      geom_col(fill = "#d95f02") +
      coord_flip() +
      labs(title = "Répartition des diagnostics", x = NULL, y = "Nombre de cas") +
      theme_minimal(base_size = 13)
  })

  output$plot_cout_diag <- renderPlot({
    filtered() %>%
      filter(diagnosis != "Non renseigné", cout_connu) %>%
      group_by(diagnosis) %>%
      summarise(moyenne = mean(treatment_cost)) %>%
      mutate(diagnosis = fct_reorder(diagnosis, moyenne)) %>%
      ggplot(aes(diagnosis, moyenne)) +
      geom_col(fill = "#31a354") +
      coord_flip() +
      labs(title = "Coût moyen par diagnostic", x = NULL, y = "Coût moyen") +
      theme_minimal(base_size = 13)
  })

  output$plot_age <- renderPlot({
    filtered() %>%
      filter(!is.na(patient_age)) %>%
      ggplot(aes(patient_age)) +
      geom_histogram(binwidth = 5, fill = "#756bb1", color = "white") +
      labs(title = "Distribution de l'âge", x = "Âge", y = "Nombre de consultations") +
      theme_minimal(base_size = 13)
  })

  output$plot_genre <- renderPlot({
    filtered() %>%
      filter(gender != "Non renseigné") %>%
      count(consultation_type, gender) %>%
      ggplot(aes(consultation_type, n, fill = gender)) +
      geom_col(position = "dodge") +
      scale_fill_manual(values = c("Male" = "#3182bd", "Female" = "#de77ae")) +
      labs(title = "Type de consultation par genre", x = NULL, y = "Nombre de consultations", fill = "Genre") +
      theme_minimal(base_size = 13)
  })

  output$table_donnees <- renderDT({
    filtered() %>%
      select(patient_id, consultation_date, region, district, patient_age, gender,
             diagnosis, treatment_cost, medication_available, consultation_type, insurance_status) %>%
      datatable(options = list(pageLength = 15, scrollX = TRUE))
  })
}

shinyApp(ui, server)
