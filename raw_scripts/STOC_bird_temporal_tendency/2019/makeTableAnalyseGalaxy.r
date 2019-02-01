

##################################################################################################################
################  Data transformation for population evolution trend analyses  function:makeTableAnalyse #########
##################################################################################################################

###########
#delcaration des arguments et variables/ declaring some variables and load arguments

args = commandArgs(trailingOnly=TRUE)

if (length(args)==0) {
    stop("At least one argument must be supplied (input file)", call.=FALSE) #if no args -> error and exit1
} else {
    "NomFichier"<-args[1] ###### Nom du fichier sans extension ".typedefichier"  / file name without the file type ".filetype"
    
}

##### Le tableau de données doit posséder 4 variables en colonne: abondance ("abond"), les carrés ou sont réalisés les observatiosn ("carre"), la ou les années des observations ("annee"), et le code de ou des espèces ("espece")
##### Data must be a dataframe with 4 variables in column: abundance ("abond"), plots where observation where made ("carre"), year(s) of the different sampling ("annee"), and the species code ("espece") 


#Import des données / Import data 
data<- read.csv(paste(args[1],".csv",sep=""))

## mise en colonne des especes  et rajout de zero mais sur la base des carrés selectionné sans l'import  /  Species are placed in separated columns and addition of zero on plots where at least one selected species is present 
makeTableAnalyse <- function(data) {
    tab <- reshape(data
                  ,v.names="abond"
                  ,idvar=c("carre","annee")      
                  ,timevar="espece"
                  ,direction="wide")
    tab[is.na(tab)] <- 0               ###### remplace les 0 par des na

    colnames(tab) <- sub("abond.","",colnames(tab))### remplace le premier pattern "abond." par le second "" / replace the column names "abond." by ""
	  filename <- "Datatransformedforfiltering&trendanalysis.csv"
      write.table(tab, filename)
    return(tab)
}





#########

#Do your analysis
makeTableAnalyse(data)

cat('exit\n')