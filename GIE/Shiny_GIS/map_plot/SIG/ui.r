# ui.R

shinyUI(fluidPage(
  br(),

  column(8,leafletOutput("map", height="600px")),
  column(4,br(),br(),br(),br(),plotOutput("plot", height="300px")),
  br()
))
