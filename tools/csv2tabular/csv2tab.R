#!/usr/bin/env Rscript
#Read csv - return tabular
#2 Options for now : sep an header

args = commandArgs(trailingOnly=TRUE)

if(args[3]=="TRUE"){
    csv<-read.csv(args[1],sep=args[2],header=TRUE)
    write.table(csv,"out.tabular",sep="\t",row.names=FALSE)
}else{
    csv<-read.csv(args[1],sep=args[2],header=FALSE)
    write.table(csv,"out.tabular",sep="\t",col.names=FALSE,row.names=FALSE)
}

