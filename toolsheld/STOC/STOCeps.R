#!/usr/bin/env Rscript

#get arguments from the command line
args <- commandArgs(trailingOnly = TRUE)

if(length(args)!=2 ){
  print("usage: ./STOCeps.r <file> <LibraryPath>")
  q("no",0,"False")
}

#############################################################################

### Analyse des variations d'abondance des donnees issues du protocole STOCeps
###      Romain Lorrilliere et Diane Gonzalez
### analyse()

##############################################################################

#### V3.2
#### flexibilite des groupes pour le graphique groupe
#### correction de coquilles 


#### V3.1
#### mise a jour necessaire pour compatibilite avec maj package ggplot2
#### modification de l adresse du mirroir


### Verification de l'instalation des packages et instalation des manquants
### necessite une connexion internet

library(lme4)
library(arm)

### fonction principale qui permet de lancer l'analyse
## listSp: specification d'une liste d'espece pour ne pas analyser toutes les especes du jeu de donnees
## id_session: specification d'un id e la session de calcul
## annees: vecteur de la premiere et derniere annees si toutes les annees presentes dans le jeu de donnees ne doivent pas etre prises en compte
## estimateAnnuel: calculer les variations d'abondances des especes
## ICfigureGroupeSp:  afficher les intervalles de confiances sur la figure pas groupes de specialisations
## figure:  creer les figures
## concatFile:  concatener les fichiers presents dans le dossier donnees et les analyser independamment
## description:  avoir un graphique simple sans les deux panels de description des donnees brutes
## tendance sur graphique: afficher la tendance en texte sur les graphiques
## tendanceGroupSpe: calculer les indicateurs groupes de specialisations
analyse <- function(listSp=NULL,id_session=NULL,annees=NULL,
                                          estimateAnnuel=TRUE,
                 echantillon=1,methodeEchantillon="carre",ICfigureGroupeSp=TRUE,
                 figure=TRUE,sauvegardeDonnees=FALSE,description=TRUE,tendanceSurFigure=TRUE,tendanceGroupSpe = TRUE,
                 groupeNom = c("generaliste","milieux batis","milieux forestiers","milieux agricoles"),
                 groupeCouleur = c("black","firebrick3","chartreuse4","orange")) {
  
    cat("\n")
    start <- Sys.time() ## heure de demarage est utilisee comme identifiant par defaut
    id <- ifelse(is.null(id_session),format(start, "%Y%m%d-%HH%M"),id_session)
    cat(format(start, "%d-%m-%Y %HH%M"),"\n")
    cat("\n")
    if(estimateAnnuel) {
        ## importation du fichier donnee en entree
        data <- read.data(sauvegardeDonnees,id,args[1])
        ## si sous echantillonage
        if(!is.null(listSp) | echantillon != 1 | !is.null(annees))
            data <-  makeSousTab(data,listSp,echantillon,methodeEchantillon,vecannees=annees)
        ## netoyage des especes trop peu abondantes 
        data <- filtreAnalyse(data,sauvegardeDonnees)
    
    cat("2) DYNAMIQUE PAR ESPECES \n--------------------------------\n")
    ## calule des tendences par espece 
    main.glm(id,data,listSp,annees,echantillon,methodeEchantillon,figure,description,tendanceSurFigure,tendanceGroupSpe)
    }
}


