args <- commandArgs(trailingOnly = TRUE)
#for test
#inputest=list.files("C:/Users/Yves Bas/Documents/GitHub/65MO_Galaxy-E/raw_scripts/Vigie-Chiro/input_examples_IdTidy",full.names=T,pattern="participation-")
#for (i in 1:length(inputest)){args=c(inputest[i])
library(data.table)
print(args)


DataPar=fread(args[1]) #ids
DataPar$participation=substr(args[1],nchar(args[1])-40,nchar(args[1])-17)
test1=duplicated(cbind(DataPar$'nom du fichier',DataPar$tadarida_taxon))
test2=(DataPar$tadarida_taxon=="empty")
DataPar=subset(DataPar,(!test1)|(test2))
DataPar$tadarida_probabilite[DataPar$tadarida_probabilite==""]="0"
DataPar$tadarida_probabilite=as.numeric(DataPar$tadarida_probabilite)

write.table(DataPar,paste0(substr(args[1],nchar(args[1])-40,nchar(args[1])-17),"-DataCorrC2.csv"),row.names=F,sep="\t")
