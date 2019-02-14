#!/usr/bin/env Rscript



######################################################################################################################
############## CALCULATE AND PLOT EVOLUTION OF SPECIES POPULATION  function:main.glm    ##############################
######################################################################################################################

#### Based on Romain Lorrillière R script
#### Modified by Alan Amosse and Benjamin Yguel for integrating within Galaxy-E

library(lme4)
library(ggplot2)
library(speedglm)
library(arm)
library(ggplot2)
library(reshape)
library(data.table)
library(reshape2)

###########
#delcaration des arguments et variables/ declaring some variables and load arguments

args = commandArgs(trailingOnly=TRUE)

if (length(args)==0) {
    stop("At least one argument must be supplied (input file)", call.=FALSE) #si pas d'arguments -> affiche erreur et quitte / if no args -> error and exit1
} else {
    Datafilteredfortrendanalysis<-args[1] ###### Nom du fichier avec extension ".typedefichier", peut provenir de la fonction "FiltreEspeceRare" / file name without the file type ".filetype", may result from the function "FiltreEspeceRare"    
    tabSpecies<-args[2] ###### Nom du fichier avec extension ".typedefichier", peut provenir de la fonction "FiltreEspeceRare" / file name without the file type ".filetype", may result from the function "FiltreEspeceRare"  
    id<-args[3]  ##### nom du dossier de sortie des resultats / name of the output folder
    spExclude <- args [4] ##### liste d'espece qu on veut exclure de l analyse  / list of species that will be excluded
 AssessIC <-arg [5] ##########  TRUE ou FALSE réalise glm "standard" avec calcul d'intervalle de confiance ou speedglm sans IC / TRUE or FALSE perform a "standard" glm with confidance interval or speedglm without CI 
}




#Import des données / Import data 
tabCLEAN <- read.csv(Datafilteredfortrendanalysis,sep=";",dec=".") #### charge le fichier de données d abondance / load abundance of species
tabsp <- read.csv(tabSpecies,sep=";",dec=".")   #### charge le fichier de donnees sur nom latin, vernaculaire et abbreviation, espece indicatrice ou non / load the file with information on species specialization and if species are indicators
ncol<-as.integer(dim(tab)[2])
if(ncol<3){ #Verifiction de la présence mini de 3 colonnes, si c'est pas le cas= message d'erreur / checking for the presence of 3 columns in the file if not = error message
    stop("The file don't have at least 3 variables", call.=FALSE)
}

 firstYear <- min(tabCLEAN$annee) #### Recupère 1ere annee des donnees / retrieve the first year of the dataset
 lastYear <- max(tabCLEAN$annee)  #### Récupère la dernière annee des donnees / retrieve the last year of the dataset
 annees <- firstYear:lastYear  ##### !!!! une autre variable s'appelle annee donc peut être à modif en "periode" ? ### argument de la fonction mais  DECLARER DANS LA FONCTION AUSSI donc un des 2 à supprimer

spsFiltre=unique(levels(tabCLEAN[,3])) #### Recupère la liste des especes du tabCLEAN qui ont été sélectionnée et qui ont passé le filtre / retrieve species name that were selected and then filtered before

spExclude=subset (tabsp, !(espece %in% spsFiltre)) #### liste des espèces exclu par le filtre ou manuellement / List of species excluded manually or by the filter from the analyses 
tabsp=subset (tabsp, (espece %in% spsFiltre)) #### Enlève les espèces qui n'ont pas passé le filtre ou exclu manuellement pour les analyses / keep only selected species and species with enough data
sp=as.character(tabsp$espece)  ##### liste des espece en code ou abbreviation gardées pour les analyses ### arg de la fonction  DECLARE AUSSI APRES DS FONCTION  / list of the code or abbreviation of the species kept for the analyses





###################### POTENTIELLEMENT INTEGRABLE OU A ENLEVER CAR OPERATION N A PLUS RAISON D ETRE ICI ELLE EST FAIT AU TOUT DEBUT PAR LES 2 SCRIPTS AVANT
    if(!is.null(spExclude)) {   ########################### Exclusion des sps se trouvant dans une liste choisie par utilisateur  !!!!!! Ne sait pas si doit être intégré à la fonction ou sortie de celle ci comme c'était le cas avant,
                                ##### si c'est le cas alors il faut rajouter un argument à la fonction ci dessous : ,spExclude=NULL
                                        # browser()
        #dataCLEAN <- subset(tabCLEAN,!(espece %in% spExclude)) ## pas besoin car sont déjà exclu de base 
        tabsp <- subset(tabsp, !(espece %in% spExclude))

    }
	################## FIN DU POTENTIELLEMENT INTEGRABLE OU A ENLEVER
	
