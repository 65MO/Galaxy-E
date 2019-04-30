#!/usr/bin/env Rscript
#library('getopt')
#library(devtools)
library(data.table)

args = commandArgs(trailingOnly=TRUE)
source(args[1]) #TODO replace by library(regionalGAM) if available as official package from bioconda

input = fread(args[2], header = TRUE)
# convert to a data.frame (the function flight curve doesn't allow the format from fread)
input <- data.frame(input)
dataset1 <- input[ , c("SPECIES", "SITE", "YEAR", "MONTH", "DAY", "COUNT")]
pheno <- flight_curve(dataset1, MinVisit = args[3], MinOccur = args[4])

write.table(pheno, file="pheno", row.names=FALSE, sep="	")
