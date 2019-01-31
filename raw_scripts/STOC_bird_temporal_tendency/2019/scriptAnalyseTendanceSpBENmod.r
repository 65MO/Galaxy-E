#############################################################################

### Analyse des variations d'abondance des donnees issues du protocole STOCeps
###      Romain Lorrilliere 
### makeTrend() 

##############################################################################

#### V3.6 - 2017-10-10 
##            ajout du multi-thread


#### V3.5 - 2017-09-12


### Verification de l'instalation des packages et instalation des manquants
### necessite une connexion internet
ip <- installed.packages()[,1]
vecPackage <-  c("lme4","arm","ggplot2","speedglm")
for(p in vecPackage)
    if (!(p %in% ip))
        install.packages(pkgs=p,repos = "http://cran.univ-paris1.fr/", dependencies=TRUE) 

library(lme4)
library(arm)
library(ggplot2)
library(speedglm)
source("scriptExportation_ansiBENmod.r") #### 


### fonction principale qui permet de lancer l'analyse
## id: nom du dossier qui va �tre cr�er
## 
## listSp: specification d'une liste d'espece pour ne pas analyser toutes les especes du jeu de donnees   
## sp: liste d'esp�ce (vecteur)
## con:connection
## spExclude: choix de operateur
## spExcludePassage1:migrateur tardif (liste predefini)
## Import: ? query c'est pour faire l'extraction / brut donn�es d�j� extraite mais pas clean / clean avec un ficheir tout propre
## id_session: specification d'un id à la session de calcul
## annees: vecteur de la premiere et derniere annees si toutes les annees presentes dans le jeu de donnees ne doivent pas être prises en compte
## estimateAnnuel: calculer les variations d'abondances des espèces
## ICfigureGroupeSp:  afficher les intervalles de confiances sur la figure pas groupes de specialisations
## figure:  creer les figures
## concatFile:  concatener les fichiers presents dans le dossier donnees et les analyser independamment
## description:  avoir un graphique simple sans les deux panels de description des données brutes
## tendance sur graphique: afficher la tendance en texte sur les graphiques
## tendanceGroupSpe: calculer les indicateurs groupes de specialisations


