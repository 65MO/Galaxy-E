#!/usr/bin/env Rscript

#get arguments from the command line
args <- commandArgs(trailingOnly = TRUE)

if(length(args)!=3 ){
  print("usage: ./STOCeps.r <variationsAnnuellesEspece> <tendanceGlobalEspece> <LibraryPath>")
  q("no",0,"False")
}

#############################################################################

### Analyse des variations d'abondance des donnees issues du protocole STOCeps
###      Romain Lorrilliere et Diane Gonzalez
### analyse()

library(lme4)
library(arm)

analyse <- function(listSp=NULL,id_session=NULL,annees=NULL,
                                          estimateAnnuel=TRUE,
                 echantillon=1,methodeEchantillon="carre",ICfigureGroupeSp=TRUE,
                 figure=TRUE,sauvegardeDonnees=FALSE, concatFile=TRUE,description=TRUE,tendanceSurFigure=TRUE,tendanceGroupSpe = TRUE,
                 groupeNom = c("generaliste","milieux batis","milieux forestiers","milieux agricoles"),
                 groupeCouleur = c("black","firebrick3","chartreuse4","orange")) {

    cat("\n")
    start <- Sys.time() ## heure de demarage est utilisee comme identifiant par defaut
    id <- ifelse(is.null(id_session),format(start, "%Y%m%d-%HH%M"),id_session)
    cat(format(start, "%d-%m-%Y %HH%M"),"\n")
    cat("\n")

    analyseGroupe(args[1],args[2],id,ICfigureGroupeSp,groupeNom = groupeNom,groupeCouleur=groupeCouleur) ;
}

    ## Analyse par groupe de specialisation � partir des resulats de variation d'abondance par especes
    ## id identifiant de la session
    ## ICfigureGroupeSp affichage des intervalles de confiances sur la figure
    ## correctionAbondanceNull correction des abondance NULL
analyseGroupe <- function(variationsAnnuellesEspece=NA, tendanceGlobalEspece=NA,id=NA,ICfigureGroupeSp=TRUE,powerWeight=2,
					correctionAbondanceNull = 0.000001,
					groupeNom = c("generaliste","milieux batis","milieux forestiers","milieux agricoles"),
					groupeCouleur = c("black","firebrick3","chartreuse4","orange")) {
  
    nameFile <- paste(variationsAnnuellesEspece,sep="" )
    nameFileTrend <- paste(tendanceGlobalEspece,sep="" )
    ## donnees variations d'abondance annuels
	donnees <-  read.csv2(nameFile, sep = "\t")
	## donnees tendences globales
    donneesTrend <- read.csv2(nameFileTrend, sep = "\t")
    donneesTrend <- subset(donneesTrend, select = c(code_espece,valide,mediane_occurrence))
	## table de reference espece
    tabsp <- read.csv2(paste(args[3],"espece.csv",sep="/"))
    tabsp <- subset(tabsp, select= c(sp,nom,indicateur, specialisation))
    donnees <- merge(donnees,donneesTrend,by="code_espece")
    donnees <- merge(donnees,tabsp,by.x="code_espece",by.y="sp")
    ## table de correspondance de biais en fonction des medianes des occuerences
    tBiais <- read.csv(paste(args[3],"biais.csv",sep="/"))
    nameFileSpe <-  paste(variationsAnnuellesEspece,sep="" )
    nameFileSpepng <-  paste(tendanceGlobalEspece,sep="" )
    
    grpe <- donnees$specialisation
    
	## recherche d'un maximum
    ff <- function(x,y) max(which(y<=x))
    ## poids du � l'incertitude 
    IncertW <- ifelse(donnees$valide=="Incertain",tBiais$biais[sapply(as.vector(donnees$mediane_occurrence),ff,y=tBiais$occurrenceMed)],1)
	## poids du � la qualit� de l'estimation
    #erreur_stW <- 1/((donnees$erreur_st+1)^powerWeight)
    #erreur_stW <- ifelse( is.na(donnees$IC_superieur),0,erreur_stW)
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

	nomFileResum <- paste("donneesGroupes.tsv",sep="" )
	write.table(ddd,nomFileResum,row.names=FALSE,sep="\t")
	cat(" <--",nomFileResum,"\n")
					  
	## calcul des moyennes pond�r� par groupe par an et pour les estimates et les IC	
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
    write.table(da,file="tendancesAnnuellesGroupes.tsv",row.names=FALSE,quote=FALSE,sep="\t")

      cat(" <-- tendancesAnnuellesGroupes.tsv\n")
    yearsrange <- c(min(da$annee),max(da$annee))
 
	# ## figure par ggplot2
 #    titre <- paste("Variation de l'indicateur groupe de sp�cialisation",sep="")


 #    #browser()
 #    p <- ggplot(data = da, mapping = aes(x = annee, y = abondance_relative, colour=groupe,fill=groupe))
 #    p <- p + geom_hline(aes(yintercept = 1), colour="white", alpha=1,size=1.2) 
	# if(ICfigureGroupeSp)
 #    p <- p + geom_ribbon(mapping=aes(ymin=IC_inferieur,ymax=IC_superieur),linetype=2,alpha=.1,size=0.1) 
	#   p <- p + geom_line(size=1.5)
 #    p <- p +  ylab("") + xlab("Ann�e")+ ggtitle(titre) 
 #    if(!is.null(groupeNom)) p <- p + scale_colour_manual(values=col, name = "" ,
 #                                 breaks = names(col))+
 #                                     scale_x_continuous(breaks=unique(da$annee))
 #    if(!is.null(groupeNom)) p <- p +  scale_fill_manual(values=groupeCouleur, name = "" ,
 #                                breaks = groupeNom)
 #    p <- p +  theme(panel.grid.minor=element_blank(), panel.grid.major.y=element_blank()) 
 #    ggsave(nameFileSpepng, p,width=17,height=10,units="cm")

    #cat(" <==",nameFileSpepng,"\n")
    
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
    namefilesum <- paste("tendancesGlobalesGroupes.tsv",sep="" )
    write.table(datasum,file=namefilesum,row.names=FALSE,quote=FALSE,sep="\t")
    cat(" <--",namefilesum,"\n")
}

## moyenne geometrique pondere
geometriqueWeighted <- function(x,w=1) exp(sum(w*log(x))/sum(w))

analyse()