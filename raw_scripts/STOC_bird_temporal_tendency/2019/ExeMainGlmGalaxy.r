#!/usr/bin/env Rscript



######################################################################################################################################
############## COMMAND LINE TO CALCULATE AND PLOT EVOLUTION OF SPECIES POPULATION  function:main.glm    ##############################
######################################################################################################################################

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
 AssessIC <-arg [5] ##########  TRUE ou FALSE réalise glm "standard" avec calcul d'intervalle de confiance ou speedglm sans IC bien plus rapide / TRUE or FALSE perform a "standard" glm with confidance interval or speedglm without CI much more fast
}


## creation d'un dossier pour y mettre les resultats

dir.create(paste("Output/",id,sep=""),recursive=TRUE)
cat(paste("Create Output/",id,"\n",sep=""))
dir.create(paste("Output/",id,"/Incertain/",sep=""),recursive=TRUE)
cat(paste("Create Output/",id,"Incertain/\n",sep=""))


#Import des données / Import data 
tabCLEAN <- read.csv(Datafilteredfortrendanalysis,sep="	",dec=".") #### charge le fichier de données d abondance / load abundance of species
tabsp <- read.csv(tabSpecies,sep="	",dec=".")   #### charge le fichier de donnees sur nom latin, vernaculaire et abbreviation, espece indicatrice ou non / load the file with information on species specialization and if species are indicators
ncol<-as.integer(dim(tabCLEAN)[2])
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


source("FunctMainGlmGalaxy.r")### chargement des fonctions / load the functions

################## 
###  Do your analysis

main.glm(donneesAll=dataCLEAN,tabsp=tabsp)





