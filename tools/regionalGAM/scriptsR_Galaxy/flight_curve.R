#!/usr/bin/env Rscript
#library('getopt')
#library(devtools)

args = commandArgs(trailingOnly=TRUE)
source(args[1]) #TODO replace by library(regionalGAM) if available as official package from bioconda

tryCatch({input = read.table(args[2], header=TRUE,sep="	")},finally={input = read.table(args[2], header=TRUE,sep=",")})
dataset1 <- input[,c("SPECIES","SITE","YEAR","MONTH","DAY","COUNT")]
pheno <- flight_curve(dataset1)

write.table(pheno, file="pheno", row.names=FALSE, sep="	")
