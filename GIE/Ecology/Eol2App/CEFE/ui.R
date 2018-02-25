#
# Mortalité éoliennes [2]
# Partie UI
#

library(shiny)

# Define UI for application
shinyUI(fixedPage(
  
  
  # Application title
  fluidRow(
    column(width=3,img(src="cefe_160px.png", style="margin: 1rem auto;")),
    column(width=9,h1("Préparer un protocole de suivi de mortalité"))
  ),

  wellPanel(
    fluidRow(
      column(width=6, 
             numericInput('Nvisites', label='Nombre de visites sur le terrain = ', value=10, step=1),
             numericInput('l', label='Intervalle de temps entre les visites = ', value=4, step=1),
             numericInput('Natt', label='Nombre de mortalités attendues par an = ', value=80, step=5),
             numericInput('Nboot', label='Nombre de simulations = ', value=1000, step=100)
      ),
      column(width=6,
             numericInput('Nind', label='Nombre de cadavres posés pour le test de persistance = ', value=15, step=1),
             numericInput('p', label='Taux de persistance quotidien des cadavres = ', value=0.75, step=0.05),
             numericInput('size', label='Nombre de cadavres posés pour le test de détection = ', value=15, step=1),
             numericInput('d', label='Taux de détection des cadavres = ', value=0.75, step=0.05)
      )
    ),
    fluidRow(
      column(width=6,
             actionButton(inputId = "go", label = "SIMULER")
      ),
      column(width=6,
             h4("A propos de cette page"),
             p(HTML("&#8226;"), a(href="manuel_shiny.pdf", "Manuel d'utilisation")),
             p(HTML("&#8226;"), a(href="estimations_de_mortalites.pdf", "Présentation sur l'estimation des mortalités"))
      )
    )
  ),
  fluidRow(
    column(width=11,
           h4("Estimations et leurs intervalles de confiance"),
           tableOutput("quantiles")
           )
  ),
  fluidRow(
    column(width=6,
           plotOutput("graphErickson"),
           plotOutput("graphHuso")
           ),
    column(width=6,
           plotOutput("graphWinkelmann"),
           plotOutput("graphJones"),
           plotOutput("graphMortalite")
    )
  )
))
