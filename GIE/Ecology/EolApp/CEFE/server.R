#
# Mortalité éoliennes [1]
# Partie UI
#

library(shiny)
library(boot)

# Define server logic 
shinyServer(function(input, output) {
  
  # fonction reactive au chargement du fichier cadavres
  # renvoie un vecteur avec les valeurs si le fichier est correct (sinon NULL ou error)
  data_cadavres <- reactive({
    # lecture du fichier csv ou txt contenant le resultat des visites de terrain 
    # (nombre de cadavres trouves sous les eoliennes, une ligne par visite de terrain)    
    in_file <- read.table("/srv/shiny-server/data/inputdata.txt", header=T, sep="\t")
    if (is.null(in_file))
      return(NULL)
    df <- read.table("/srv/shiny-server/data/inputdata.txt", header=T, sep="\t")
    # extraire colonne 1, supprimer les éventuelles valeurs non-numériques
    v <- df[[1]]
    vnum <- suppressWarnings(!is.na(as.numeric(v)))
    as.numeric(v[vnum])
  })
  
  # fonction reactive au chargement du fichier persistence
  # renvoie un vecteur avec les valeurs si le fichier est correct (sinon NULL ou error)
  data_persistence <- reactive({
    # lecture du fichier csv ou txt contenant la duree de presence de cadavres deposes par les experimentateurs 
    # (une ligne par cadavre depose)
    in_file <- read.table("/srv/shiny-server/data/inputdata.txt", header=T, sep="\t")
    if (is.null(in_file)) 
      return(NULL)
    df <- read.table("/srv/shiny-server/data/inputdata.txt", header=T, sep="\t")
    # extraire colonne 1, supprimer les éventuelles valeurs non-numériques
    v <- df[[1]]
    vnum <- suppressWarnings(!is.na(as.numeric(v)))
    as.numeric(v[vnum])
  })

  # affichage du nb de lignes lues dans le fichier cadavres
  output$nb_points_c <- renderText({
    v_cadavres <- data_cadavres() # valeur reactive au fichier cadavres
    #validate(need(!inherits(v_cadavres, "try-error"), "NA"))
    length(v_cadavres)
  })
  
  # affichage du nb de lignes lues dans le fichier persistence
  output$nb_points_p <- renderText({
    v_persistence <- data_persistence() # valeur reactive au fichier persistence
    #validate(need(!inherits(v_persistence, "try-error"), "NA"))
    length(v_persistence)
  })
  
  output$datacheck <- renderUI({
    v_cad <- data_cadavres()
    v_per <- data_persistence()
    if(is.null(v_cad))
      str_cad <- "-"
    else {
      if (length(v_cad) <= 10)
        str_cad <- paste(v_cad, collapse=" , ")
      else
        str_cad <- paste(paste(head(v_cad,5), collapse=" , "), " , ... , ", paste(tail(v_cad,5), collapse=" , "))
    }
    if(is.null(v_per))
      str_per <- "-"
    else {
      if (length(v_per) <= 10)
        str_per <- paste(v_per, collapse=" , ")
      else
        str_per <- paste(paste(head(v_per,5), collapse=" , "), " , ... , ", paste(tail(v_per,5), collapse=" , "))
    }
    list(
      p(strong("Nombre de cadavres trouvés sous les éoliennes (une valeur par visite de terrain) :")),
      p(str_cad),
      p(strong("Durée de présence de cadavres déposés par les experimentateurs (une valeur par cadavre déposé)")),
      p(str_per)
    )
  })
  # affichage des données
  
  # la fonction qui lance les calculs pour la methode 1 reagit à 1 click sur le bouton go (Calcul)
  calculBoot <- eventReactive (input$go, {
    v_cadavres <- data_cadavres() # valeur reactive au fichier cadavres
    v_persistence <- data_persistence() # valeur reactive au fichier persistence
    
    # RECUPERE DE L'INFO DANS LES FICHIERS DE DONNEES
    param_l <- input$inter_temps #params[1,2]
    param_nb_depose <- input$nb_depose #params[2,2]
    param_nb_trouve <- input$nb_trouve #params[3,2]
    A <- input$pcent_simpl 
    Nvisites <- length(v_cadavres)
    Ncad_persistence <- length(v_persistence)
    Nd <- c(rep(1, param_nb_trouve), rep(0, (param_nb_depose - param_nb_trouve)))
    d <- param_nb_trouve / param_nb_depose
    
    # NOMBRE DE BOOTSTRAP A REALISER (pas le choix ? le garder toujours ? 10000)
    Nboot<-10000
    
    # CREER DES MATRICES POUR STOCKER LES RESULTATS DES BOOTSTRAP
    Mortboot<-rep(0,Nboot)
    t<-rep(0,Nboot)
    p_estim<-rep(0,Nboot)
    d_estim<-rep(0,Nboot)
    ptemp<-rep(0,Nboot)
    Huso<-rep(0,Nboot)
    Winkelmann<-rep(0,Nboot)
    Erickson<-rep(0,Nboot)
    Jones<-rep(0,Nboot)
    
    ### l'utilisateur a a choisir deux methodes d'estimation
    ## la methode 1 = boostrap non-parametrique (si pas beaucoup de donnees)

    if (input$methode == '1') {
      ## ------------------------###
      ##         METHODE 1      ####
      ## ------------------------###
      ### LE COEUR DE LA MACHINE POUR LES BOOTSTRAP METHODE 1
      # avec une barre de progression
      withProgress(message = 'Bootstrap progression : ', value=0, {
        for (boot in 1:Nboot) {
          #print(boot)
          # nb de cadavres detectes a chaque visite
          tir <- sample(1:Nvisites, Nvisites, replace=T)
          Mortboot[boot] <- sum(v_cadavres[tir])
          
          # persistence
          tir <- sample(1:Ncad_persistence, Ncad_persistence, replace=T)
          Pers <- v_persistence[tir]
          t[boot] <- mean(Pers)
          p_estim[boot] <- sum(Pers >= param_l) / Ncad_persistence
          
          # processus de detection
          tir <- sample(1:param_nb_depose, param_nb_depose, replace=T)
          d_estim[boot]<-mean(Nd[tir])
          
          
          ### calculs formules
          if ((-log(0.01) * t[boot]) >= param_l) 
            e_hat <- 1
          if ((-log(0.01) * t[boot]) < param_l) 
            e_hat <- ((-log(0.01) * t[boot])/param_l)
          ptemp[boot] <- t[boot] * (1 - exp(-(param_l / t[boot]))) / param_l
          Huso[boot] <- (Mortboot[boot] / (d_estim[boot] * ptemp[boot] * e_hat))/A
          Winkelmann[boot] <- (Mortboot[boot] / (p_estim[boot] * d_estim[boot]))/A
          Erickson[boot] <- (param_l * Mortboot[boot] / (t[boot] * d_estim[boot]))/A
          Jones[boot] <- (Mortboot[boot] / (d_estim[boot] * exp(-0.5*(param_l / t[boot])) * e_hat))/A
          
          # barre de progression Shiny (+10 % tous les 1000 iterations)
          if (boot%%100 == 0)
            incProgress(0.1)
        }
        setProgress(1)
      })
      
    }
    else if (input$methode == '2') {
      
      ## ------------------------###
      ##         METHODE 2      ####
      ## ------------------------###
      
      ### LE COEUR DE LA MACHINE POUR LES BOOTSTRAP METHODE 2
      # proba persistence
      p<-v_persistence
      p[p<param_l]<-0
      p[p>=param_l]<-1
      resP<-glm(p~1,family=binomial)
      p_estim<-inv.logit(rnorm(Nboot,resP$coefficients,vcov(resP)))
      
      # nb de cadavres
      resC<-glm(v_cadavres~1,family=poisson)
      Mortboot<-exp(rnorm(Nboot,resC$coefficients,vcov(resC)))*Nvisites
      
      # detection
      Nd<-c(rep(1,param_nb_trouve),rep(0,(param_nb_depose - param_nb_trouve)))
      resD<-glm(Nd~1,family=binomial)
      d_estim<-inv.logit(rnorm(Nboot,resD$coefficients,vcov(resD)))
      
      #duree persistence 
      resT<-glm(v_persistence~1)
      t<-rnorm(Nboot,resT$coefficients,vcov(resT))
      
      ### calculs formules
      withProgress(message = 'Bootstrap progression : ', value=0, {
        for (boot in 1:Nboot) {
          if ((-log(0.01)*t[boot])>=param_l){e_hat<-1}
          if ((-log(0.01)*t[boot])<param_l){e_hat<-((-log(0.01)*t[boot])/param_l)}
          ptemp[boot]<-t[boot]*(1-exp(-(param_l/t[boot])))/param_l
          Huso[boot]<-(Mortboot[boot]/(d_estim[boot]*ptemp[boot]*e_hat))/A
          Winkelmann[boot]<-(Mortboot[boot]/(p_estim[boot]*d_estim[boot]))/A
          Erickson[boot]<-(param_l*Mortboot[boot]/(t[boot]*d_estim[boot]))/A
          Jones[boot]<-(Mortboot[boot]/(d_estim[boot]*exp(-0.5*(param_l/t[boot]))*e_hat))/A
          # barre de progression Shiny (+10 % tous les 1000 iterations)
          if (boot %% 1000 == 0)
            incProgress(0.1)
        }
      })
    }
    col1 <- c("Erickson", "Huso", "Winkelmann", "Jones")
    col23456 <- rbind(
      quantile(Erickson[Erickson<1000], probs=c(0.5,0.025,0.975, 0.1,0.9),na.rm=T),
      quantile(Huso[Huso<1000], probs=c(0.5,0.025,0.975, 0.1,0.9),na.rm=T),
      quantile(Winkelmann[Winkelmann<1000], probs=c(0.5,0.025,0.975, 0.1,0.9),na.rm=T),
      quantile(Jones[Jones<1000], probs=c(0.5,0.025,0.975, 0.1,0.9),na.rm=T)
    )
    result <- data.frame(col1,col23456)
    colnames(result) <- c("Formule" ,"Médiane", "IC 2.5", "IC 97.5","IC 0.10","IC 0.90")
    result
    
  })

  # affichage du resultat basé sur la fonction calculBoot()
  output$quantiles <- renderTable({
    calculBoot()
  })
    
})