### fonction d'importation des fichier des donnes
### fonction d'importation, de concatenation des fichiers 
### verification des nom de colonnes 
### verification des doublon de ligne
read.data <-  function(sauvegarde=TRUE,id=NA,file=NULL) {
    cat("1) IMPORTATION \n--------------\n\n")
    flush.console()
    ## tabsp : table de reference des especes
    tabsp <- read.csv2(paste(args[2],"espece.csv",sep="/"))
  #  tabsp <- tabsp[which(tabsp$especeOiseaux=="oui"),]
   	listFile <- file
    flush.console()
    spValide <- as.vector(tabsp$sp)
    ## import data
    for (f in listFile) {
        cat("<--",f,"\n")
        data <- read.csv(f)
        ## verification qu'il y a plusieur colonnes et essaye different separateur
        if(ncol(data)==1) {
            data <- read.csv(f,sep=";")
            if(ncol(data)==1) {
                data <- read.csv(f,sep=",")
                if(ncol(data)==1) {
                    data <- read.csv(f,sep=" ")
                    if(ncol(data)==1) {
                        data <- read.csv(f,sep="\t")
                    }
                }
            }
        }
        
        ## verifi type de tableau
        ## lesSp vecteur des especes dont le code espece 6 lettres est valide
        lesSp <- colnames(data)[colnames(data)%in%spValide]
        ## test si les especes sont en colonne
        spEnColonne <- length(lesSp)>0
        
        ## une colonne par espece 
        if(spEnColonne) {
            ## tabf table final en construction
           tabf <- data
          
            
        } else {
            ## sinon transformation du tableau pour obtenir les une colonne par espece
            tabf <- makeTableAnalyse(data)
             lesSp <- colnames(tabf)[colnames(tabf)%in%spValide]
        }
            ## non des colonne non utiliser car pas dans la liste des nom d'especes valides
            colonnePasUtile <- colnames(tabf)[!(colnames(tabf) %in% c(lesSp,"carre","annee"))]
            
            if(length(colonnePasUtile)>0) {
                cat("\n\n  ATTENTION COLONNE NON UTILISEE LORS DE L IMPORTATION !!!\n",
                    "Verifiez qu'il n'y a pas de code espece mal orthographie\n\n",sep="")
                nbPasUtile <- length(colonnePasUtile)
                ## affichage des colonne non utilisees
                i <- 0
                while(i<nbPasUtile){ 
                    cat(colonnePasUtile[(i+1):min((i+10),nbPasUtile)],"\n")  
                    i <- i+10
                }

                
                cat("\n")
                
                tabf <- tabf[,c("carre","annee",lesSp)]
            }
            
            ## nombre de colonne par espece
            countSp <- tapply(lesSp,lesSp,length)
            if(any(countSp>1)) {
                cat("!!!! ERREUR : PLUSIEURS COLONNES ESPECE DE MEME NOM !!!!\n")
                spDoublon <- countSp[countSp>1]
                
                for(n in 1:length(spDoublon))
                    cat(spDoublon[n],"colonnes",names(spDoublon)[n],"\n")
                stop("Verifiez vos fichiers de donnees")
            }
        ## initialisation de la table de sortie 
        if(f==listFile[1]) {
            tab <- tabf
        } else {
            ## verifier les noms des colonnes
            ## recherche des nouvelles especes
            newsp <- colnames(tabf)[!(colnames(tabf) %in% colnames(tab))]
            if(length(newsp)>0) {
                lesColonnes <- colnames(tab)
                for(s in newsp) tab <- data.frame(tab,0)
                colnames(tab) <- c( lesColonnes,newsp)
            }
            ## recherche des espece absente
            spabs <- colnames(tab)[!(colnames(tab) %in% colnames(tabf))]
            if(length(spabs)>0) {
                lesColonnes <- colnames(tabf)
                for(s in spabs) tabf <- data.frame(tabf,0)
                colnames(tabf) <- c(lesColonnes ,spabs)
            }
            ## assemblage des deux tables
            tabf <- tabf[,colnames(tab)]
            tab <- rbind(tab,tabf)
        }
    }
    ## recherche des doublons
    ligne <- tapply(paste(tab$carre,tab$annee,sep=" "),
                    paste(tab$carre,tab$annee,sep=" "),length)
    doublonligne <- ligne[ligne>1]
    if(length(doublonligne)>1) {
        cat("!!!! ERREUR : PLUSIEURS LIGNES REDONDANTES !!!!\n\n")
        if(length(doublonligne)<20) {
            spDoublon <- countSp[countSp>1]
            for(n in 1:length(doublonligne))
                cat(doublonligndee[n],"lignes pour",names(doublonligne)[n],"\n\n")
        } 
        stop("Verifiez vos fichiers de donnees")
    }
    
    
    
    return(tab)
}

