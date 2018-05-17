#
# Mortalité éoliennes [1]
# Partie UI
#

library(shiny)

# UI
shinyUI(fluidPage(
  
  # Application title
  fluidRow(
    column(width=3,img(src="cefe_160px.png", style="margin: 1rem auto;")),
    column(width=9,h1("Estimation des mortalités induites par les éoliennes"))
  ),
  
  
  # Sidebar 
  sidebarLayout(
    sidebarPanel(
      fileInput(
        'fichier_c', 
        label='Sélectionner un fichier avec le nombre de cadavres trouvés :', 
        accept=c(
          'text/csv',
          'text/comma-separated-values',
          'text/tab-separated-values',
          'text/plain',
          '.csv',
          '.txt')
      ),
      div('Nb lignes lues = ', textOutput('nb_points_c',inline=TRUE)),
      fileInput(
        'fichier_p', 
        label='Sélectionner un fichier avec la durée de persistance des cadavres déposés :', 
        accept=c(
          'text/csv',
          'text/comma-separated-values',
          'text/tab-separated-values',
          'text/plain',
          '.csv',
          '.txt')
      ),
      div('Nombre de lignes lues = ', textOutput('nb_points_p',inline=TRUE)),
      hr(),
      
      # lorsque le nb de lignes lues dans le fichier cadavres > 0 ET le nb de lignes lues dans le fichier persistence > 0 
      # alors afficher les zones de saisie + le bouton calcul
      conditionalPanel(condition="output.nb_points_c > 0 && output.nb_points_p > 0", 
                       # input parametres 
                       radioButtons('methode', 'Méthode de calcul des intervalles de confiance',
                                    c("Non-paramétrique"='1',
                                      "Paramétrique"='2'),
                                    '1'),                       
                       numericInput('inter_temps', label='Intervalle de temps entre les passages = ', value=4, step=1),
                       numericInput('nb_depose', label='Nombre de cadavres déposé pour étude de la détection = ', value=20, step=10),
                       numericInput('nb_trouve', label='Nombre de cadavres trouvé pour étude de la détection = ', value=10, step=10),
                       numericInput('pcent_simpl', label='Pourcentage de la surface prospectée = ', value=1, step=0.05),
                       # input$go = bouton Calcul
                       actionButton(inputId = "go", label = "CALCULER"),
                       hr()
      ),
      h4("A propos de cette page"),
      p(HTML("&#8226;"), a(href="manuel_shiny.pdf", "Manuel d'utilisation")),
      p(HTML("&#8226;"), a(href="estimations_de_mortalites.pdf", "Présentation sur l'estimation des mortalités")),
      p(HTML("&#8226;"), "Exemples de fichier CSV ",
        em(a(href="cadavres.csv", "'Nombre de cadavres trouvés'")), 
        "et",
        em(a(href="persistence.csv", "'Durée de persistance'")),
        "à télécharger."
        )
    ),

    # Show a plot of the generated distribution
    mainPanel(
      h3("Données en entrée"),
      htmlOutput("datacheck"),
      hr(),
      h3("Estimations avec leurs intervalles de confiance"),
      tableOutput("quantiles")
    )
  )
))
