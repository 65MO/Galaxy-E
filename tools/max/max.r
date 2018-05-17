#!/usr/bin/env Rscript

options(error = function() traceback(2))

#get arguments from the command line (by Yves Bas, Mnhn, France)
args <- commandArgs(trailingOnly = TRUE)

#Verification que le nombre de paramètre est compatible avec le script
if(length(args)!=4 ){
  print("usage: ./max.r <file> <nameCol1> <nameCol2> <nameCol3>")
  q("no",0,"False")
}
#Lecture du fichier d'entrée (au format tsv)
read.table(args[1],head=T,sep="\t")->tab

#Pour chaque ligne on recherche la valeur maximun et le nom de la colonne qui correspond à cette valeur
vector()->nomValeurColonne
vector()->valeurMax
for (i in 1:nrow(tab)){
	max=0
	jmax=0
	for(j in 2:ncol(tab)){
		if(max<tab[i,j]){
			max=tab[i,j]
			jmax=j
		}
	}
	c(nomValeurColonne,colnames(tab)[jmax])->nomValeurColonne
	c(valeurMax,max)->valeurMax
}

#On renomme les entêtes de colonnes
vector()-> nomColonne
c(nomColonne, args[2]) -> nomColonne
c(nomColonne, args[3]) -> nomColonne
c(nomColonne, args[4]) -> nomColonne

tab_fin<-data.frame(tab[,1], nomValeurColonne, valeurMax)
colnames(tab_fin) <- nomColonne

write.table(tab_fin, "./Resultat", sep="\t", row.names = FALSE) 