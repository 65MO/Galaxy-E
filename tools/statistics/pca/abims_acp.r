#!/usr/local/public/bin/Rscript
# abims_acp.r version="1.1"

# date: 04-06-2013
# **Authors** Gildas Le Corguille  ABiMS - UPMC/CNRS - Station Biologique de Roscoff - gildas.lecorguille|at|sb-roscoff.fr 



#function PCA from package FactoMineR 

library(batch)
library(FactoMineR)

acp_metabolomics=function(file ,graph=FALSE, scale.unit=TRUE, sep=";", dec="."){

    if (sep=="tabulation") sep="\t"
    if (sep=="semicolon") sep=";"
    if (sep=="comma") sep=","
    
    # -- loading --
    data=read.table(file, header = TRUE, row.names=1, sep = sep, quote="\"", dec = dec,
		    fill = TRUE, comment.char="",na.strings = "NA")
    
    # -- acp / output pdf --
    resPCA =PCA(t(data),graph=graph, scale.unit=scale.unit)
    # scale.unit=F : on réalise l'ACP sans la réduction des variables
    # graph=F : pas de sortie graphique
    dev.off() #close plot
    dev.off()

    # -- output png --
    # Percentage of variance
    png("percentage_of_variance.png", width =800, height = 400);
    barplot(resPCA$eig$per,xlab="Components",ylab="percentage of variance");
    dev.off()
    
    png("eigenvalue.png", width =800, height = 400);
    barplot(resPCA$eig$eig,xlab="Components",ylab="eigenvalue");
    dev.off()
    
    # -- output / return --
    system("zip -r acp.zip percentage_of_variance.png eigenvalue.png Rplots*.pdf", ignore.stdout = TRUE)
}

listArguments = parseCommandArgs(evaluate=FALSE)
do.call(acp_metabolomics, listArguments)
