#!/usr/bin/env Rscript
library("getopt")
library(devtools)
library(RegionalGAM)

args = commandArgs(trailingOnly=TRUE)

input = read.table(args[1], header=TRUE, sep=",")#sep="," à changer, devrait être réglé par galaxy
pheno = read.table(args[2], header=TRUE,sep=",")
dataset2 <- input[input$TREND==1,c("SPECIES","SITE","YEAR","MONTH","DAY","COUNT")]

data.index <- abundance_index(dataset2, pheno)
write.table(data.index, file="data.index", row.names=FALSE)
