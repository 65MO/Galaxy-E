#!/usr/bin/env Rscript
#Read Xlsx sheets - return tabular
library(readxl)

args = commandArgs(trailingOnly=TRUE)

sheet<-read_excel(args[1],sheet=args[2])
write.table(sheet,"out.tabular",sep="\t",row.names=FALSE)