## mise en colonne des especes
makeTableAnalyse <- function(data) {
    tab <- reshape(data
                  ,v.names="nombre"
                  ,idvar=c("carre","annee")      
                  ,timevar="espece"
                  ,direction="wide")
    tab[is.na(tab)] <- 0
                                        #  filename <- "touverUnNom"
                                        #  chemin <- paste(rep,filename,sep="/")
                                        #  write.table(tab, chemin) 
    colnames(tab) <- sub("nombre.","",colnames(tab))

    return(tab)
}

## netoie le jeux de donnees des especes jamais observee
filtreAnalyse <- function(tab,sauvegarde) {
    ## tabsp table reference des especes
    tabsp <- read.csv2(paste(args[2],"espece.csv",sep="/"))
    rownames(tabsp) <- tabsp$sp
    ## cas d'une seule especes (probleme de format)
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
    ## Affichage des especes rejetees
    if(length(colNull)>0){
        cat("\n",length(colNull)," Especes enlevees de l'analyse car abondance toujours egale a 0\n\n",sep="")
        tabNull <- data.frame(Code_espece = colNull, nom_espece = tabsp[colNull,"nom"])
        print(tabNull)  
        cat("\n\n",sep="")
        tab <- tab[,c("carre","annee",colConserve)]
    }
    ## filtrage des especes rare
    lfiltre <- filtreEspeceRare(tab)
    tab <- lfiltre$tab
    ## colConserve espece conservees
    colConserve <- lfiltre$colConserve
    ## colsupr espece trop rare et donc supprime de l'analyse
    colSupr <- lfiltre$colSupr
    
    ## affichage des especes retirer de l'analyse
    if(length(colSupr)>0){
        cat("\n",length(colSupr)," Especes enlevees de l' analyse car especes trop rares\n\n",sep="")
        tabSupr <- data.frame(Code_espece = colSupr, nom_espece = tabsp[colSupr,"nom"])
        print(tabSupr)  
        cat("\n\n",sep="")
        
          }
    if(length(colConserve)==0) {
        mess <- "Aucun espece elligible dans le jeu de donnees pour le calcul de variation d'abondance"
        stop(mess)
    }
    ## affichage des especes conservees pour l'analyse
    cat("\n",length(colConserve)," Especes conservees pour l'analyse\n\n",sep="")
    tabCons <- data.frame(Code_espece = colConserve, nom_espece = tabsp[colConserve,"nom"])
    print(tabCons)  
    cat("\n\n",sep="")
    if(sauvegarde) {
        nomFichier <- paste("Donnees/data.csv",sep="" )
     #   tab$carre <- paste("carre",as.numeric(as.factor(tab$carre)),sep="_")
        write.csv(tab,nomFichier)
        cat("-->",nomFichier,"\n")
        flush.console()
    }
    cat("\n\n")
    flush.console()
    return(tab)
}

## filtre les especes trop rare pour avoir confiance dans les analyse
## y0is0 premiere annee sans presence
## gsInf0 > 3 plus de 3 annees consecutives sans presence
## gsSup0 < 3 plus de 3 annees consecutuve avec des presence
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