## fonction general de calcul de la variation temporelle et de la tendance generale
## la fonction genere aussi les graphiques

main.glm <- function(id="france",donneesAll=dataCLEAN,assessIC= TRUE,listSp=sp,tabsp=tabsp,annees=annees,figure=TRUE,description=TRUE,tendanceSurFigure=TRUE,tendanceGroupSpe = FALSE, ###### declaration des arguments  listSp=sp était avant declaré avant la fonction mais il me semble que ca marche aussi comme cela
                     seuilOccu=14,seuilAbond=NA,ecritureStepByStep=FALSE,spExcluPassage1=c("MOTFLA","SAXRUB","OENOEN","ANTPRA","PHYTRO")) {   #################  ici peut être à rajouter de spExclude qui se trouvait dans la fonction regroupant celle ci
                                                                                                                                      #########  j'ai rajouté arguments de la fonction qui englobait cette fonction: spExcluPassage1
    ##  donneesAll=data;listSp=sp;annees=firstYear:lastYear;figure=TRUE;description=TRUE;tendanceSurFigure=TRUE;tendanceGroupSpe = FALSE;
    ##                   seuilOccu=14;seuilAbond=NA;ecritureStepByStep=TRUE
    





###########################################################################################################  fonction renvoyant la categorie European Bird Census Council en fonction des resultats des modèles
## renvoie la categorie EBCC de la tendance en fonction
## trend l'estimateur de la tendance
## pVal la p value
## ICinf ICsup l intervalle de confiance a 95 pourcent
affectCatEBCC <- function(trend,pVal,ICinf,ICsup){
  catEBCC <- ifelse(pVal>0.05,
                    ifelse(ICinf < 0.95 | ICsup > 1.05,"Incertain","Stable"),
                    ifelse(trend<1,
                           ifelse(ICsup<0.95,"Fort dÃ©clin","DÃ©clin modÃ©rÃ©"),
                           ifelse(ICinf>1.05,"Forte augmentation","Augmentation modÃ©rÃ©e")))
  return(catEBCC)
}

############################################################################################################ fin de la fonction renvoyant la categorie EBCC






############################################################################################################ fonction graphique / function for graphical output
ggplot.espece <- function(dgg,tab1t,id,serie=NULL,sp,valide,nomSp=NULL,description=TRUE,
                          tendanceSurFigure=TRUE,seuilOccu=14, vpan) {
  
  #  serie=NULL;nomSp=NULL;description=TRUE;valide=catIncert
  #  tendanceSurFigure=TRUE;seuilOccu=14
  require(ggplot2)
  
  figname<- paste("Output/",id,"/",ifelse(valide=="Incertain","Incertain/",""),
                  sp,"_",id,serie, ".png",
                  sep = "")
  ## coordonnÃ©e des ligne horizontal de seuil pour les abondances et les occurences
  hline.data1 <- data.frame(z = c(1), panel = c(vpan[1]),couleur = "variation abondance",type="variation abondance")
  hline.data2 <- data.frame(z = c(0,seuilOccu), panel = c(vpan[2],vpan[2]),couleur = "seuil",type="seuil")
  hline.data3 <- data.frame(z = 0, panel = vpan[3] ,couleur = "seuil",type="seuil")  
  hline.data <- rbind(hline.data1,hline.data2,hline.data3)
  titre <- paste(nomSp)#,"\n",min(annee)," - ",max(annee),sep="")
  
  ## texte de la tendence
  tab1 <- subset(dgg,panel =="Variation abondance")
  pasdetemps <- max(dgg$annee) - min(dgg$annee) + 1
  txtPente1 <- paste(tab1t$Est,
                     ifelse(tab1t$signif," *",""),"  [",tab1t$LL," , ",tab1t$UL,"]",
                     ifelse(tab1t$signif,paste("\n",ifelse(tab1t$pourcent>0,"+ ","- "),
                                               abs(tab1t$pourcent)," % en ",pasdetemps," ans",sep=""),""),sep="")
  ## table du texte de la tendence
  tabTextPent <- data.frame(y=c(max(c(tab1$val,tab1$UL),na.rm=TRUE)*.9),
                            x=median(tab1$annee),
                            txt=ifelse(tendanceSurFigure,c(txtPente1),""),
                            courbe=c(vpan[1]),panel=c(vpan[1]))
  ## les couleurs
  vecColPoint <- c("#ffffff","#eeb40f","#ee0f59")
  names(vecColPoint) <- c("significatif","infSeuil","0")
  vecColCourbe <- c("#3c47e0","#5b754d","#55bb1d","#973ce0")
  names(vecColCourbe) <- c(vpan[1],"carre","presence",vpan[3])
  vecColHline <- c("#ffffff","#e76060")
  names(vecColHline) <- c("variation abondance","seuil")
  
  col <- c(vecColPoint,vecColCourbe,vecColHline)
  names(col) <- c(names(vecColPoint),names(vecColCourbe),names(vecColHline))
  
  ## si description graphique en 3 panels
  if(description) {
    p <- ggplot(data = dgg, mapping = aes(x = annee, y = val))
    ## Titre, axes ...
    p <- p + facet_grid(panel ~ ., scale = "free") +
      theme(legend.position="none",
            panel.grid.minor=element_blank(),
            panel.grid.major.y=element_blank())  +
      ylab("") + xlab("AnnÃ©e")+ ggtitle(titre) +
      scale_colour_manual(values=col, name = "" ,
                          breaks = names(col))+
      scale_x_continuous(breaks=min(dgg$annee):max(dgg$annee))
    p <- p + geom_hline(data =hline.data,mapping = aes(yintercept=z, colour = couleur,linetype=type ),
                        alpha=1,size=1.2)
    
    p <- p + geom_ribbon(mapping=aes(ymin=LL,ymax=UL),fill=col[vpan[1]],alpha=.2) 
    p <- p + geom_pointrange(mapping= aes(y=val,ymin=LL,ymax=UL),fill=col[vpan[1]],alpha=.2)
    p <- p + geom_line(mapping=aes(colour=courbe),size = 1.5)
    p <- p + geom_point(mapping=aes(colour=courbe),size = 3)
    p <- p + geom_point(mapping=aes(colour=catPoint,alpha=ifelse(!is.na(catPoint),1,0)),size = 2)
    p <-  p + geom_text(data=tabTextPent, mapping=aes(x,y,label=txt),parse=FALSE,color=col[vpan[1]],fontface=2, size=4)
    ggsave(figname, p,width=16,height=21, units="cm")
  } else {
    
    p <- ggplot(data = subset(dgg,panel=="Variation abondance"), mapping = aes(x = annee, y = val))
    ## Titre, axes ...
    p <- p + facet_grid(panel ~ ., scale = "free") +
      theme(legend.position="none",
            panel.grid.minor=element_blank(),
            panel.grid.major.y=element_blank())  +
      ylab("") + xlab("AnnÃ©e")+ ggtitle(titre) +
      scale_colour_manual(values=col, name = "" ,
                          breaks = names(col))+
      scale_x_continuous(breaks=min(dgg$annee):max(dgg$annee))
    p <- p + geom_hline(data =subset(hline.data,panel=="Variation abondance"),mapping = aes(yintercept=z, colour = couleur,linetype=type ),
                        alpha=1,size=1.2)
    
    p <- p + geom_ribbon(mapping=aes(ymin=LL,ymax=UL),fill=col[vpan[1]],alpha=.2) 
    p <- p + geom_pointrange(mapping= aes(y=val,ymin=LL,ymax=UL),fill=col[vpan[1]],alpha=.2)
    p <- p + geom_line(mapping=aes(colour=courbe),size = 1.5)
    p <- p + geom_point(mapping=aes(colour=courbe),size = 3)
    p <- p + geom_point(mapping=aes(colour=catPoint,alpha=ifelse(!is.na(catPoint),1,0)),size = 2)
    p <-  p + geom_text(data=tabTextPent, mapping=aes(x,y,label=txt),parse=FALSE,color=col[vpan[1]],fontface=2, size=4)
    ggsave(figname, p,width=15,height=9,units="cm")
  }
}
############################################################################################################ fin fonction graphique / end of function for graphical output





    filesaveAn <-  paste("Output/",id,"/variationsAnnuellesEspece_",id,".csv",  ##### Nom du fichier de sortie des resultats par année / name of the output file with results for each years
                         sep = "")
    filesaveTrend <-  paste("Output/",id,"/tendanceGlobalEspece_",id,".csv",   ##### Nom du fichier de sortie des resultats pour la période "annee" complete / name of the output file with the results for the period
                            sep = "")

    fileSaveGLMs <-  paste("Output/",id,"/listGLM_",id,sep = "")  #####  Nom du fichier de sortie des modèles lineaire generalisés / name of the output file of the generlized linear models

    
     
    seuilSignif <- 0.05  ## seuil de significativite / significancy threshold
    
    
   rownames(tabsp) <- tabsp$espece  ## change nom des lignes de tabsp (table de reference des especes) 
    
    
    ##vpan vecteur des panels de la figure  ###### POUR FAIRE LES GRAPHIQUES
    vpan <- c("Variation abondance")
    if(description) vpan <- c(vpan,"Occurrences","Abondances brutes")
                                        # nomfile1 <- paste("Donnees/carre2001-2014REGION_",id,".csv",sep="")   ##### PAS SUR QUE CE SOIT UTILE

    ## specifications des variables temporelles necesaires pour les analyses / specification of temporal variable necessary for the analyses
    annee <- sort(unique(donneesAll$annee))
    nbans <- length(annee)
    pasdetemps <- nbans-1
    firstY <- min(annee)
    lastY <- max(annee)
	
	listSp <- sp                  ###### COMPRENDS PAS CAR C UN ARGUMENT DE LA FONCTION DONC FAUT PAS LE DECLARER AVANT ? ET IL ETAIT DECLARE AUSSI AVANT DANS LA FONCTION D ORIGINE (c déclaré aussi avant mais sinon à supprimer)
    annees <- firstYear:lastYear  ###### COMPRENDS PAS CAR C UN ARGUMENT DE LA FONCTION DONC FAUT PAS LE DECLARER AVANT ? (c déclaré avant aussi mais sinon à supprimer)
	
	
	

    ## Ordre de traitement des especes ### order of species to be analyzed
    spOrdre <- aggregate(abond~espece,data=donneesAll,sum)  #### calcul les sommes des abondances pour ordonner / calculate the sum for the ordination
    spOrdre <- merge(spOrdre,tabsp,by="espece") #### rajoute la colonne avec les abondances totales par espece / add a new column with the sum
    
    spOrdre <- spOrdre[order(as.numeric(spOrdre$indicateur),spOrdre$abond,decreasing = TRUE),] #### mets les especes plus abondantes en premiers (plus long pour faire tourner le modèle) / order the species by abundance, the most abundant species being the less fast analysis
    
    
    listSp <- spOrdre$espece
    i <- 0
    nbSp <- length(listSp)
                                        #	browser()
    ## analyse par espece
### browser()
    ## affichage des especes conservÃ©es pour l'analyse  ### PAS SUR QUE CE SOIT ENCORE UTILE
    cat("\n",nbSp," Espéces conservÃ©es pour l'analyse\n\n",sep="")
    rownames(tabsp) <- tabsp$espece
    tabCons <- data.frame(Code_espece = listSp, nom_espece = tabsp[as.character(listSp),"nom"])
    print(tabCons)  
    cat("\n\n",sep="")
    flush.console()


    ## initialisation de la liste de sauvegarde


##browser()
    
    for (sp in listSp) {  ######## Boucle pour analyse par espèce / loop for the analysis by species


        i <- i + 1
          
        d <- subset(donneesAll,espece==sp)  ## d data pour l'espece en court  / cut the data keeping only the i species
        
        nomSp <- as.character(tabsp[sp,"nom"])  ## info sp
        cat("\n(",i,"/",nbSp,") ",sp," | ", nomSp,"\n",sep="")
        flush.console()

        indic <- tabsp[sp,"indicateur"] ## indic :espece utilisee pour le calcul des indicateurs par groupe de specialisation / list the species used as species indicators by trophic specialization

        nb_carre = tapply(rep(1,nrow(d)),d$annee,sum) ## nb_carre nombre de carre suivie par annee / number of plots per year
        
        nb_carre_presence = tapply(ifelse(d$abond>0,1,0),d$annee,sum) ## nb_carre_presence nombre de carre de presence par annee / number the plots where the species were observed
        
        tab2 <- data.frame(annee=rep(annee,2),val=c(nb_carre,nb_carre_presence),LL = NA,UL=NA, ## tab2 table de resultat d'analyse / data.frame of the analyses results
                           catPoint=NA,pval=NA,
                           courbe=rep(c("carre","presence"),each=length(annee)),panel=vpan[2])
        tab2$catPoint <- ifelse(tab2$val == 0,"0",ifelse(tab2$val < seuilOccu,"infSeuil",NA))
        
        abond <- tapply(d$abond,d$annee,sum) ## abond abondance par annee / abundance per year
        
        tab3 <- data.frame(annee=annee,val=abond,LL = NA,UL=NA,catPoint=NA,pval=NA,courbe=vpan[3],panel=vpan[3]) ## tab3 tab3 pour la figure / data.frame made to realize the graphical outputs
        tab3$catPoint <- ifelse(tab3$val == 0,"0",ifelse(tab3$val < seuilAbond,"infSeuil",NA))

        ## GLM pour calcul des tendances annuelles de l'evolution des populations / GLM to measure annual tendency of population evolution 
       formule <- as.formula("abond~as.factor(carre)+as.factor(annee)") #### specification du modèle = log lineaire / specifying the model = log linear
       if(assessIC) {##### OPTION A RENTRER AU DEBUT PEUT ËTRE A METTRE DANS LES ARGUMENTS SI LAISSE LE CHOIX SINON L ARG PAR DEFAUT LORS DE LA DECLARATION DE LA FONCTION
           glm1 <- glm(formule,data=d,family=quasipoisson)  ##### fit model lineaire general avec intervalle de confiance disponible / fit linear and generalized model with confidence intervalle available
       } else {
           glm1 <- try(speedglm(formule,data=d,family=quasipoisson())) ##### fit modele lineaire et generaux pour les gros jeux de données / fit of linear and generalized model for large-medium dataset
           if(class(glm1)[1]=="try-error")
               glm1 <- glm(formule,data=d,family=quasipoisson) ##### comprends pas mais je pense que c'est speedglm qui marche pas avec toutes les données
       }
       sglm1 <- summary(glm1)  #### sortie du modele / output of the model
       sglm1 <- coefficients(sglm1) ### coefficient regression de chaque variable avec les résultats des tests statistiques / regression coefficient of each predictive variables with results of the statistical tests
       sglm1 <- tail(sglm1,pasdetemps) #### recupére les derniers elements du modèle avec la taille de l'objet "pasdetemps" car le nombre de coef = nbre d'année et pas les coefficient de regression de la variable carre / retrieve only the coefficient regression of the variable year
       coefan <- as.numeric(as.character(sglm1[,1]))#### coefficient de regression de la variable année (1 pour chaque année)
        
        coefannee <- c(1,exp(coefan))## coefannee vecteur des variation d'abondance par annee avec transformation inverse du log :exp() / regression coefficient of the year back transformed from log(abundance) : exp()
        
		erreuran <- as.numeric(as.character(sglm1[,2])) #### erreur standard sur le coefficient de regression de la variable annee  / standard error on the regression coefficient of the year 
        erreurannee1 <- c(0,erreuran*exp(coefan))## erreur standard par année / the standard error per year
		
        pval <- c(1,as.numeric(as.character(sglm1[,4])))###### p value
        
        ## calcul des intervalle de confiance  / calcul of the confidence interval    POURQUOI PAS UTILISE confint()
        if(assessIC) {
        glm1.sim <- sim(glm1)
        ic_inf_sim <- c(1,exp(tail(apply(coef(glm1.sim), 2, quantile,.025),pasdetemps)))
        ic_sup_sim <- c(1,exp(tail(apply(coef(glm1.sim), 2, quantile,.975),pasdetemps)))
        } else {
            ic_inf_sim <- NA
            ic_sup_sim <- NA
 
        }
        
        
        
        tab1 <- data.frame(annee,val=coefannee,  ## tab1 table pour la realisation des figures   2EME POUR GRAPH A VERIF DIFFERENCE AVEC tab3  ici ce sont le coef de regress annee en fonction des annéés alors que tab2 c'est les abondance en fct des années
                           LL=ic_inf_sim,UL=ic_sup_sim,
                           catPoint=ifelse(pval<seuilSignif,"significatif",NA),pval,
                           courbe=vpan[1],
                           panel=vpan[1])
        ## netoyage des intervalle de confiance superieur trÃ¨s trÃ¨s grande et qd données pas suffisantes pour calcul d'IC /cleaning of wrong or biaised measures of the confidence interval
        if(assessIC) {
        tab1$UL <- ifelse( nb_carre_presence==0,NA,tab1$UL)
        tab1$UL <-  ifelse(tab1$UL == Inf, NA,tab1$UL)
        tab1$UL <-  ifelse(tab1$UL > 1.000000e+20, NA,tab1$UL)
        tab1$UL[1] <- 1
        tab1$val <-  ifelse(tab1$val > 1.000000e+20,1.000000e+20,tab1$val)
        }
        ## indice de surdispersion  / overdispersion index
       ## browser()
        if(assessIC) dispAn <- glm1$deviance/glm1$null.deviance else dispAn <- glm1$deviance/glm1$nulldev


        ## tabAn table de sauvegarde des resultats 2EM POUR RESULTAT A VERIF DIFFERENCE AVEC tab2     nb de carre, nb de carre presnce, p val sont aussi ds tab2
        tabAn <- data.frame(id,code_espece=sp, nom_espece = nomSp,indicateur = indic,annee = tab1$annee,
                            abondance_relative=round(tab1$val,3),
                            IC_inferieur = round(tab1$LL,3), IC_superieur = round(tab1$UL,3),
                            erreur_standard = round(erreurannee1,4),
                            p_value = round(tab1$pval,3),significatif = !is.na(tab1$catPoint),
                            nb_carre,nb_carre_presence,abondance=abond)
        
        ## GLM pour calcul des tendance generale sur la periode  / GLM to measure the tendency of population evolution on the studied period 
        formule <- as.formula(paste("abond~ as.factor(carre) + annee",sep="")) ### 
          #  browser()
    
       
         if(assessIC) {
             md2 <- glm(formule,data=d,family=quasipoisson) }
        else {
                md2 <- try(speedglm(formule,data=d,family=quasipoisson()),silent=TRUE)

                if(class(md2)[1]=="try-error")
                    md2 <- glm(formule,data=d,family=quasipoisson)
            }

        
       smd2 <- summary(md2)       #### sortie du modele / output of the model
       smd2 <- coefficients(smd2) ### coefficient regression de chaque variable avec les résultats des tests statistiques / regression coefficient of each predictive variables with results of the statistical tests
       smd2 <- tail(smd2,1)       ### coefficient regression de variable annee avec les résultats des tests statistiques / regression coefficient of the variable year with results of the statistical tests
       
        
        coefan <- as.numeric(as.character(smd2[,1])) ## tendences sur la periode / tendency of population evolution on the studied period 
        trend <- round(exp(coefan),3)
        
        pourcentage <- round((exp(coefan*pasdetemps)-1)*100,2) ## pourcentage de variation sur la periode / percentage of population variation on the studied period 
        pval <- as.numeric(as.character(smd2[,4]))
        
        erreuran <- as.numeric(as.character(smd2[,2])) #### récuperer l'erreur standard / retrieve the error 
        ## erreur standard 
        erreurannee2 <- erreuran*exp(coefan)
        
        
        ## calcul des intervalle de confiance / calculating the confidence interval
        LL <- NA
        UL <- NA
        if(assessIC) {
            md2.sim <- sim(md2)
            LL <- round(exp(tail(apply(coef(md2.sim), 2, quantile,.025),1)),3)
            UL <- round(exp(tail(apply(coef(md2.sim), 2, quantile,.975),1)),3)
        } else {
            LL <- NA
            UL <- NA
        }
        
        ## tab1t table utile pour la realisation des figures  / table used for the figures
        tab1t <- data.frame(Est=trend,
                            LL , UL,
                            pourcent=pourcentage,signif=pval<seuilSignif,pval)
        
        
        trendsignif <- tab1t$signif
        pourcent <- round((exp(coefan*pasdetemps)-1)*100,3)
        ## mesure de la surdispersion / overdispersion measurment

          if(assessIC) dispTrend <- md2$deviance/md2$null.deviance else dispTrend <- md2$deviance/md2$nulldev


        
        ## classement en categorie incertain /classifying wrong or not reliable results 
       # browser()
        if(assessIC) {
        if(dispTrend > 2 | dispAn > 2 | median( nb_carre_presence)<seuilOccu) catIncert <- "Incertain" else catIncert <-"bon"  ##### en fonction de l'indice de surdispersion et presence < à seuil occurence / based on the overdispersion index and the presence on a minimum number of plots
        vecLib <-  NULL
        if(dispTrend > 2 | dispAn > 2 | median( nb_carre_presence)<seuilOccu) {
            if(median( nb_carre_presence)<seuilOccu) {
                vecLib <- c(vecLib,"espece trop rare")
            }
            if(dispTrend > 2 | dispAn > 2) {
                vecLib <- c(vecLib,"deviance")
            }
        }
        raisonIncert <-  paste(vecLib,collapse=" et ")
        } else {
            catIncert <- NA
            raisonIncert <- NA
        }
        
        
        
        ## affectation des tendence EBCC  / retrieve the trend of population evolution on the studied period
        catEBCC <- NA
        if(assessIC)  catEBCC <- affectCatEBCC(trend = as.vector(trend),pVal = pval,ICinf=as.vector(LL),ICsup=as.vector(UL)) else catEBCC <- NA
        ## table complete de resultats  
     #   browser()
        tabTrend <- data.frame(
            id,code_espece=sp,nom_espece = nomSp,indicateur = indic,
            nombre_annees = pasdetemps,premiere_annee = firstY,derniere_annee = lastY,
            tendance = as.vector(trend) ,  IC_inferieur=as.vector(LL) , IC_superieur = as.vector(UL),pourcentage_variation=as.vector(pourcent),
            erreur_standard = as.vector(round(erreurannee2,4)), p_value = round(pval,3),
            significatif = trendsignif,categorie_tendance_EBCC=catEBCC,mediane_occurrence=median( nb_carre_presence) ,
            valide = catIncert,raison_incertitude = raisonIncert)


        if(assessIC)  listGLMsp <- list(list(glm1,glm1.sim,md2,md2.sim)) else  listGLMsp <- list(list(glm1,md2))
        names(listGLMsp)[[1]] <-sp 
        fileSaveGLMsp <- paste(fileSaveGLMs,"_",sp,".Rdata",sep="")
        
        save(listGLMsp,file=fileSaveGLMsp)
        cat("--->",fileSaveGLMsp,"\n")
        flush.console()

        if(sp==listSp[1]) {
            glmAn <- tabAn
            glmTrend <- tabTrend
        } else  {
            glmAn <- rbind(glmAn,tabAn)
            glmTrend <- rbind(glmTrend,tabTrend)
        }
	## les figures     
        if(figure) {
            ## table complete pour la figure en panel par ggplot2
            ## table pour graphe en panel par ggplot2
            if(description)	dgg <- rbind(tab1,tab2,tab3) else dgg <- tab1
            ## les figures     
            
            ggplot.espece(dgg,tab1t,id,serie=NULL,sp,valide=catIncert,nomSp,description,tendanceSurFigure,seuilOccu=14,vpan = vpan)
            
        }
        
        if(ecritureStepByStep) {

            write.csv2(glmAn,filesaveAn,row.names=FALSE,quote=FALSE)
            cat("--->",filesaveAn,"\n")
            write.csv2(glmTrend,filesaveTrend,row.names=FALSE,quote=FALSE)
            cat("--->",filesaveTrend,"\n")
            
            flush.console()

        }
        
        
    }
    
    write.csv2(glmAn,filesaveAn,row.names=FALSE,quote=FALSE)
    cat("--->",filesaveAn,"\n")
    write.csv2(glmTrend,filesaveTrend,row.names=FALSE,quote=FALSE)
    cat("--->",filesaveTrend,"\n")
    
    
    flush.console()
    
    
    
}


################## 
###  Do your analysis

main.glm(donneesAll=dataCLEAN,tabsp=tabsp)



 

 
    
