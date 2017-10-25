#!/usr/bin/env Rscript
#Return list of attributes from a Rdata file

args = commandArgs(trailingOnly=TRUE)
rda<-load(args[1]) #Load the rdata
rdata<-get(rda)
names<-names(rdata) #Get the attributes
write(names, file = "rdata_list_attr")