## fonction general de calcul de la variation temporelle et de la tedence generale
## la fonction genere aussi les graphiques
main.glm <- function(id,donneesAll,listSp=NULL,annees=NULL,echantillon=1,methodeEchantillon=NULL,
                      figure=TRUE,description=TRUE,tendanceSurFigure=TRUE,tendanceGroupSpe = FALSE,
                     seuilOccu=14,seuilAbond=NA) {
    
  #donneAll = data;listSp=NULL;annees=NULL;echantillon=1;methodeEchantillon=NULL;
  #figure=TRUE;description=TRUE;tendanceSurFigure=TRUE;tendanceGroupSpe = FALSE;
  #seuilOccu=14;seuilAbond=NA
 # browser()
  require(arm)
    
    ## seuil de significativite
    seuilSignif <- 0.05
    
    ## tabsp table de reference des especes
    tabsp <- read.csv2(paste(args[2],"espece.csv",sep="/"))
  rownames(tabsp) <- tabsp$sp
  
    
    ##vpan vecteur des panels de la figure
    vpan <- c("Variation abondance")
    if(description) vpan <- c(vpan,"Occurrences","Abondances brutes")
    nomfile1 <- paste("Donnees/carre2001-2014REGION_",id,".csv",sep="")

    ## des variable annees
    annee <- sort(unique(donneesAll$annee))
    nbans <- length(annee)
    pasdetemps <- nbans-1
    firstY <- min(annee)
    lastY <- max(annee)

    ## Ordre de traitement des especes
    if (is.null(listSp)) {
    
        spValide <- as.vector(tabsp$sp)
        listSp <- colnames(donneesAll)[colnames(donneesAll)%in%spValide]
       # browser()
        tabsp2 <- tabsp[listSp,]
        
        listSp <- listSp[order(as.numeric(tabsp2$shortlist)*-1,tabsp2$sp)]
            }
    i <- 0
    nbSp <- length(listSp)
#   browser()
    ## analyse par espece
    for (sp in listSp) {
        i <- i + 1
        ## d data pour l'espece en court    
        d <- data.frame(abond=donneesAll[,sp],annee = donneesAll$annee,carre = donneesAll$carre)
        ## info sp
        nomSp <- as.character(tabsp[sp,"nom"])
        cat("\n(",i,"/",nbSp,") ",sp," | ", nomSp,"\n",sep="")
        flush.console()
        ## shortlist espece fait partie des especes indiactrice reconnue a l'echelle national
        shortlist <- tabsp[sp,"shortlist"]
        ## indic espece utilise pour le calcul des indicateurs par groupe de specialisation 
        indic <- tabsp[sp,"specialisation"]

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
        glm1 <- glm(formule,data=d,family=quasipoisson)
        sglm1 <- summary(glm1)
        coefan <- tail(matrix(coefficients(glm1)),pasdetemps)
        ## coefannee vecteur des variation d'abondance par annee back transformee
        coefannee <- rbind(1,exp(coefan))
        erreuran <- as.data.frame(tail(matrix(summary(glm1)$coefficients[,2]),pasdetemps))
        ## erreur standard back transformee
        erreurannee1 <- as.vector(rbind(0,erreuran*coefannee)[,1])
        pval <- c(1,tail(coefficients(sglm1),pasdetemps)[,4])
        
        ## calcul des intervalle de confiance
        glm1.sim <- sim(glm1)
        ic_inf_sim <- c(1,exp(tail(apply(coef(glm1.sim), 2, quantile,.025),pasdetemps)))
        ic_sup_sim <- c(1,exp(tail(apply(coef(glm1.sim), 2, quantile,.975),pasdetemps)))

        ## tab1 table pour la realisation des figures
        tab1 <- data.frame(annee,val=coefannee,
                           LL=ic_inf_sim,UL=ic_sup_sim,
                           catPoint=ifelse(pval<seuilSignif,"significatif",NA),pval,
                           courbe=vpan[1],
                           panel=vpan[1])
        ## netoyage des intervalle de confiance superieur tres tres grande                 
        tab1$UL <- ifelse( nb_carre_presence==0,NA,tab1$UL)
        tab1$UL <-  ifelse(tab1$UL == Inf, NA,tab1$UL)
        tab1$UL <-  ifelse(tab1$UL > 1.000000e+20, NA,tab1$UL)
        tab1$UL[1] <- 1
        tab1$val <-  ifelse(tab1$val > 1.000000e+20,1.000000e+20,tab1$val)
        ## indice de surdispersion
        dispAn <- sglm1$deviance/sglm1$null.deviance


        ## tabAn table de sauvegarde des resultats      
        tabAn <- data.frame(id,code_espece=sp, nom_espece = nomSp,indicateur = indic,annee = tab1$annee,
                            abondance_relative=round(tab1$val,3),
                            IC_inferieur = round(tab1$LL,3), IC_superieur = round(tab1$UL,3),
                            erreur_standard = round(erreurannee1,4),
                            p_value = round(tab1$pval,3),significatif = !is.na(tab1$catPoint),
                            nb_carre,nb_carre_presence,abondance=abond)
        
        ## GLM tendance generale sur la periode
        formule <- as.formula(paste("abond~ as.factor(carre) + annee",sep=""))
        md2 <- glm(formule,data=d,family=quasipoisson) 
        smd2 <- summary(md2)
        ## tendences sur la periode
        coefannee <- tail(matrix(coefficients(md2)),1)
        trend <- round(exp(coefannee),3)
        ## pourcentage de variation sur la periode
        pourcentage <- round((exp(coefannee*pasdetemps)-1)*100,2)
        pval <- tail(matrix(summary(md2)$coefficients[,4]),1)
        
        erreuran <- as.data.frame(tail(matrix(summary(md2)$coefficients[,2]),1))
        ## erreur standard 
        erreurannee2 <- as.vector(erreuran*exp(coefannee))[,1]
        pval <- tail(coefficients(smd2),1)[,4]
       
        
        ## calcul des intervalle de confiance
        md2.sim <- sim(md2)
        LL <- round(exp(tail(apply(coef(md2.sim), 2, quantile,.025),1)),3)
        UL <- round(exp(tail(apply(coef(md2.sim), 2, quantile,.975),1)),3)
        
        ## tab1t table utile pour la realisation des figures 
        tab1t <- data.frame(Est=trend,
                            LL , UL,
                            pourcent=pourcentage,signif=pval<seuilSignif,pval)

  
        trendsignif <- tab1t$signif
        pourcent <- round((exp(coefannee*pasdetemps)-1)*100,3)
        ## surdispersion
        dispTrend <- smd2$deviance/smd2$null.deviance
        
        ## classement en categorie incertain
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
        
        ## affectation des tendence EBCC
        catEBCC <- affectCatEBCC(trend = as.vector(trend),pVal = pval,ICinf=as.vector(LL),ICsup=as.vector(UL))
        ## table complete de resultats
        tabTrend <- data.frame(
            id,code_espece=sp,nom_espece = nomSp,indicateur = indic,
            nombre_annees = pasdetemps,premiere_annee = firstY,derniere_annee = lastY,
            tendance = as.vector(trend) ,  IC_inferieur=as.vector(LL) , IC_superieur = as.vector(UL),pourcentage_variation=as.vector(pourcent),
            erreur_standard = as.vector(round(erreurannee2,4)), p_value = round(pval,3),
            significatif = trendsignif,categorie_tendance_EBCC=catEBCC,mediane_occurrence=median( nb_carre_presence) ,
            valide = catIncert,raison_incertitude = raisonIncert)
        
       
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
    if(description) dgg <- rbind(tab1,tab2,tab3) else dgg <- tab1                       
    }
       
  
        
    }
    
    filesaveAn <-  paste("variationsAnnuellesEspece.tsv",
                         sep = "")
    filesaveTrend <-  paste("tendanceGlobalEspece.tsv",
                            sep = "")
    write.table(glmAn,filesaveAn,row.names=FALSE,quote=FALSE,sep="\t")
    write.table(glmTrend,filesaveTrend,row.names=FALSE,quote=FALSE,sep="\t")
    flush.console()
   
}

## renvoie la categorie EBCC de la tendance en fonction
## trend l'estimateur de la tendance
## pVal la p value
## ICinf ICsup l intervalle de confiance a 95 pourcent
affectCatEBCC <- function(trend,pVal,ICinf,ICsup){
    catEBCC <- ifelse(pVal>0.05,
                 ifelse(ICinf < 0.95 | ICsup > 1.05,"Incertain","Stable"),
                  ifelse(trend<1,
                        ifelse(ICsup<0.95,"Fort declin","Declin modere"),
                        ifelse(ICinf>1.05,"Forte augmentation","Augmentation moderee")))
    return(catEBCC)
}

analyse()