makeTrend <- function(id="France",fileData="dataSTOCallSp_France_trend_2001_2017", ###### #### 
                      sp = NULL, 
                      con=NULL,user="postgres",password="postgre",import="query",assessIC=TRUE,champSp = "code_sp",  ######  ici indique le fichier d'import defini juste apr�s
                      spExclude=NULL,#findSp2Exclude(),
                      firstYear=2001,lastYear=2018,altitude_min=NULL,altitude_max=NULL,departement=NULL,
                      spExcluPassage1=c("MOTFLA","SAXRUB","OENOEN","ANTPRA","PHYTRO") ,seuilAbondance=.99,
                      ic = TRUE,carre = TRUE,
                      seuilSignif=0.05,output=FALSE,
                      operateur=c("Lorrilliere Romain","lorrilliere@mnhn.fr"),
                      ICfigureGroupeSp=TRUE, figure=TRUE,description=TRUE,tendanceSurFigure=TRUE,tendanceGroupSpe = FALSE,
                      ecritureStepByStep=FALSE,
                      groupeNom = c("generaliste","milieux batis","milieux forestiers","milieux agricoles"),
                      groupeCouleur = c("black","firebrick3","chartreuse4","orange")) {
    
    
    ##   con=NULL;query=TRUE;sp = c("AEGCAU","PASDOM","PANBIA","TROTRO","FICHYP","GRIVES","PROUT","ERIRUB");ic = TRUE;carre = TRUE;    ### BIZARRE LES ARGUMENTS ONT PAS LES MEMES NOMS
    ##   seuilSignif=0.05;output=FALSE;fileName="dataTrend_France_2001-2017";                                                         ### pas d'argument "query" mais "import" avant ????
    ##   firstYear=2001;lastYear=2017;altitude=800;departement=c(44,29,25);
    ##   operateur=c("Lorrilliere Romain","lorrilliere@mnhn.fr");id="France";
    ##   ICfigureGroupeSp=TRUE; figure=TRUE;description=FALSE;tendanceSurFigure=TRUE;tendanceGroupSpe = TRUE;
    ##   ecritureStepByStep=TRUE;
    ##   groupeNom = c("generaliste","milieux batis","milieux forestiers","milieux agricoles")
    ##   groupeCouleur = c("black","firebrick3","chartreuse4","orange")
    
    
    #############################################  INDICATION HEURE DE LANCEMENT DE LA FCT EN ENTETE AVEC SPACE AVANT APRES
    cat("\n")
    start <- Sys.time() ## heure de demarage est utilisée comme identifiant par defaut
    id <- ifelse(is.null(id),paste("Trend",format(start, "%Y%m%d-%HH%M"),sep="_"),id)
    cat(format(start, "%d-%m-%Y %HH%M"),"\n")
    cat("\n")
    
    
    ## creation d'un dossier pour y mettre les resultats
    dir.create(paste("Output/",id,sep=""))
    dir.create(paste("Output/",id,"/Incertain/",sep=""))
    
    ## importation des donnees
    if(import != "clean") {
        if(import=="query") {
            data <- makeTableCarre(con=NULL, user=user,mp=password,savePostgres=FALSE, output=TRUE, sp=sp, champSp=champSp, ##### FONCTION DU SCRIPT EXPORTATION MAIS PAS TROUVE, TROUVE D4AUTRE FCT sans le "simple"
                                         spExcluPassage1=spExcluPassage1  ,seuilAbondance=seuilAbondance,
                                         champsHabitat=FALSE, altitude_min=altitude_min,altitude_max = altitude_max, firstYear=firstYear, lastYear=lastYear,
                                         departement=departement,formatTrend = TRUE,isEnglish=FALSE,addAbscence=TRUE,
                                         id_output=fileData,encodingSave="utf-8") ##### indique le nom de la sortie fileData
            
        
             if(is.null(fileData)) {  ################## SI PAS DE DONNEE DONC POSSIBILITE D AVOIR DEJA LES DONNEES SORTIES ??
                      if(is.null(sp))    ####        SI PAS D ESPECE  INDIQUE OU SI NB ESPECE < 4  PQUOI ? 
                          suffSp <- "allSp" else if(length(sp)<4) suffSp <- paste(sp,collapse="-") else suffSp <- paste(length(sp),"sp",sep="") ### QUEL PBLME EN DESSOUS DE 4 SPS ??
                      fname <- paste("export/data_FrenchBBS_",fileData,"_",suffSp,"_",firstYear,"_",lastYear,".csv",sep="")
                    } else {
                        fname <- paste("export/",fileData,".csv",sep="")
                    }
                
                write.csv2(data,fname,row.names=FALSE)
            
        } else {
            if(import == "brut") {
                  if(is.null(fileData)) {
                      if(is.null(sp))                
                          suffSp <- "allSp" else if(length(sp)<4) suffSp <- paste(sp,collapse="-") else suffSp <- paste(length(sp),"sp",sep="")
                      fname <- paste("export/data_FrenchBBS_",fileData,"_",suffSp,"_",firstYear,"_",lastYear,".csv",sep="")
                    } else {
                        fname <- paste("export/",fileData,".csv",sep="")
                    }
                
                data <- read.csv2(fname)
            }
        }
        
        
  spList <- paste("('",paste(unique(data$espece),collapse="' , '"),"')",sep="") ### RECUPERR LES NOMS D SPS POUR EN FAIRE UNE LISTE
        querySp <- paste("
select s.pk_species as espece, french_name as nom, scientific_name as nomscientific, indicator as indicateur, habitat_specialisation_f as specialisation
from species as s, species_list_indicateur as i
where s.pk_species = i.pk_species and s.pk_species in ",spList," and niveau_taxo = 'espece' 
order by espece;",sep="")
        
        cat("\n QUERY  espece :\n--------------\n\n",querySp,"\n")  #### POUR LA PRESENTATION DU DOC AVEC LA LISTE SPS
        
        con <- openDB.PSQL(user=user,mp=password)  ##### FONCTION DANS LE SCRIPT EXTRACTION
        tabsp <- dbGetQuery(con, querySp)
        write.csv2(tabsp,paste("Output/",id,"/tabSpecies.csv",sep=""),row.names=FALSE) ###### PAS COMPRIS PQUOI RECHARGEMENT DE LA BASE
        
        cat("\n --> DONE !\n")
        dbDisconnect(con)
        ## si sous echantillonage
        
        ## netoyage des espèces trop peu abondantes	##### UTILISE ICI UNE AUTRE FONCTION "filtreAnalyse"
      
        data <- filtreAnalyse(data,tabsp)
        
   
        
        fname <- paste("Output/",id,"/",fileData,"_",id,"_clean.csv",sep="")
      ###  browser()
        write.csv2(data,fname,row.names=FALSE)
    } else {
        fname <- paste("Output/",id,"/",fileData,"_",id,"clean.csv",sep="")
        data <- read.csv2(fname)
            tabsp <-read.csv2(paste("Output/",id,"/tabSpecies.csv",sep=""))
   
    }
    
           


    if(!is.null(spExclude)) {

                                        # browser()
        data <- subset(data,!(espece %in% spExclude))
        tabsp <- subset(tabsp, !(espece %in% spExclude))

    }

  
    
    cat("2) DYNAMIQUE PAR ESPECES \n--------------------------------\n") ##### UTILISE ICI UNE AUTRE FONCTION "main.glm"
    ## calule des tendences par espece
    listSp <- sp
    annees <- firstYear:lastYear
    
    main.glm(id,data,assessIC=assessIC,listSp,tabsp,annees,figure,description,tendanceSurFigure,tendanceGroupSpe,seuilOccu=14,seuilAbond=NA,ecritureStepByStep)
    
    
    if(tendanceGroupSpe) {
        cat("3) DYNAMIQUE PAR GROUPE D'ESPECES \n--------------------------------\n") ##### UTILISE ICI UNE AUTRE FONCTION "analyseGroupe" 
        flush.console()
        analyseGroupe(id,tabsp,ICfigureGroupeSp,groupeNom = groupeNom,groupeCouleur=groupeCouleur)
    }
    
}




## mise en colonne des especes  et rajout de zero mais sur la base des carr�s selectionn� sans l'import
makeTableAnalyse <- function(data) {
    tab <- reshape(data
                  ,v.names="abond"
                  ,idvar=c("carre","annee")      
                  ,timevar="espece"
                  ,direction="wide")
    tab[is.na(tab)] <- 0
                                        #  filename <- "touverUnNom"
                                        #  chemin <- paste(rep,filename,sep="/")
                                        #  write.table(tab, chemin) 
    colnames(tab) <- sub("abond.","",colnames(tab))### remplace le premier pattern "nombre." par le second
    return(tab)
}



## filtre les especes trop rare pour avoir confiance dans les analyse
## y0is0 premiere annee sans presence
## gsInf0 > 3 plus de 3 annees consécutives sans presence
## gsSup0 < 3 plus de 3 annees consécutuve avec des presence
filtreEspeceRare <- function(tab) {
### analyse occurrences
    cat <- NULL
    ## calcul pour chaque colonne espece
    for(i in 3:ncol(tab)) {
        ## v abondance par annee
        v <- tapply(tab[,i],tab$annee,sum)
        ## v0 presence abscence par annee
        v0 <- ifelse(v>0,1,0)
        tx <- paste(v0,collapse="")
        
        p <- unlist(strsplit(tx,"0"))
        p <- p[p!=""]
        ## gsSup0 plus grande serie temporelle de presence
        gsSup0 <- max(nchar(p))
        ## gsInf0 plus grande serie temporelle d'absccence
        gsInf0 <- max(nchar(unlist(strsplit(tx,"1"))))
        ## y0is0 absence la premiere annee
        y0is0 <- v0[1]==0
        ## seuil d'exclusion
        cat <- c(cat,as.vector(ifelse( y0is0 | gsInf0 > 3 | gsSup0 < 3 ,"exclu","bon")))
    }
    names(cat) <- colnames(tab)[3:ncol(tab)]
    ## colonnes conservees
    colConserve <- names(cat)[cat=="bon"]
    ## colonnes supprimees
    colSupr <- names(cat)[cat=="exclu"]
    tab <- tab[,c("carre","annee",colConserve)]
    lfiltre <- list(tab=tab,colConserve=colConserve,colSupr=colSupr)
    return(lfiltre)

}

## netoie le jeux de donnees des especes jamais observee
filtreAnalyse <- function(tab,tabsp) {
  tab <- makeTableAnalyse(tab)
    ## cas d'une seule especes (problème de format)
    ## tabSum sommes de abondance par espece
    if(ncol(tab)==3) {
	tabSum <- sum(tab[,3])
	names(tabSum) <- colnames(tab)[3]
    } else {
        tabSum <- colSums(tab[,-(1:2)])
    }
    ## colNull espece toujours absente
    colNull <- names(which(tabSum==0))
    ## colconserve especec au moins presente 1 fois
    colConserve <- names(which(tabSum>0))
    ## Affichage des espèces rejetees
    if(length(colNull)>0){
        cat("\n",length(colNull)," Espèces enlevées de l'analyse car abondance toujours égale a 0\n\n",sep="")
        tabNull <- data.frame(Code_espece = colNull, nom_espece = tabsp[colNull,"nom"])
        print(tabNull)  
        cat("\n\n",sep="")
        tab <- tab[,c("carre","annee",colConserve)]
    }
    ## filtrage des especes rare
    lfiltre <- filtreEspeceRare(tab)#### OBLIGE DE LE NOMMER lfiltre ?
    tab <- lfiltre$tab
    ## colConserve espece conservees
    colConserve <- lfiltre$colConserve
    ## colsupr espece trop rare et donc supprimé de l'analyse
    colSupr <- lfiltre$colSupr
    
    ## affichage des especes retirer de l'analyse
    if(length(colSupr)>0){
        cat("\n",length(colSupr)," Espèces enlevées de l' analyse car espèces trop rares\n\n",sep="")
        tabSupr <- subset(tabsp,espece %in% colSupr ,select=c("espece","nom"))
        tabSupr <- tabSupr[order(tabSupr$espece),]
        print(tabSupr)  
        cat("\n\n",sep="")
        
    }
    if(length(colConserve)==0) {
        mess <- "Aucun espèce elligible dans le jeu de données pour le calcul de variation d'abondance"
        stop(mess)
    }
                                        #browser()
    tab <- melt(tab, id.vars=c("carre", "annee"))
    colnames(tab)[3:4] <- c("espece","abond")
    tab$annee <- as.numeric(as.character(tab$annee))
    return(tab)
}

## filtre les annees ou l espece n a pas ete observee
filtreAnnees <- function(tab) {
    sumAn <- by(tab[,3],tab$annee,sum)
    return(names(sumAn)[which(sumAn==0)])
    
}

## filtre les carres ayant jamais vu l espece
filtreCarres <- function(tab) {
    sumCarre <- tapply(tab[,3],tab$carre,sum)
    return(names(sumCarre)[which(sumCarre==0)])
}


## renvoie la categorie EBCC de la tendance en fonction
## trend l'estimateur de la tendance
## pVal la p value
## ICinf ICsup l intervalle de confiance a 95 pourcent
affectCatEBCC <- function(trend,pVal,ICinf,ICsup){
    catEBCC <- ifelse(pVal>0.05,
               ifelse(ICinf < 0.95 | ICsup > 1.05,"Incertain","Stable"),
               ifelse(trend<1,
               ifelse(ICsup<0.95,"Fort déclin","Déclin modéré"),
               ifelse(ICinf>1.05,"Forte augmentation","Augmentation modérée")))
    return(catEBCC)
}



## fonction general de calcul de la variation temporelle et de la tedence generale
## la fonction genere aussi les graphiques
main.glm <- function(id,donneesAll,assessIC= TRUE,listSp=NULL,tabsp,annees=NULL,figure=TRUE,description=TRUE,tendanceSurFigure=TRUE,tendanceGroupSpe = FALSE,
                     seuilOccu=14,seuilAbond=NA,ecritureStepByStep=FALSE) {

    ##  donneesAll=data;listSp=sp;annees=firstYear:lastYear;figure=TRUE;description=TRUE;tendanceSurFigure=TRUE;tendanceGroupSpe = FALSE;
    ##                   seuilOccu=14;seuilAbond=NA;ecritureStepByStep=TRUE
    
                                        #donneAll = data;listSp=NULL;annees=NULL;echantillon=1;methodeEchantillon=NULL;
                                        #figure=TRUE;description=TRUE;tendanceSurFigure=TRUE;tendanceGroupSpe = FALSE;
                                        #seuilOccu=14;seuilAbond=NA;ecritureStepByStep=FALSE
                                        # browser()
    require(arm)
    require(ggplot2)

    filesaveAn <-  paste("Output/",id,"/variationsAnnuellesEspece_",id,".csv",
                         sep = "")
    filesaveTrend <-  paste("Output/",id,"/tendanceGlobalEspece_",id,".csv",
                            sep = "")

    fileSaveGLMs <-  paste("Output/",id,"/listGLM_",id,sep = "")

    
    ## seuil de significativite
    seuilSignif <- 0.05
    
    ## tabsp table de reference des especes
    rownames(tabsp) <- tabsp$espece
    
    
    ##vpan vecteur des panels de la figure
    vpan <- c("Variation abondance")
    if(description) vpan <- c(vpan,"Occurrences","Abondances brutes")
                                        # nomfile1 <- paste("Donnees/carre2001-2014REGION_",id,".csv",sep="")

    ## des variable annees
    annee <- sort(unique(donneesAll$annee))
    nbans <- length(annee)
    pasdetemps <- nbans-1
    firstY <- min(annee)
    lastY <- max(annee)

    ## Ordre de traitement des especes
    spOrdre <- aggregate(abond~espece,data=donneesAll,sum)
    spOrdre <- merge(spOrdre,tabsp,by="espece")
    
    spOrdre <- spOrdre[order(as.numeric(spOrdre$indicateur),spOrdre$abond,decreasing = TRUE),]
    
    
    listSp <- spOrdre$espece
    i <- 0
    nbSp <- length(listSp)
                                        #	browser()
    ## analyse par espece
### browser()
    ## affichage des especes conservées pour l'analyse
    cat("\n",nbSp," Esp�ces conservées pour l'analyse\n\n",sep="")
    rownames(tabsp) <- tabsp$espece
    tabCons <- data.frame(Code_espece = listSp, nom_espece = tabsp[as.character(listSp),"nom"])
    print(tabCons)  
    cat("\n\n",sep="")
    flush.console()




    ## initialisation de la liste de sauvegarde

    


##browser()
    
    for (sp in listSp) {
###        if(sp=="PHYCOL")            browser()

        i <- i + 1
        ## d data pour l'espece en court    
        d <- subset(donneesAll,espece==sp)
        ## info sp
        nomSp <- as.character(tabsp[sp,"nom"])
        cat("\n(",i,"/",nbSp,") ",sp," | ", nomSp,"\n",sep="")
        flush.console()
#### shortlist espece fait partie des especes indiactrice reconnue à l'echelle national
### shortlist <- tabsp[sp,"shortlist"]
        ## indic espèce utilisé pour le calcul des indicateurs par groupe de specialisation 
        indic <- tabsp[sp,"indicateur"]

        ## Occurrence
        ## nb_carre nombre de carre suivie par annee
        nb_carre = tapply(rep(1,nrow(d)),d$annee,sum)
        ## nb_carre_presence nombre de carre de presence par annee
        nb_carre_presence = tapply(ifelse(d$abond>0,1,0),d$annee,sum)
        ## tab2 table de resultat d'analyse
        tab2 <- data.frame(annee=rep(annee,2),val=c(nb_carre,nb_carre_presence),LL = NA,UL=NA,
                           catPoint=NA,pval=NA,
                           courbe=rep(c("carre","presence"),each=length(annee)),panel=vpan[2])
        tab2$catPoint <- ifelse(tab2$val == 0,"0",ifelse(tab2$val < seuilOccu,"infSeuil",NA))
        
        ## abondance brut
        ## abond abondance par annee
        abond <- tapply(d$abond,d$annee,sum)
        ## tab3 tab3 pour la figure
        tab3 <- data.frame(annee=annee,val=abond,LL = NA,UL=NA,catPoint=NA,pval=NA,courbe=vpan[3],panel=vpan[3])
        tab3$catPoint <- ifelse(tab3$val == 0,"0",ifelse(tab3$val < seuilAbond,"infSeuil",NA))

        ## GLM variation d abondance
       formule <- as.formula("abond~as.factor(carre)+as.factor(annee)")
       if(assessIC) {##### OPTION A RENTRER AU DEBUT
           glm1 <- glm(formule,data=d,family=quasipoisson)
       } else {
           glm1 <- try(speedglm(formule,data=d,family=quasipoisson()))
           if(class(glm1)[1]=="try-error")
               glm1 <- glm(formule,data=d,family=quasipoisson) 
       }
       sglm1 <- summary(glm1)
       sglm1 <- coefficients(sglm1)
       sglm1 <- tail(sglm1,pasdetemps)
       coefan <- as.numeric(as.character(sglm1[,1]))
        ## coefannee vecteur des variation d'abondance par annee back transformee
        coefannee <- c(1,exp(coefan))
        erreuran <- as.numeric(as.character(sglm1[,2]))
        ## erreur standard back transformee
        erreurannee1 <- c(0,erreuran*exp(coefan))
        pval <- c(1,as.numeric(as.character(sglm1[,4])))
        
        ## calcul des intervalle de confiance
        if(assessIC) {
        glm1.sim <- sim(glm1)
        ic_inf_sim <- c(1,exp(tail(apply(coef(glm1.sim), 2, quantile,.025),pasdetemps)))
        ic_sup_sim <- c(1,exp(tail(apply(coef(glm1.sim), 2, quantile,.975),pasdetemps)))
        } else {
            ic_inf_sim <- NA
            ic_sup_sim <- NA
 
        }
        
        
        ## tab1 table pour la realisation des figures
        tab1 <- data.frame(annee,val=coefannee,
                           LL=ic_inf_sim,UL=ic_sup_sim,
                           catPoint=ifelse(pval<seuilSignif,"significatif",NA),pval,
                           courbe=vpan[1],
                           panel=vpan[1])
        ## netoyage des intervalle de confiance superieur très très grande
        if(assessIC) {
        tab1$UL <- ifelse( nb_carre_presence==0,NA,tab1$UL)
        tab1$UL <-  ifelse(tab1$UL == Inf, NA,tab1$UL)
        tab1$UL <-  ifelse(tab1$UL > 1.000000e+20, NA,tab1$UL)
        tab1$UL[1] <- 1
        tab1$val <-  ifelse(tab1$val > 1.000000e+20,1.000000e+20,tab1$val)
        }
        ## indice de surdispersion
       ## browser()
        if(assessIC) dispAn <- glm1$deviance/glm1$null.deviance else dispAn <- glm1$deviance/glm1$nulldev


        ## tabAn table de sauvegarde des resultats      
        tabAn <- data.frame(id,code_espece=sp, nom_espece = nomSp,indicateur = indic,annee = tab1$annee,
                            abondance_relative=round(tab1$val,3),
                            IC_inferieur = round(tab1$LL,3), IC_superieur = round(tab1$UL,3),
                            erreur_standard = round(erreurannee1,4),
                            p_value = round(tab1$pval,3),significatif = !is.na(tab1$catPoint),
                            nb_carre,nb_carre_presence,abondance=abond)
        
        ## GLM tendance generale sur la periode
        formule <- as.formula(paste("abond~ as.factor(carre) + annee",sep="")) ### ANNEE PAS DECLARE EN TANT QUE FACTEUR ?
          #  browser()
    
       
         if(assessIC) {
             md2 <- glm(formule,data=d,family=quasipoisson) }
        else {
                md2 <- try(speedglm(formule,data=d,family=quasipoisson()),silent=TRUE)

                if(class(md2)[1]=="try-error")
                    md2 <- glm(formule,data=d,family=quasipoisson)
            }

        
       smd2 <- summary(md2)
       smd2 <- coefficients(smd2)
       smd2 <- tail(smd2,1)
       
        ## tendences sur la periode
        coefan <- as.numeric(as.character(smd2[,1]))
        trend <- round(exp(coefan),3)
        ## pourcentage de variation sur la periode
        pourcentage <- round((exp(coefan*pasdetemps)-1)*100,2)
        pval <- as.numeric(as.character(smd2[,4]))
        
        erreuran <- as.numeric(as.character(smd2[,2])) 
        ## erreur standard 
        erreurannee2 <- erreuran*exp(coefan)
        
        
        ## calcul des intervalle de confiance
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
        
        ## tab1t table utile pour la realisation des figures 
        tab1t <- data.frame(Est=trend,
                            LL , UL,
                            pourcent=pourcentage,signif=pval<seuilSignif,pval)
        
        
        trendsignif <- tab1t$signif
        pourcent <- round((exp(coefan*pasdetemps)-1)*100,3)
        ## surdispersion

          if(assessIC) dispTrend <- md2$deviance/md2$null.deviance else dispTrend <- md2$deviance/md2$nulldev


        
        ## classement en categorie incertain
       # browser()
        if(assessIC) {
        if(dispTrend > 2 | dispAn > 2 | median( nb_carre_presence)<seuilOccu) catIncert <- "Incertain" else catIncert <-"bon"
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
        
        
        
        ## affectation des tendence EBCC
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


ouiOuNon <-function() {
    reponse <- readline(prompt= " oui ou non  > ")
    reponse <- toupper(sub(" ","",reponse))
    while(!(reponse %in% c("OUI","NON"))) {
        reponse <- readline(prompt= " oui ou non  > ")
        reponse <- toupper(sub(" ","",reponse))
    }
    return(reponse)
}


repChoix <- function(vecChoix) {
    mess <- paste(paste(vecChoix,collapse=" ou "),"> ", sep="")
    reponse <- readline(prompt= mess)
    while(!(reponse %in% vecChoix)) {
        reponse <- readline(prompt= mess)
        
    }
    return(reponse)
}


                                        # complete le fichier de sortie avec les info de description
                                        # fonction pour fixer un oublie de la premiere version du script
completeSortieDescription <- function(id,listSp,taban) {

    cat("Les donnees de description n'ont pas été enregistrer dans votre fichier de résultats\n")
    cat("Les descripteurs doivent être recalculer et necessite le tableau de donner\n")
    cat("A la fin de cette procedure le fichier de sortie variationsAnnuellesEspece_... sera mis à jour\n")

    listeFichier <- dir("Donnees/")
    if(length(listeFichier) > 1 ) {
	cat("Il y a plusieur fichiers dans le dossier 'Donnees'\n")
	cat(listeFichier)
	cat("Sont ils à concaténer ? oui ou non\n")
	reponse <- ouiOuNon()
	if(reponse == "OUI") {
            donneesAll <-  read.data()
	} else {
            cat("Quel est le fichier à traiter\n")
            cat("Notez le nom du fichier sans son extension\n")
            
            nomfichier <- repChoix(vecChoix)
            donneesAll <-  read.data(file=nomfichier)
	}
    } else { 
	if(length(listeFichier) == 1) { 
            cat("Le fichier de données suivant est il le bon ? \n")
            cat(listeFichier)
            cat("\n")
            reponse <- ouiOuNon()
            if(reponse == "OUI") {
                donneesAll <-  read.data()
            } else {
                mess <- "Veuillez mettre vos données dans le dossier 'Donnees'\n"	
                stop(mess)
            }
	} else { 
            mess <- "Veuillez mettre vos données dans le dossier 'Donnees'\n"	
            stop(mess)
	} 
    }

    for(sp in listSp) {
        d <- data.frame(abond=donneesAll[,sp],annee = donneesAll$annee,carre = donneesAll$carre)
        ## d data pour l'espece en court  
        ## Occurrence
        ## nb_carre nombre de carre suivie par annee
        nb_carre = tapply(rep(1,nrow(d)),d$annee,sum)
        ## nb_carre_presence nombre de carre de presence par annee
        nb_carre_presence = tapply(ifelse(d$abond>0,1,0),d$annee,sum)
        ## tab2 table de resultat d'analyse
        
        ## abondance brut
        ## abond abondance par annee
        abond <- tapply(d$abond,d$annee,sum)
        ## tab3 tab3 pour la figure
        vecAnnees <- min(d$annee):max(d$annee)
        tabDescriSp <- data.frame(code_espece=sp,annee=vecAnnees,nb_carre,nb_carre_presence,abondance = abond)
        if(sp == listSp[1]) tabDescri <- tabDescriSp else tabDescri <- rbind(tabDescri,tabDescriSp)
    }
    taban$idmerge <- paste(taban$code_espece,taban$annee,sep="_")
    tabDescri$idmerge <- paste(tabDescri$code_espece,tabDescri$annee,sep="_")
    tabDescri <- subset(tabDescri, select = c("idmerge","nb_carre","nb_carre_presence","abondance"))
    glmAn <- merge(taban,tabDescri,by="idmerge",all=TRUE)
    glmAn <- glmAn[,-1]
    
    filesaveAn <-  paste("Resultats/",id,"/variationsAnnuellesEspece_",id,".csv",
                         sep = "")
    write.csv2(glmAn,filesaveAn,row.names=FALSE,quote=FALSE)
    
    cat("--->",filesaveAn,"\n")
    flush.console()


    return(glmAn)


}


                                        # la figure realiser par ggplot

ggplot.espece <- function(dgg,tab1t,id,serie=NULL,sp,valide,nomSp=NULL,description=TRUE,
                          tendanceSurFigure=TRUE,seuilOccu=14, vpan) {

                                        #  serie=NULL;nomSp=NULL;description=TRUE;valide=catIncert
                                        #  tendanceSurFigure=TRUE;seuilOccu=14
    require(ggplot2)

    figname<- paste("Output/",id,"/",ifelse(valide=="Incertain","Incertain/",""),
                    sp,"_",id,serie, ".png",
                    sep = "")
    ## coordonnée des ligne horizontal de seuil pour les abondances et les occurences
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
            ylab("") + xlab("Année")+ ggtitle(titre) +
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
            ylab("") + xlab("Année")+ ggtitle(titre) +
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

## moyenne geometrique pondere
geometriqueWeighted <- function(x,w=1) exp(sum(w*log(x))/sum(w))


## Analyse par groupe de specialisation à partir des resulats de variation d'abondance par especes
## id identifiant de la session
## ICfigureGroupeSp affichage des intervalles de confiances sur la figure
## correctionAbondanceNull correction des abondance NULL
analyseGroupe <- function(id=NA,tabsp,ICfigureGroupeSp=TRUE,powerWeight=2,
                          correctionAbondanceNull = 0.000001,
                          groupeNom = c("generaliste","milieux batis","milieux forestiers","milieux agricoles"),
                          groupeCouleur = c("black","firebrick3","chartreuse4","orange")) {
    
    
    nameFile <- paste("Output/",id,"/variationsAnnuellesEspece_",id,".csv",sep="" )
    nameFileTrend <- paste("Output/",id,"/tendanceGlobalEspece_",id,".csv",sep="" )
    ## donnees variations d'abondance annuels
    donnees <-  read.csv2(nameFile)
    ## donnees tendences globales
    donneesTrend <- read.csv2(nameFileTrend)
    donneesTrend <- subset(donneesTrend, select = c(code_espece,valide,mediane_occurrence))
    ## table de reference espece
    tabsp <- subset(tabsp, select= c(sp,nom,indicateur, specialisation))
    donnees <- merge(donnees,donneesTrend,by="code_espece")
    donnees <- merge(donnees,tabsp,by.x="code_espece",by.y="sp")
    ## table de correspondance de biais en fonction des medianes des occuerences
    tBiais <- read.csv("Librairie/biais.csv")
    nameFileSpe <-  paste("Output/",id,"/variationsAnnuellesGroupes_",id,
                          ".csv",sep="" )
    nameFileSpepng <-  paste("Output/",id,"/variationsAnnuellesGroupes_",id,
                             ".png",sep="" )
    
    grpe <- donnees$specialisation
    
    ## recherche d'un maximum
    ff <- function(x,y) max(which(y<=x))
    ## poids du à l'incertitude 
    IncertW <- ifelse(donnees$valide=="Incertain",tBiais$biais[sapply(as.vector(donnees$mediane_occurrence),ff,y=tBiais$occurrenceMed)],1)
    ## poids du à la qualité de l'estimation
                                        #   erreur_stW <- 1/((donnees$erreur_st+1)^powerWeight)
                                        #	erreur_stW <- ifelse( is.na(donnees$IC_superieur),0,erreur_stW)
    erreur_stW <- ifelse(is.na(donnees$IC_superieur),0,1)
    ## poids total
    W <- IncertW * erreur_stW
    
    ## variable de regroupement pour les calculs
    grAn <- paste(donnees$specialisation,donnees$annee,sep="_")
    ## data frame pour le calcul
    dd <- data.frame(grAn,annee = donnees$annee, grpe,W,ab=donnees$abondance_relative,ICinf= donnees$IC_inferieur, ICsup= ifelse(is.na(donnees$IC_superieur),10000,donnees$IC_superieur)) 
    ## table resumer de tous les poids
    ddd <- data.frame(code_espece = donnees$code_espece,nom_espece = donnees$nom_espece,annee = donnees$annee, 
                      groupe_indicateur = grpe,
                      poids_erreur_standard = round(erreur_stW,3), poids_incertitude = round(IncertW,3),poids_final = round(W,3),
                      abondance_relative=donnees$abondance_relative,
                      IC_inferieur= donnees$IC_inferieur, 
                      IC_superieur= ifelse(is.na(donnees$IC_superieur),10000,donnees$IC_superieur),
                      valide = donnees$valide, mediane_occurrence = donnees$mediane_occurrence) 

    nomFileResum <- paste("Resultats/",id,"/donneesGroupes_",id,
                          ".csv",sep="" )
    write.csv2(ddd,nomFileResum,row.names=FALSE)
    cat(" <--",nomFileResum,"\n")
    
    ## calcul des moyennes pondéré par groupe par an et pour les estimates et les IC	
    for(j in 5:7) dd[,j] <- ifelse(dd[,j]==0,correctionAbondanceNull,dd[,j])	
    ag <- apply(dd[,5:7], 2,
                function(x) {
                    sapply(split(data.frame(dd[,1:4], x), dd$grAn),
                           function(y) round(geometriqueWeighted(y[,5], w = y$W),3))
                })
    ##	gg <- subset(dd,as.character(dd$grAn)=="milieux forestier_2014")  #############################################################

    ag <- ifelse(is.na(ag),1,ag)
    ag <- as.data.frame(ag)
    ag$grAn <-  rownames(ag)
    dbon <- subset(donnees,valide=="bon")
    dIncert <- subset(donnees,valide=="Incertain")
    ## calcul nombre d'espece "bonne" pour le calcul
    bon <- tapply(dbon$nom,dbon$specialisation,FUN=function(X)length(unique(X)) )
    bon <- ifelse(is.na(bon),0,bon)
    tbon <- data.frame(groupe=names(bon),bon)
    ## calcul nombre d'especes "incertaines" pour le calcul
    Incert <- tapply(dIncert$nom,dIncert$specialisation,FUN=function(X)length(unique(X)) )
    Incert <- ifelse(is.na(Incert),0,Incert)
    tIncert <- data.frame(groupe=names(Incert),Incertain=Incert)

    tIncert <- merge(tIncert,tbon,by="groupe")
    
    ## table de resultat
    da <- merge(unique(dd[,1:3]),ag,by="grAn")[,-1]
    colnames(da) <- c("annee","groupe","abondance_relative","IC_inferieur","IC_superieur")

    da$annee <- as.numeric(da$annee)
    da <-  merge(da,tIncert,by="groupe")
    da <- subset(da, groupe != "non")
    colnames(da)[6:7] <-  c("nombre_especes_incertaines","nombre_espece_bonnes")
    a <- data.frame(id,da)
    write.csv2(da,file=nameFileSpe,row.names=FALSE,quote=FALSE)

    cat(" <--",nameFileSpe,"\n")
    yearsrange <- c(min(da$annee),max(da$annee))
    
    ## figure par ggplot2
    titre <- paste("Variation de l'indicateur groupe de spécialisation",sep="")

    vecCouleur <- setNames(groupeCouleur,groupeNom)
                                        #browser()
    p <- ggplot(data = da, mapping = aes(x = annee, y = abondance_relative, colour=groupe,fill=groupe))
    p <- p + geom_hline(aes(yintercept = 1), colour="white", alpha=1,size=1.2) 
    if(ICfigureGroupeSp)
        p <- p + geom_ribbon(mapping=aes(ymin=IC_inferieur,ymax=IC_superieur),linetype=2,alpha=.1,size=0.1) 
    p <- p + geom_line(size=1.5)
    p <- p +  ylab("") + xlab("Année")+ ggtitle(titre) 
    if(!is.null(groupeNom)) p <- p + scale_colour_manual(values=vecCouleur, name = "" )+
                                scale_x_continuous(breaks=unique(da$annee))
    if(!is.null(groupeNom)) p <- p +  scale_fill_manual(values=vecCouleur, name="")
    p <- p +  theme(panel.grid.minor=element_blank(), panel.grid.major.y=element_blank()) 
    ggsave(nameFileSpepng, p,width=17,height=10,units="cm")

                                        #   cat(" <==",nameFileSpepng,"\n")
    
    ## calul pour chaque groupe une pente de regression de la variation d'abondance
    vecSpe <- unique(da$groupe)
    datasum <- data.frame(groupe=NULL,tendance=NULL,pourcentage_variation=NULL)
    for(spe in 1:4){
                                        # print(spe)
        subtab <- subset(da,groupe==vecSpe[spe])
        if(nrow(subtab)>1) {
            sumlm <- summary(lm(abondance_relative~annee,data=subtab))
            subdatasum <- data.frame(groupe=vecSpe[spe],
                                     tendance=round(sumlm$coefficients[2,1],3),
                                     pourcentage_variation=round(sumlm$coefficients[2,1]*(nrow(subtab)-1)*100,3))
            datasum <- rbind(datasum,subdatasum)
            
        }
        
    }
    datasum <- merge(datasum,tIncert,by="groupe")
    datasum <- data.frame(id,datasum)
                                        #datasum$cat_tendance_EBCC <- affectCatEBCC(trend,pVal,ICinf,ICsup
    namefilesum <- paste("Resultats/",id,"/tendancesGlobalesGroupes_",id,
                         ".csv",sep="" )
    write.csv2(datasum,file=namefilesum,row.names=FALSE,quote=FALSE)
    cat(" <--",namefilesum,"\n")
}




####################################




## fonction pour faire les figures espece

figure.espece <- function(id,serie=NULL,listSp=NULL,description=TRUE,tendanceSurFigure=TRUE,seuilOccu=14,annees=NULL) {
    ##vpan vecteur des panels de la figure
    vpan <- c("Variation abondance")
    if(description) vpan <- c(vpan,"Occurrences","Abondances brutes")
    
    
    ## tabsp table de reference des especes
    tabsp <- read.csv2("Librairie/espece.csv")
    rownames(tabsp) <- tabsp$sp
    
    
    ##vpan vecteur des panels de la figure
    vpan <- c("Variation abondance")
    if(description) vpan <- c(vpan,"Occurrences","Abondances brutes")
    
    ## import des fichiers de résultats 
    filesaveAn <-  paste("Resultats/",id,"/variationsAnnuellesEspece_",id,".csv",
                         sep = "")
    filesaveTrend <-  paste("Resultats/",id,"/tendanceGlobalEspece_",id,".csv",
                            sep = "")
    taban <- read.csv2(filesaveAn)
    tabtrend <- read.csv2(filesaveTrend)

    if(is.null(annees)) { 
        vecAnnees <- min(taban$annee):max(taban$annee)
    } else {
        vecAnnees <- annees
    }

    ## Ordre de traitement des especes
    if (is.null(listSp)) {
        listSp <- as.character(unique(taban$code_espece))
    }

    if(description) {
        if(!("nb_carre" %in% colnames(taban))) {
            listSpTotal <- as.character(unique(taban$code_espece))
            taban <- completeSortieDescription(id,listSpTotal,taban)
        } 
    }

    i <- 0
    nbSp <- length(listSp)
                                        #browser()
    ## analyse par espece
    for (sp in listSp) {
        i <- i + 1
        ## info sp
        nomSp <- as.character(tabsp[sp,"nom"])
        cat("\n(",i,"/",nbSp,") ",sp," | ", nomSp,"\n",sep="")
        flush.console()
	
        tabanSp <- subset(taban,code_espece == sp)
        tabtrendSp <- subset(tabtrend,code_espece == sp)

        if(description) {
            tab2 <- data.frame(annee=rep(tabanSp$annee,2),val=c(tabanSp$nb_carre,tabanSp$nb_carre_presence),LL = NA,UL=NA,
                               catPoint=NA,pval=NA,
                               courbe=rep(c("carre","presence"),each=length(vecAnnees)),panel=vpan[2])
            tab2$catPoint <- ifelse(tab2$val == 0,"0",ifelse(tab2$val < seuilOccu,"infSeuil",NA))
            tab3 <- data.frame(annee=tabanSp$annee,val=tabanSp$abondance,LL = NA,UL=NA,catPoint=NA,pval=NA,courbe=vpan[3],panel=vpan[3])
            tab3$catPoint <- ifelse(tab3$val == 0,"0",NA)
        }
        tab1 <- data.frame(annee=tabanSp$annee,val=tabanSp$abondance_relative,
                           LL=tabanSp$IC_inferieur,UL=tabanSp$IC_superieur,
                           catPoint=ifelse(tabanSp$significatif,"significatif",NA),pval = tabanSp$p_val,
                           courbe=vpan[1],
                           panel=vpan[1])
        ## netoyage des intervalle de confiance superieur très très grande				   
                                        #   tab1$UL <- ifelse( nb_carre_presence==0,NA,tab1$UL)
        tab1$UL <-  ifelse(tab1$UL == Inf, NA,tab1$UL)
        tab1$UL <-  ifelse(tab1$UL > 1.000000e+20, NA,tab1$UL)
        tab1$UL[1] <- 1
        tab1$val <-  ifelse(tab1$val > 1.000000e+20,1.000000e+20,tab1$val)
        
        ## tab1t table utile pour la realisation des figures 
        tab1t <- data.frame(Est=tabtrendSp$tendance,
                            LL= tabtrendSp$IC_inferieur , UL=tabtrendSp$IC_superieur,
                            pourcent=tabtrendSp$pourcentage_variatio,signif=tabtrendSp$significatif,pval=tabtrendSp$p_value,
                            valide = tabtrendSp$valide)

	## table pour graphe en panel par ggplot2
        if(description)	dgg <- rbind(tab1,tab2,tab3) else dgg <- tab1
    	## les figures     
        
        ggplot.espece(dgg,tab1t,id,serie,sp,valide=tabtrendSp$valide,nomSp,description,tendanceSurFigure,seuilOccu=14,vpan = vpan)
    }
    
}


##' Recherche des especes deja traiter quand le modele doit être relancé 
##'
##' .. content for \details{} ..
##' @title findSp2Exclude
##' @param rep CHAR id du batch a checker 
##' @return CHAR[] vecteur des espèces à exclure
##' @author Romain Lorrilliere
findSp2Exclude <- function(id="test44_FRANCE_2017") {
                                        # id <- "test44_FRANCE_2017"
    rep <- paste("Output/",id,sep="")
    vecfile <- dir(rep)
    vecfile <- vecfile[grep(".png",vecfile)]
    vecSp <- substr(vecfile,1,6)
    

}





testParall <- function() {
machin<-1:500000
cores=detectCores()
cl <- makeCluster(cores[1]-1) #not to overload your computer (défini le nombre de cœurs à utiliser)
registerDoParallel(cl)
ptm<-proc.time()
truc2<-c()
finalMatrix <- foreach(i=1:1000, .combine=cbind) %dopar% {
  bidule<-machin[i]+sample(1000:2000,1)
}
truc2<-as.vector(finalMatrix[,1:500000])
proc.time()-ptm
#stop cluster
stopCluster(cl)

    }
