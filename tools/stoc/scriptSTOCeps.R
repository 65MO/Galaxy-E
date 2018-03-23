#!/usr/bin/env Rscript

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
### Pas utile sous forme d'outil galaxy
#ip <- installed.packages()[,1]
#vecPackage <-  c("lme4","arm","ggplot2")
#for(p in vecPackage)
#    if (!(p %in% ip))
#        install.packages(pkgs=p,repos = "http://cran.univ-paris1.fr/", dependencies=TRUE) 


args <- commandArgs(trailingOnly = TRUE)

library(lme4)
library(arm)
library(ggplot2)



### fonction principale qui permet de lancer l'analyse
## listSp: specification d'une liste d'espece pour ne pas analyser toutes les especes du jeu de donnees
## id_session: specification d'un id a la session de calcul
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
                 figure=TRUE,sauvegardeDonnees=FALSE, concatFile=TRUE,description=TRUE,tendanceSurFigure=TRUE,tendanceGroupSpe = TRUE,
                 groupeNom = c("generaliste","milieux batis","milieux forestiers","milieux agricoles"),
                 groupeCouleur = c("black","firebrick3","chartreuse4","orange")) {
  
  
#  listSp=NULL;id_session=NULL;annees=NULL;
#  estimateAnnuel=TRUE;
#  echantillon=1;methodeEchantillon="carre";ICfigureGroupeSp=TRUE;
#  figure=TRUE;sauvegardeDonnees=FALSE; concatFile=TRUE;description=TRUE;tendanceSurFigure=TRUE;tendanceGroupSpe = TRUE
  
  

    if(concatFile) {
        cat("\n")
        start <- Sys.time() ## heure de demarage est utilisee comme identifiant par defaut
        id <- ifelse(is.null(id_session),format(start, "%Y%m%d-%HH%M"),id_session)
        cat(format(start, "%d-%m-%Y %HH%M"),"\n")
        cat("\n")
		## verification de la presence des repertoires donnees et resultats 
        checkRepertories()
		## creation d'un dossier pour y mettre les resultats
        dir.create(paste("Resultats/",id,sep=""))
        dir.create(paste("Resultats/",id,"/Incertain/",sep=""))
        if(estimateAnnuel) {
			## importation des donnees
            data <- read.data(sauvegardeDonnees,id)
			## si sous echantillonage
            if(!is.null(listSp) | echantillon != 1 | !is.null(annees))
                data <-  makeSousTab(data,listSp,echantillon,methodeEchantillon,vecannees=annees)
			## netoyage des especes trop peu abondantes	
            data <- filtreAnalyse(data,sauvegardeDonnees)
            #print(data) 
		cat("2) DYNAMIQUE PAR ESPECES \n--------------------------------\n")
		## calule des tendences par espece
        cat(listSp) 
        main.glm(id,data,listSp,annees,echantillon,methodeEchantillon,figure,description,tendanceSurFigure,tendanceGroupSpe)
        }
        if(tendanceGroupSpe) {
            cat("3) DYNAMIQUE PAR GROUPE D'ESPECES \n--------------------------------\n")
            flush.console()
            analyseGroupe(id,ICfigureGroupeSp,groupeNom = groupeNom,groupeCouleur=groupeCouleur)
        }
        
    } else {
        if (is.null(id_session)) {
			## recuperation des nom de session a partir des nom de fichiers
            id_session <- dir("Donnees/")
            id_session <- id_session[grep(".csv",id_session)]
            id_session <- substr(id_session,1,nchar(id_session)-4)
        }
        cat(id_session,sep="\n")
        cat("\n##################\n")
        flush.console()
		## analyse independante pour chaque fichier
        for(id in id_session) {
            cat("\n\n--  ",id,"  --\n-------------------\n\n")
            flush.console()
            start <- Sys.time()
             cat(format(start, "%d-%m-%Y %HH%M"),"\n")
            cat("\n")
            flush.console()
            ## verification de la presence des repertoire donnees et resultats 
        	checkRepertories()
            dir.create(paste("Resultats/",id,sep=""))
            dir.create(paste("Resultats/",id,"/Incertain/",sep=""))
            nomFichier <- paste("Donnees/",id,".csv",sep="")
            if(estimateAnnuel) {
				## importation des donnees
                data <- read.data(sauvegardeDonnees,id,file=nomFichier)
				## si sous echantillonage
                if(!is.null(listSp) | echantillon != 1 | !is.null(annees))
                    data <-  makeSousTab(data,listSp,echantillon,methodeEchantillon,vecannees=annees)
				## netoyage des especes trop peu abondantes	
				data <- filtreAnalyse(data,sauvegardeDonnees)
				cat("2) DYNAMIQUE PAR ESPECES \n--------------------------------\n")
				## calule des tendences par espece 
                main.glm(id,data,listSp,annees,echantillon,methodeEchantillon,figure,description,tendanceSurFigure,tendanceGroupSpe)
            }
            if(tendanceGroupSpe) {
                cat("2) DYNAMIQUE PAR GROUPE D'ESPECES \n--------------------------------\n")
                flush.console()
                analyseGroupe(id,ICfigureGroupeSp,groupeNom = groupeNom,groupeCouleur=groupeCouleur )
            }

        }
    }
}




