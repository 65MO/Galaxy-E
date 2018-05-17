#!/usr/bin/env Rscript
#Read csv - return tabular
#2 Options for now : sep an header

args = commandArgs(trailingOnly=TRUE)

if(args[3]=="TRUE"){
    tabular<-read.table(args[1],sep="\t",header=TRUE)
    write.csv(tabular,"out.csv",sep=args[2],row.names=FALSE)
}else{
    tabular<-read.table(args[1],sep="\t",header=FALSE)
    write.csv(tabular,"out.csv",sep=args[2],col.names=FALSE,row.names=FALSE)
}

