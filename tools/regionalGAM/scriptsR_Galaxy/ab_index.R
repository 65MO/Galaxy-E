#!/usr/bin/env Rscript
#library("getopt")
#library(devtools)
#library(RegionalGAM)

args = commandArgs(trailingOnly=TRUE)
source(args[1])


tryCatch({input = read.table(args[2], header=TRUE,sep=" ")},finally={input = read.table(args[2], header=TRUE,sep=",")})
pheno = read.table(args[3], header=TRUE,sep="	")
dataset2 <- input[input$TREND==1,c("SPECIES","SITE","YEAR","MONTH","DAY","COUNT")]

data.index <- abundance_index(dataset2, pheno)
write.table(data.index, file="data.index", row.names=FALSE, sep="	")
#write.csv(data.index, file="data.index", row.names=FALSE)
