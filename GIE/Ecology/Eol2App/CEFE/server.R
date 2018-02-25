#
# Mortalité éoliennes [2]
# Partie Server
#

library(shiny)

# Define server logic required to draw a histogram
shinyServer(function(input, output) {

  ##------------------------##
  # la fonction suivante se déclenche avec un clic sur le bouton GO,
  # effectue 1000 simulations et 
  # renvoie un dataframe de 5 variables x 1000 valeurs
  ##------------------------##
  simul <- eventReactive(input$go, {

    # nombre de visites sur le terrain
    Nvisites<-input$Nvisites
    # intervale de temps entre les visites
    l<-input$l
    # nombre de cadavres posés pour le test de persistence
    Nind<-input$Nind
    # taux de détection des cadavres
    d<-input$d 	# detection
    # nombre de cadavres posés pour le test de détection
    size<-input$size
    # taux de persistence quotidien des cadavres
    p<-input$p		# persistence quotidienne
    # nombre de mortalités attendues par an
    Natt<-input$Natt
    # nombre de simulations 
    Nboot<-input$Nboot
    
    ##------------------------##
    # script de simulations	
    ##------------------------##
    Njour<-Nvisites*l+100
    Ncad<-Natt/365 	# nombre de cadavres moyen par jour
    
    d_estim<-rep(0,Nboot)
    Mortboot<-rep(0,Nboot)
    t<-rep(0,Nboot)
    ptemp<-rep(0,Nboot)
    p_estim<-rep(0,Nboot)
    Huso<-rep(0,Nboot)
    Winkelmann<-rep(0,Nboot)
    Erickson<-rep(0,Nboot)
    Jones<-rep(0,Nboot)
    Mort_true_interval<-rep(0,Nboot)
    
    ## debut des bootstrap
    withProgress(message = 'Bootstrap progression : ', value=0, {
      
      for (boot in 1:Nboot) {
        ###################################
        # simulation - nombre de cadavres détectés
        ###################################
        Mort_an<-rpois(Njour,Ncad)
        Ntotmort<-sum(Mort_an)
        histM<-matrix(0,ncol=Njour,nrow=Ntotmort)
        first<-rep(0,Ntotmort)
        last<-rep(0,Ntotmort)
        done<-0
        
        for (j in 1:(Njour-1)) {
          Nnew<-Mort_an[j]
          if(Nnew>0) {
            histM[(done+1):(done+Nnew),j]<-1
            first[(done+1):(done+Nnew)]<-j
            done<-done+Nnew
          }
          if (done>0) {
            for (i in 1:done) {
              if (histM[i,j]>0) {
                histM[i,(j+1)]<-rbinom(1,histM[i,j],p)
                if (histM[i,(j+1)]==0){
                  last[i]<-j
                }
              }
            }
          }
        }

        init<-5
        Sample_visites<-seq(init,(init+(l*(Nvisites-1))),length.out=Nvisites)
        Mort_visites<-histM[,Sample_visites]
        histdetect<-matrix(0,nrow=Ntotmort,ncol=Nvisites)
        for (i in 1:Ntotmort) {
          for (j in 1:Nvisites) {
            if (Mort_visites[i,j]>0){
              histdetect[i,j]<-rbinom(1,Mort_visites[i,j],d)
            }
          }
        }
        
        Mort_detect<-sum(rowSums(histdetect)>0)
        Mortboot[boot]<-Mort_detect
        Mort_true_interval[boot]<-sum(Mort_an[init:(init+(l*(Nvisites-1)))])
        
        ###################################
        ##  simulation estimation detect
        ###################################
        Ndetect<-sum(rbinom(size,1,d))
        d_estim[boot]<-Ndetect/size
        
        ###################################
        # simulation estimation persistence
        ###################################
        
        
        NjourP<-100
        hist<-matrix(0,nrow=Nind,ncol=NjourP)
        last<-rep(1,Nind)
        hist[,1]<-1
        for (i in 1:Nind) {
          for (j in 2:NjourP) {
            hist[i,j]<-rbinom(1,hist[i,(j-1)],p)
            if (hist[i,j]==1) {
              last[i]<-j
            }
          }
        }
        last<-last-1
        p_estim[boot]<-sum(last>l)/Nind
        t[boot]<-mean(last) # durée de vie moyenne d'un cadavre
        
        
        ### calculs Huso
        if ((-log(0.01)*t[boot])>=l){
          e_hat<-1
        }
        if ((-log(0.01)*t[boot])<l){
          e_hat<-((-log(0.01)*t[boot])/l)
        }
        ptemp[boot]<-t[boot]*(1-exp(-(l/t[boot])))/l
        Huso[boot]<-Mortboot[boot]/(d_estim[boot]*ptemp[boot]*e_hat)
        Winkelmann[boot]<-Mortboot[boot]/(p_estim[boot]*d_estim[boot])
        Erickson[boot]<-l*Mortboot[boot]/(t[boot]*d_estim[boot])
        Jones[boot]<-Mortboot[boot]/(d_estim[boot]*exp(-0.5*(l/t[boot]))*e_hat)
        
        # barre de progression Shiny (recalculee tous les 10 iterations)
        if (boot%%10 == 0)
          setProgress(boot/Nboot)
      }
      setProgress(1)
    })
    # fin des bootstrap
    ##------------------------##
    
    # valeur retour
    data.frame(Huso, Erickson, Winkelmann, Jones, Mort_true_interval)
  })
   
  ##------------------------##
  # rendu HTML résultats
  output$quantiles <- renderTable({
    df <- simul()
    l <- nrow(df)
    #nomcol <- c("Méthode" ,"Médiane", "IC 2.5", "IC 97.5", "IC 10", "IC 90","Proportion simulations sans Mortalité")
    col1 <- c("Erickson", "Huso", "Winkelmann", "Jones")
    col23456 <- rbind(
      quantile(df$Erickson[df$Erickson<10000], probs=c(0.5,0.025,0.975, 0.1,0.9),na.rm = T),
      quantile(df$Huso[df$Huso<10000], probs=c(0.5,0.025,0.975, 0.1,0.9),na.rm = T),
      quantile(df$Winkelmann[df$Winkelmann<10000], probs=c(0.5,0.025,0.975, 0.1,0.9),na.rm = T),
      quantile(df$Jones[df$Jones<10000], probs=c(0.5,0.025,0.975, 0.1,0.9),na.rm = T)
    )
    col7 <- c(
      sum(df$Erickson==0,na.rm=T)/(l-sum(is.na(df$Erickson))),
      sum(df$Huso==0,na.rm=T)/(l-sum(is.na(df$Huso))),
      sum(df$Winkelmann==0,na.rm=T)/(l-sum(is.na(df$Winkelmann))),
      sum(df$Jones==0,na.rm=T)/(l-sum(is.na(df$Jones)))
    )
    result <- data.frame(col1,col23456,col7)
    colnames(result) <- c("Méthode" ,"Médiane", "IC 2.5", "IC 97.5", "IC 10", "IC 90","Proportion simulations sans Mortalité")
    result
  })
  
  ##------------------------##
  # rendu des graphiques
  output$graphHuso <- renderPlot({
    df <- simul()
    hist(df$Huso, xlab="Estimation de la mortalité", ylab="fréquence sur les simulations", main="Formule de Huso")
  })
  
  output$graphErickson <- renderPlot({
    df <- simul()
    hist(df$Erickson, xlab="Estimation de la mortalité", ylab="fréquence sur les simulations", main="Formule de Erickson")
  })

  output$graphWinkelmann <- renderPlot({
    df <- simul()
    hist(df$Winkelmann, xlab="Estimation de la mortalité", ylab="fréquence sur les simulations", main="Formule de Winkelmann")
  })

  output$graphJones <- renderPlot({
    df <- simul()
    hist(df$Jones, xlab="Estimation de la mortalité", ylab="fréquence sur les simulations", main="Formule de Jones")
  })

  output$graphMortalite <- renderPlot({
    df <- simul()
    hist(df$Mort_true_interval, xlab="Nombre réeel de mortalités", ylab="fréquence sur les simulations", main="Mortalité réelle")
  })

})
