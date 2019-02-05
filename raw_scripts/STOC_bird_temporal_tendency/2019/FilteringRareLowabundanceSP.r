
#####################################################################################################################
############## FILTERING RARE AND LOW-ABUNDANCE SPECIES   function:filtreEspeceRare    ##############################
#####################################################################################################################

#### Based on Romain Lorrillière R script
#### Modified by Alan Amosse and Benjamin Yguel for integrating within Galaxy-E


###########
#delcaration des arguments et variables/ declaring some variables and load arguments

args = commandArgs(trailingOnly=TRUE)

if (length(args)==0) {
    stop("At least one argument must be supplied (input file)", call.=FALSE) #si pas d'arguments -> affiche erreur et quitte / if no args -> error and exit1
} else {
    Datatransformedforfiltering_trendanalysis<-args[1] ###### Nom du fichier sans extension ".typedefichier", peut provenir de la fonction "MakeTableAnalyse" / file name without the file type ".filetype", may result from the function "MakeTableAnalys"    
}

##### Le tableau de données doit posséder 3 variables en colonne minimum avec 1 seule espèce et autant de colonne en plus que d'espèces en plus: les carrés ou sont réalisés les observatiosn ("carre"), la ou les années des observations ("annee"), 1 colonne par espèce renseignée avec les abondances correspondantes
##### Data must be a dataframe with 3 variables in column: plots where observation where made ("carre"), year(s) of the different sampling ("annee"), and one column per species with its abundance


#Import des données / Import data 
tab <- read.csv(paste(Datatransformedforfiltering_trendanalysis,".csv",sep=""),sep=";",dec=".") #  
ncol<-as.integer(dim(tab)[2])
if(ncol<3){ #Verifiction de la présence mini de 3 colonnes, si c'est pas le cas= message d'erreur / checking for the presence of 3 columns in the file if not = error message
    stop("The file don't have at least 3 variables", call.=FALSE)
}


