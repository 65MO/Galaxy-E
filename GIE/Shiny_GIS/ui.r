# ui.R

shinyUI(fluidPage(
  titlePanel("Zones d'échantillonnage"),

  sidebarLayout(
    sidebarPanel(
      helpText("Sélectionner une région dans la liste ci-dessous."),

      selectInput("DEPNAME", choices = regions, label = "Départements", selected="Finistère")
    ),

    mainPanel(leafletOutput("map"))
  )
))
