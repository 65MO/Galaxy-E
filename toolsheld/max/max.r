#!/usr/bin/env Rscript

options(error = function() traceback(2))

#get arguments from the command line
args <- commandArgs(trailingOnly = TRUE)

if(length(args)!=1 ){
  print("usage: ./max.r <file>")
  q("no",0,"False")
}
read.csv(args[1],head=T)->tab

vector()->nomEspece
vector()->valeurConfiance
for (i in 1:nrow(tab)){
	max=0
	jmax=0
	for(j in 2:ncol(tab)){
		if(max<tab[i,j]){
			max=tab[i,j]
			jmax=j
		}
	}
	c(nomEspece,colnames(tab)[jmax])->nomEspece
	c(valeurConfiance,max)->valeurConfiance
}
data.frame(evenementSonore=tab[,1], nomEspece, valeurConfiance)