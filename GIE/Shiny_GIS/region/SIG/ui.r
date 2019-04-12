# ui.R

shinyUI(fluidPage(
  titlePanel("Zones d'échantillonnage"),

  sidebarLayout(
    sidebarPanel(
      helpText("Sélectionner une région dans la liste ci-dessous."),

      selectInput("REGION", choices = regions, label = "Départements")
    ),

    mainPanel(leafletOutput("map"))
  )
))
