

##################################################################################################################
################  Data transformation for population evolution trend analyses  function:makeTableAnalyse #########
##################################################################################################################

###########
#delcaration des arguments et variables/ declaring some variables and load arguments

args = commandArgs(trailingOnly=TRUE)

if (length(args)==0) {
    stop("At least one argument must be supplied (input file)", call.=FALSE) #si pas d'arguments -> affiche erreur et quitte / if no args -> error and exit1
} else {
    ImportduSTOC<-args[1] ###### Nom du fichier importé depuis la base de données STOCeps sans extension ".typedefichier"  / file name imported from the STOCeps database without the file type ".filetype"    
}

##### Le tableau de données doit posséder 4 variables en colonne: abondance ("abond"), les carrés ou sont réalisés les observatiosn ("carre"), la ou les années des observations ("annee"), et le code de ou des espèces ("espece")
##### Data must be a dataframe with 4 variables in column: abundance ("abond"), plots where observation where made ("carre"), year(s) of the different sampling ("annee"), and the species code ("espece") 


#Import des données / Import data 
data<- read.csv(paste(ImportduSTOC,".csv",sep="")) #  
ncol<-as.integer(dim(data)[2])
if(ncol<4){ #Verifiction de la présence mini de 4 colonnes on peut aller plus loin et vérifier les noms de ces colonnes.
    stop("The file don't have at least 4 variables", call.=FALSE)
}


## mise en colonne des especes  et rajout de zero mais sur la base des carrés selectionné sans l'import  /  Species are placed in separated columns and addition of zero on plots where at least one selected species is present 
makeTableAnalyse <- function(data) {
    tab <- reshape(data
                  ,v.names="abond"
                  ,idvar=c("carre","annee")      
                  ,timevar="espece"
                  ,direction="wide")
    tab[is.na(tab)] <- 0               ###### remplace les 0 par des na

    colnames(tab) <- sub("abond.","",colnames(tab))### remplace le premier pattern "abond." par le second "" / replace the column names "abond." by ""
    return(tab)
}





#########

#Do your analysis
tableAnalyse<-makeTableAnalyse(data) #la fonction a un 'return' il faut donc stocker le resultat dans une nouvelle variable
#On ecrit le fichier en dehors de la fonction si possible comme ça c'est plus visible. La fonction ne fait que les calcul et est générale. on peut l'appeler plusieurs fois avec plusieurs noms et plusieurs fichiers écrits.
filename <- "Datatransformedforfiltering&trendanalysis.csv"
write.csv2(tableAnalyse, filename) 



cat('exit\n')