############################################# la fonction qui filtre les données pas suffisantes pour analyses fiables / The filtering function removing species with not enough data to perform accurate analyses
filtreEspeceRare <- function(tab) {

##################### Filtre les espèces jamais présentes (abondance=0) / Filter of species with 0 abundance
#################################################################################  PARTIE POTENTIELLEMENT ISOLABLE ET INSERABLE AVANT LA BOUCLE = permet de gagner du temps sur la boucle car supprime sps pas vu, donc pas repris par la boucle
    
    ## Fait la somme des abondances totales par espèce / calculate the sum of all abundance per species
    if(ncol(tab)==3) {
	tabSum <- sum(tab[,3])## cas d'une seule especes (problème de format et manip un peu differente)  / when selecting only one species, use a different method
	names(tabSum) <- colnames(tab)[3]
    } else {  ## cas de plusieurs espèce/ when selecting more than one species
        tabSum <- colSums(tab[,-(1:2)])
    }
    ## colNull= espece(s) toujours absente /species with 0 total abundance
    colNull <- names(which(tabSum==0))
    ## colconserve= espece(s) au moins presente 1 fois/ species at least with 1 presence
    colConserve <- names(which(tabSum>0))
    ## Affichage des espèces rejetees  / show species eliminated for the analyses
    if(length(colNull)>0){
        cat("\n",length(colNull)," Espèces enlevées de l'analyse car abondance toujours égale a 0\n\n",sep="")
        tabNull <- data.frame(Code_espece = colNull, nom_espece = tabsp[colNull,"nom"])
        print(tabNull)  
        cat("\n\n",sep="")
        tab <- tab[,c("carre","annee",colConserve)]  
    }
################################################################################ FIN DE LA PARTIE ISOLABLE





###################### Filtre les especes trop rare pour avoir des analyses robustes i.e. espèce non presente la 1ère année, avec plus de 3 ans consecutif sans données et moins de 3 ans consécutif avec données 
######################  Filter too rare species for accurate analysis i.e.  species absent the first year, with more than 3 consecutive years with 0 abundance, or with less than 3 consecutive years with presence

### 
    cat <- NULL
    ## calcul et filtre pour chaque (colonne) espece / measure and filter for each species
    for(i in 3:ncol(tab)) {
        ## v =abondance par annee / v= abundance per year
        v <- tapply(tab[,i],tab$annee,sum)  ####################    
        ## v0 =presence abscence par annee 
        v0 <- ifelse(v>0,1,0)  ##### 
        tx <- paste(v0,collapse="") #### colle les 0 et 1 / stick the 0 and 1 
        
        p <- unlist(strsplit(tx,"0"))#### Enleve les 0, ce qui séparent les sequences de "1", les sequences de "1" = nbre d'années consécutives avec data / remove 0, splitting sequences of "1" which correspond to consecutve year with data (e.g. 111 = 3 years consecutive years with data)
        p <- p[p!=""] #### ne garde pas les partie sans 1 ou 0 dans les sequences
        ## gsSup0 = plus grande serie temporelle de presence =calcul du nbre de 1 consécutif max / calcul of the biggest temporal series which corresponds to the maximum number of consecutive "1"
        gsSup0 <- max(nchar(p))#### 
        ## gsInf0 plus grande serie temporelle d'absccence ou sans données = enlève les 1 séparant sequence de 0 qui correspondent au nbre d'année consecutive sans données / calcul of the biggest temporal series without data which corresponds to max numbzer fo consecutive "0" 
        gsInf0 <- max(nchar(unlist(strsplit(tx,"1")))) ####  
        ## y0is0 absence la premiere annee
        y0is0 <- v0[1]==0  #### True ou false pour presence de "0"(=pas de données) dans la 1ère année / look if the first year of the time sequence analyzed has no data 
        ## seuil d'exclusion / exclusion threshold  
        cat <- c(cat,as.vector(ifelse( y0is0 | gsInf0 > 3 | gsSup0 < 3 ,"exclu","bon")))  ############## exclu sps absente la 1ère année, avec plus de 3 ans consécutifs sans données, et avec moins de 3 années consécutives sans données / indicate if the max consecutive year with data and without data, as well as whether the first year of the time sequence analyzed has data 
    }
    names(cat) <- colnames(tab)[3:ncol(tab)]
    ## colonnes conservees avec assez de données / Column with enough data
    colConserve <- names(cat)[cat=="bon"]
    ## colonnes supprimees / Column that will conserved 
    colSupr <- names(cat)[cat=="exclu"]
    tabCLEAN <- tab[,c("carre","annee",colConserve)] #### Garde les sps à conserver / select only species with enough data 
    lfiltre <- list(tabCLEAN=tabCLEAN,colConserve=colConserve,colSupr=colSupr)
    return(lfiltre) 
#################################################################################  PARTIE POTENTIELLEMENT ISOLABLE

    ## colConserve espece conservees / extract species that will be kept to print them
    colConserve <- lfiltre$colConserve
    ## colsupr espece trop rare et donc supprimée de l'analyse / extract species that will be deleted to print them
    colSupr <- lfiltre$colSupr
    
    ## affichage des especes retirer de l'analyse / print species that will be deleted
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
	
	tabCLEAN <- lfiltre$tabCLEAN

                                        
    tabCLEAN <- melt(tabCLEAN, id.vars=c("carre", "annee"))
    colnames(tab)[3:4] <- c("espece","abond")
    tabCLEAN$annee <- as.numeric(as.character(tabCLEAN$annee))
################################################################################ FIN DE LA PARTIE ISOLABLE

}

#########

#Do your analysis
    lfiltre <- filtreEspeceRare(tab)

    

#save the data in a output file in a csv format
filename <- "Datafilteredfortrendanalysis.csv"
write.csv2(tabCLEAN, filename)



