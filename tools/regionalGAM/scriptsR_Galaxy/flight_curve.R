#!/usr/bin/env Rscript
library('getopt')
library(devtools)
library(RegionalGAM)

args = commandArgs(trailingOnly=TRUE)

tryCatch({input = read.table(args[1], header=TRUE,sep="	")},finally={input = read.table(args[1], header=TRUE,sep=",")})
dataset1 <- input[,c("SPECIES","SITE","YEAR","MONTH","DAY","COUNT")]
pheno <- flight_curve(dataset1)

write.table(pheno, file="pheno", row.names=FALSE, sep="	")