### verification de la presences des repertoire necessaire au script
### si absence la fonction les cree
checkRepertories <-  function() {
### si pas de rerpertoire les creer
    contenuDir <-  dir()
    if (!("Resultats" %in% contenuDir))
        dir.create("Resultats")
    if (!("Donnees" %in% contenuDir)) {
        cat("  CORRECTION ARCHITECTURE \n----------------------\n\n")
        flush.console()
        mess <- "ATTENTION DOSSIER  'Donnees'  ABSENT\n"
        cat(mess)
        dir.create("Donnees")
        mess <- "DOSSIER  'Donnees'  cree\n ==> Veuillez y mettre vos donnees\n"
        stop(mess)
    }
}

### fonction d'importation des fichier des donnes
### fonction d'importation, de concatenation des fichiers 
### verification des nom de colonnes 
### verification des doublon de ligne
read.data <-  function(sauvegarde=TRUE,id=NA,file=NULL) {
    checkRepertories()
    cat("1) IMPORTATION \n--------------\n\n")
    flush.console()
	## tabsp : table de reference des especes
	tabsp <- read.csv2(paste(args[1],"espece.csv",sep="/")) #("Librairie/espece.csv")
  #  tabsp <- tabsp[which(tabsp$especeOiseaux=="oui"),]
    if(is.null(file)) listFile <- paste("Donnees",dir("Donnees/"),sep="/") else listFile <- file
    cat(length(listFile),"fichier(s)\n")
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

## sous jeux de donnees si choix d espece d annee ou d un pourcentage de carres
makeSousTab <- function(tab,vecSp=NULL,echantillon=1,
                        methodeEchantillon="carre",vecannees=NULL) {
    cat("  -- Fabrication du sous jeu de donnees --\n")
    flush.console()
   ## reduction de la table a certaine especes
   if(!is.null(vecSp)) {
        cat("     selection",length(vecSp),"espece(s):\n -> ")
        cat(vecSp)
        cat("\n")
        tab <- data.frame(carre = tab$carre,annee = tab$annee,tab[,vecSp])
        colnames(tab) <- c("carre","annee",vecSp)
    }
	## reduction de la table pour certaines annees
    if(!is.null(vecannees)) {
        tab <- subset(tab,annee>=vecannees[1] & annee <= vecannees[2])
        
    }
	## reduction de la table par une proportion de carre suivie
    if(echantillon != 1) {
        if(echantillon < 1 & echantillon >0) {
            nbinit <- nrow(tab)
            if(methodeEchantillon == "global") {
                nb <- round(nrow(tab)*echantillon)
                cat("     echantillonage",echantillon*100,
                    "% des donnees par la methode",methodeEchantillon,"\n")
                cat(" -> conservation de",nb,"lignes sur",nbinit,"\n")
                flush.console()
                tab <- tab[sample(1:nrow(tab))[1:nb],]
            } else {
                if (methodeEchantillon =="carre") {
                    cat("     echantillonage",echantillon*100,
                        "% des carrees par la methode",methodeEchantillon,"\n")
                    nbcarreinit <- length(unique(tab$carre))
                    chat=sample(unique(tab$carre),
                        length(unique(tab$carre))*echantillon,replace=F)
                    cat(" -> conservation de",length(chat),"carrees sur",
                        nbcarreinit)
                    tab=subset(tab, subset = carre %in% chat)
                    cat(" (",nrow(tab)," lignes sur ",nbinit,")\n",sep="")
                } else {
                    
                    stop("Methode d echantillonnage non reconnue")
                }
            }
        } else {
            stop("Le parametre d ehantillonnage est une proportion : il  doit etre superieur a 0 et inferieur a 1")
        }
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
    if (ncol(tab)<3){
        err<-"Aucune espece elligible dans le jeu de donnees pour le calcul de variation d'abondance"
        stop(err)
    }
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
filtreAnalyse <- function(tab,sauvegarde) {
	## tabsp table reference des especes
	tabsp <- read.csv2(paste(args[1],"espece.csv",sep="/"))  #("Librairie/espece.csv")
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
                        ifelse(ICsup<0.95,"Fort declin","Declin modere"),
                        ifelse(ICinf>1.05,"Forte augmentation","Augmentation moderee")))
    return(catEBCC)
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
    require(ggplot2)
	
	## seuil de significativite
	seuilSignif <- 0.05
	
	## tabsp table de reference des especes
    tabsp <- read.csv2(paste(args[1],"espece.csv",sep="/")) #("Librairie/espece.csv")
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
#	browser()
	## analyse par espece
    for (sp in listSp) {
        cat("\n",sp,"\n")
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
    if(description)	dgg <- rbind(tab1,tab2,tab3) else dgg <- tab1
    	## les figures     
         
         ggplot.espece(dgg,tab1t,id,serie=NULL,sp,valide=catIncert,nomSp,description,tendanceSurFigure,seuilOccu=14,vpan = vpan)
                   
        }
       
  
        
    }
    
    filesaveAn <-  paste("Resultats/",id,"/variationsAnnuellesEspece_",id,".csv",
                         sep = "")
    filesaveTrend <-  paste("Resultats/",id,"/tendanceGlobalEspece_",id,".csv",
                            sep = "")
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

## fonction pour faire les figures espece

figure.espece <- function(id,serie=NULL,listSp=NULL,description=TRUE,tendanceSurFigure=TRUE,seuilOccu=14,annees=NULL) {
       ##vpan vecteur des panels de la figure
       vpan <- c("Variation abondance")
       if(description) vpan <- c(vpan,"Occurrences","Abondances brutes")
       
       
## tabsp table de reference des especes
    tabsp <- read.csv2(paste(args[1],"espece.csv",sep="/")) #("Librairie/espece.csv")
    rownames(tabsp) <- tabsp$sp
  
    
    ##vpan vecteur des panels de la figure
    vpan <- c("Variation abondance")
    if(description) vpan <- c(vpan,"Occurrences","Abondances brutes")
   
## import des fichiers de resultats 
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
		## netoyage des intervalle de confiance superieur tres tres grande				   
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


# complete le fichier de sortie avec les info de description
# fonction pour fixer un oublie de la premiere version du script
completeSortieDescription <- function(id,listSp,taban) {

cat("Les donnees de description n'ont pas ete enregistrer dans votre fichier de resultats\n")
cat("Les descripteurs doivent etre recalculer et necessite le tableau de donner\n")
cat("A la fin de cette procedure le fichier de sortie variationsAnnuellesEspece_... sera mis a jour\n")

listeFichier <- dir("Donnees/")
if(length(listeFichier) > 1 ) {
	cat("Il y a plusieur fichiers dans le dossier 'Donnees'\n")
	cat(listeFichier)
	cat("Sont ils a concatener ? oui ou non\n")
	reponse <- ouiOuNon()
	if(reponse == "OUI") {
		donneesAll <-  read.data()
	} else {
		cat("Quel est le fichier a traiter\n")
		cat("Notez le nom du fichier sans son extension\n")
		
		nomfichier <- repChoix(vecChoix)
		donneesAll <-  read.data(file=nomfichier)
	}
} else { 
	if(length(listeFichier) == 1) { 
		cat("Le fichier de donnees suivant est il le bon ? \n")
		cat(listeFichier)
		cat("\n")
		reponse <- ouiOuNon()
		if(reponse == "OUI") {
			donneesAll <-  read.data()
		} else {
			mess <- "Veuillez y mettre vos donnees dans le dossier 'Donnees'\n"	
			stop(mess)
		}
	} else { 
		mess <- "Veuillez y mettre vos donnees dans le dossier 'Donnees'\n"	
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

figname<- paste("Resultats/",id,"/",ifelse(valide=="Incertain","Incertain/",""),
                sp,"_",id,serie, ".png",
                sep = "")
## coordonnee des ligne horizontal de seuil pour les abondances et les occurences
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
    ylab("") + xlab("Annee")+ ggtitle(titre) +
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
  ggsave(figname, p,width=15,height=20, units="cm")
} else {

  p <- ggplot(data = subset(dgg,panel=="Variation abondance"), mapping = aes(x = annee, y = val))
  ## Titre, axes ...
  p <- p + facet_grid(panel ~ ., scale = "free") +
    theme(legend.position="none",
          panel.grid.minor=element_blank(),
          panel.grid.major.y=element_blank())  +
    ylab("") + xlab("Annee")+ ggtitle(titre) +
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
  ggsave(figname, p,width=14,height=8,units="cm")
}
}

## moyenne geometrique pondere
geometriqueWeighted <- function(x,w=1) exp(sum(w*log(x))/sum(w))

                                     
## Analyse par groupe de specialisation a partir des resulats de variation d'abondance par especes
## id identifiant de la session
## ICfigureGroupeSp affichage des intervalles de confiances sur la figure
## correctionAbondanceNull correction des abondance NULL
analyseGroupe <- function(id=NA,ICfigureGroupeSp=TRUE,powerWeight=2,
					correctionAbondanceNull = 0.000001,
					groupeNom = c("generaliste","milieux batis","milieux forestiers","milieux agricoles"),
					groupeCouleur = c("black","firebrick3","chartreuse4","orange")) {
  
  
    nameFile <- paste("Resultats/",id,"/variationsAnnuellesEspece_",id,".csv",sep="" )
    nameFileTrend <- paste("Resultats/",id,"/tendanceGlobalEspece_",id,".csv",sep="" )
    ## donnees variations d'abondance annuels
	donnees <-  read.csv2(nameFile)
	## donnees tendences globales
    donneesTrend <- read.csv2(nameFileTrend)
    donneesTrend <- subset(donneesTrend, select = c(code_espece,valide,mediane_occurrence))
	## table de reference espece
    tabsp <- read.csv2(paste(args[1],"espece.csv",sep="/")) #("Librairie/espece.csv")
    tabsp <- subset(tabsp, select= c(sp,nom,indicateur, specialisation))
	donnees <- merge(donnees,donneesTrend,by="code_espece")
    donnees <- merge(donnees,tabsp,by.x="code_espece",by.y="sp")
    ## table de correspondance de biais en fonction des medianes des occuerences
    tBiais <- read.csv(paste(args[1],"espece.csv",sep="/")) #("Librairie/biais.csv")
    nameFileSpe <-  paste("Resultats/",id,"/variationsAnnuellesGroupes_",id,
                          ".csv",sep="" )
    nameFileSpepng <-  paste("Resultats/",id,"/variationsAnnuellesGroupes_",id,
                             ".png",sep="" )
    
    grpe <- donnees$specialisation
    
	## recherche d'un maximum
    ff <- function(x,y) max(which(y<=x))
    ## poids du a l'incertitude 
    IncertW <- ifelse(donnees$valide=="Incertain",tBiais$biais[sapply(as.vector(donnees$mediane_occurrence),ff,y=tBiais$occurrenceMed)],1)
	## poids du a la qualite de l'estimation
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
					  
	## calcul des moyennes pondere par groupe par an et pour les estimates et les IC	
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
    titre <- paste("Variation de l'indicateur groupe de specialisation",sep="")


#browser()
    p <- ggplot(data = da, mapping = aes(x = annee, y = abondance_relative, colour=groupe,fill=groupe))
    p <- p + geom_hline(aes(yintercept = 1), colour="white", alpha=1,size=1.2) 
	if(ICfigureGroupeSp)
    p <- p + geom_ribbon(mapping=aes(ymin=IC_inferieur,ymax=IC_superieur),linetype=2,alpha=.1,size=0.1) 
	  p <- p + geom_line(size=1.5)
    p <- p +  ylab("") + xlab("Annee")+ ggtitle(titre) 
if(!is.null(groupeNom)) p <- p + scale_colour_manual(values=col, name = "" ,
                                 breaks = names(col))+
                                     scale_x_continuous(breaks=unique(da$annee))
   if(!is.null(groupeNom)) p <- p +  scale_fill_manual(values=groupeCouleur, name = "" ,
                                breaks = groupeNom)
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

listSp<-c()
for (i in 2:length(args)){listSp<-c(listSp,args[i])}
#listSp<-paste("c(\"",args[2],"\")",sep="")
cat (listSp)
print (length(listSp))
if(length(listSp)==1){
    cat("\ncoucou\n")
    analyse(listSp,"Galaxy",NULL,TRUE,1,"carre",TRUE,TRUE,FALSE,TRUE,TRUE,TRUE,FALSE,c("generaliste","milieux batis","milieux forestiers","milieux agricoles"),c("black","firebrick3","chartreuse4","orange"))
}else{
    analyse(listSp,"Galaxy",NULL,TRUE,1,"carre",TRUE,TRUE,FALSE,TRUE,TRUE,TRUE,TRUE,c("generaliste","milieux batis","milieux forestiers","milieux agricoles"),c("black","firebrick3","chartreuse4","orange"))
}
