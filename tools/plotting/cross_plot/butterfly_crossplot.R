##################################################################
####   Script generique pour realiser les figures en croix  ######
####       a partir des donnees brut                        ######
##################################################################

### Version V1.2 _ 2018-07-31

library(ggplot2)
library(RColorBrewer)

args <- commandArgs(trailingOnly = TRUE)

### importation code
sourcefunctions<-args[1]
source(sourcefunctions)

## fonction d'importation des fichier des donnes
### fonction d'importation, de concatenation des fichiers 
### verification des nom de colonnes 
### verification des doublon de ligne
read.data <-  function(file=NULL,decimalSigne=".") {
#    cat("1) IMPORTATION \n--------------\n")
#    cat("<--",file,"\n")
    data <- read.table(file,sep="\t",stringsAsFactors=FALSE,header=TRUE,dec=decimalSigne)
    ## verification qu'il y a plusieur colonnes et essaye different separateur
    if(ncol(data)==1) {
        data <- read.table(file,sep=";",stringsAsFactors=FALSE,header=TRUE,dec=decimalSigne)
        if(ncol(data)==1) {
            data <- read.table(file,sep=",",stringsAsFactors=FALSE,header=TRUE,dec=decimalSigne)
            if(ncol(data)==1) {
                data <- read.table(file,sep=" ",stringsAsFactors=FALSE,header=TRUE,dec=decimalSigne)
                if(ncol(data)==1) {
                    stop("!!!! L'importation a echoue\n   les seperatateurs de colonne utilise ne sont pas parmi ([tabulation], ';' ',' [espace])\n   -> veuillez verifier votre fichier de donnees\n")
                }
            }
        }
    }
    return(data)
}





filtre1niveau <- function(func,
                          nom_fichier = filename, 
                          dec=".",
                          nom_fichierCouleur= color_filename,
                          col_abscisse = "AB_MOYENNE",
                          figure_abscisse = "Abondance",
                          col_ordonnee = "DIVERSITE_MOYENNE",
                          figure_ordonnee = "Diversite",
                          nomGenerique="GLOBAL",
                          vec_figure_titre = c("Les Papillons"),
                          colourProtocole = TRUE,
                          nomProtocole = "Papillons",
                          vec_col_filtre = vec_col_filtre_usr,
			  col_sousGroup = NULL,#
                          val_filtre = NULL,#
                          figure_nom_filtre = NULL,#
                          bagplot = TRUE,
                          bagProp=c(.05,.5,.95),
                          seuilSegment=30,
                          segmentSousSeuil=TRUE,
                          forcageMajusculeFiltre=TRUE,
                          forcageMajusculeSousGroupe=TRUE){

    dCouleur <- read.data(file=nom_fichierCouleur)
    d <- read.data(file=nom_fichier,decimalSigne=dec)
    if(colourProtocole & !is.null(nomProtocole)) colourProtocole_p <- as.character(dCouleur[dCouleur[,2]==nomProtocole,3]) else colourProtocole_p <- NULL 

    for(f in 1:length(vec_col_filtre)) {
        if(length(vec_figure_titre)==1){
            figure_titre_f <-  vec_figure_titre
        }else{
            figure_titre_f <- vec_figure_titre[f]
        }
        col_filtre_f <- vec_col_filtre[f]
        print(col_sousGroup) #Just to check
        if(func=="ggfiltre1niveau"){
            print("ggfiltre1niveau")
            ggfiltre1niveau(d,
                        col_abscisse,
                        figure_abscisse,
                        col_ordonnee,
                        figure_ordonnee,
                        figure_titre = figure_titre_f,
                        col_filtre = col_filtre_f,
                        nomGenerique,
                        val_filtre = NULL,
                        figure_nom_filtre = NULL,
                        tab_figure_couleur=  subset(dCouleur,Filtre==col_filtre_f),
                        colourProtocole = colourProtocole_p,
                        nomProtocole,
                        bagplot,
                        bagProp=c(.05,.5,.95),
                        seuilSegment,
                        segmentSousSeuil,
                        forcageMajusculeFiltre)
        }else if(func=="gglocal"){
            print("gglocal")
            gglocal(d,
                    col_abscisse,
                    figure_abscisse,
                    col_ordonnee,
                    figure_ordonnee,
                    figure_titre = figure_titre_f,
                    col_filtre = col_filtre_f,
                    nomGenerique = nomGenerique,
                    col_sousGroup = col_sousGroup,
                    val_filtre = NULL,
                    figure_nom_filtre = NULL,
                    tab_figure_couleur= subset(dCouleur,Filtre==col_filtre_f),
                    colourProtocole = colourProtocole_p,
                    nomProtocole,
                    couleurLocal="#f609c1",
                    bagplot,
                    bagProp,
                    seuilSegment,
                    segmentSousSeuil,
                    forcageMajusculeFiltre,
                    forcageMajusculeSousGroupe)
        }else{
            print("ggCompareLevel")
            ggCompareLevel(d,
                           col_abscisse,
                           figure_abscisse,
                           col_ordonnee,
                           figure_ordonnee,
                           figure_titre = figure_titre_f,
                           col_filtre = col_filtre_f,
                           nomGenerique = nomGenerique,
                           val_filtre = NULL,
                           figure_nom_filtre = NULL,
                           tab_figure_couleur= subset(dCouleur,Filtre==col_filtre_f),
                           colourProtocole = colourProtocole_p,
                           nomProtocole, 
                           bagplot,
                           bagProp,
                           seuilSegment,
                           segmentSousSeuil,
                           forcageMajusculeFiltre)
        }
    }    
}

ggfiltre1niveau <- function(d,
                            col_abscisse = "AB_MOYENNE",
                            figure_abscisse = "Abondance",
                            col_ordonnee = "DIVERSITE_MOYENNE",
                            figure_ordonnee = "Diversite",
                            figure_titre = "Referentiel papillon",
                            col_filtre = "nom_reseau",
                            nomGenerique = "Global",
                            val_filtre = NULL,
                            figure_nom_filtre = NULL,
                            tab_figure_couleur= NULL,
                            colourProtocole = NULL,
                            nomProtocole = NULL,
                            bagplot = TRUE,
                            bagProp=c(.05,.5,.95),
                            seuilSegment=30,
                            segmentSousSeuil=TRUE,
                            forcageMajusculeFiltre=TRUE,
                            result_dir="resultats/") {

    d$groupe <- as.character(d[,col_filtre])
    d$abscisse <- d[,col_abscisse]
    d$ordonnee <- d[,col_ordonnee]
    d$groupe <-gsub("/","_",d$groupe)
    d$groupe <-gsub("!","",d$groupe)
   
    if(forcageMajusculeFiltre){
        d$groupe <- toupper(d$groupe)}

    d <- subset(d,!(is.na(groupe)) & !(is.na(abscisse)) & !(is.na(ordonnee)) & groupe != "")

    if(is.null(val_filtre)){ 
        lesModalites <- unique(d$groupe) 
    }else{
        lesModalites <- val_filtre
    }

#    repResult <- dir(result_dir)
#    current_dir<-getwd()
#    dir.create(file.path(current_dir,result_dir))
#
#    if(!(col_filtre %in% repResult)){
#        dir.create(file.path(".",paste(result_dir,col_filtre,sep="")))}
#
#    nomRep1 <- paste(result_dir,col_filtre,"/",sep="")   
    
    d.autre <- d
    d.autre$groupe <- nomGenerique

    for(m in lesModalites) {
        d.reseau <-  subset(d,groupe==m)
        d.reseau$groupe <- m
        ggTable <- rbind(d.autre,d.reseau)

        seuilResum <- nrow(d.reseau) >= seuilSegment
        
        ggTableResum <- aggregate(cbind(ordonnee, abscisse) ~ groupe, data = ggTable,quantile, c(.25,.5,.75))
        ggTableResum <- data.frame(ggTableResum[,1],ggTableResum[,2][,1:3],ggTableResum[,3][,1:3])
        colnames(ggTableResum) <- c("groupe","ordonnee.inf","ordonnee.med","ordonnee.sup","abscisse.inf","abscisse.med","abscisse.sup")

        if(ggTableResum$groupe[2]==nomGenerique){
            ggTableResum <- ggTableResum[c(2,1),]}
      
        if(!(is.null(tab_figure_couleur))) {
            if(m %in% tab_figure_couleur$Modalite) {
                figure_couleur <- setNames(c(as.character(tab_figure_couleur$couleur[tab_figure_couleur$Modalite == nomGenerique]),
                                           as.character(tab_figure_couleur$couleur[tab_figure_couleur$Modalite == m])),
                                           c(nomGenerique,m))
            }else{
                figure_couleur <- setNames(c(as.character(tab_figure_couleur$couleur[tab_figure_couleur$Modalite == nomGenerique]),
                                           as.character(tab_figure_couleur$couleur[tab_figure_couleur$Modalite == ""])),
                                           c(nomGenerique,m))
            }
        }

#        repResult <- dir(nomRep1)
#        if(!(m %in% repResult)){
#            dir.create(paste(nomRep1,m,sep=""))}
#        nomRep <- paste(nomRep1,m,"/",sep="") 
#        
#        
#        if(!is.null(nomProtocole)){
#            repResult <- dir(nomRep)
#            if(!(nomProtocole %in% repResult)){
#                dir.create(paste(nomRep,nomProtocole,sep=""))}
#            nomRep <- paste(nomRep,nomProtocole,"/",sep="")
#        } 
        
     
        gg <- ggplot(ggTable,aes(x=abscisse,y=ordonnee,colour=groupe,fill=groupe))
        if(bagplot){
            gg <- gg + stat_bag(data=d.autre,prop=bagProp[1],colour=NA,alpha=.7) + stat_bag(data=d.autre,prop=bagProp[2],colour=NA,alpha=.4) + stat_bag(data=d.autre,prop=bagProp[3],colour=NA,alpha=.2) }
        else {
            gg <- gg + geom_point(alpha=.2)  
        } 
        gg <- gg + geom_hline(data=subset(ggTableResum,groupe== nomGenerique),aes(yintercept = ordonnee.med,colour=groupe),size=.5,linetype="dashed") + geom_vline(data=subset(ggTableResum,groupe==nomGenerique),aes(xintercept = abscisse.med,colour=groupe),size=.5,linetype="dashed")
        if(segmentSousSeuil) {
            gg <- gg + geom_segment(data=ggTableResum,aes(x = abscisse.med, y = ordonnee.inf, xend = abscisse.med, yend = ordonnee.sup),alpha=.8,size=2.5)
            gg <- gg + geom_segment(data=ggTableResum,aes(x = abscisse.inf, y = ordonnee.med, xend = abscisse.sup, yend = ordonnee.med),alpha=.8,size=2.5)
            if(!(seuilResum)) {
                gg <- gg + geom_segment(data=subset(ggTableResum,groupe!=nomGenerique),aes(x = abscisse.med, y = ordonnee.inf, xend = abscisse.med, yend = ordonnee.sup),alpha=.5,size = 1.5,colour="white")
                gg <- gg + geom_segment(data=subset(ggTableResum,groupe!=nomGenerique),aes(x = abscisse.inf, y = ordonnee.med, xend = abscisse.sup, yend = ordonnee.med),alpha=.5,size = 1.5,colour="white")
            }
        } else {
            gg <- gg + geom_segment(data=subset(ggTableResum,groupe==nomGenerique),aes(x = abscisse.med, y = ordonnee.inf, xend = abscisse.med, yend = ordonnee.sup),alpha=.8,size = 2.5)
            gg <- gg + geom_segment(data=subset(ggTableResum,groupe==nomGenerique),aes(x = abscisse.inf, y = ordonnee.med, xend = abscisse.sup, yend = ordonnee.med),alpha=.8,size = 2.5)
        }

        gg <- gg + geom_point(data=d.reseau,size=2)
        gg <- gg + labs(list(title=figure_titre,x=figure_abscisse,y=figure_ordonnee))

        if(!is.null(colourProtocole)){
            gg <- gg + theme(legend.justification=c(1,0), legend.position=c(1,0),legend.text = element_text(size = 7),legend.background = element_rect(fill=NA), axis.ticks = element_line(colour = colourProtocole, size = 1), axis.ticks.length = unit(0.3, "cm"),plot.title = element_text(colour = colourProtocole))
        }else{
            gg <- gg + theme(legend.justification=c(1,0), legend.position=c(1,0),legend.text = element_text(size = 7),legend.background = element_rect(fill=NA))
        }

        if(!(is.null(tab_figure_couleur))){
            gg <- gg + scale_colour_manual(values = figure_couleur,name = "") + scale_fill_manual(values = figure_couleur,name = "",guide=FALSE)}
        
        ggfile <- paste(nomRep,nomProtocole,"_",m,".png",sep="")
        cat("Check",ggfile,":")
        ggsave(ggfile,gg)
        cat("\n")
        flush.console()
    }
}


##############################################################
gglocal <- function(d,
                    col_abscisse = "AB_MOYENNE",
                    figure_abscisse = "Abondance",
                    col_ordonnee = "DIVERSITE_MOYENNE",
                    figure_ordonnee = "Diversite",
                    figure_titre = "Graphe referentiel",
                    col_filtre = "NOM_RESEAU",
                    nomGenerique = "GLOBAL",
                    col_sousGroup = "PARCELLEID",
                    val_filtre = NULL,
                    figure_nom_filtre = NULL,
                    tab_figure_couleur= NULL,
                    colourProtocole = NULL,
                    nomProtocole = NULL,
                    couleurLocal="#f609c1",
                    bagplot = TRUE,
                    bagProp=c(.05,.5,.95),
                    seuilSegment=30,
                    segmentSousSeuil=TRUE,
                    forcageMajusculeFiltre=TRUE,
                    forcageMajusculeSousGroupe=TRUE) {
    
    d$groupe <- d[,col_filtre]
    d$abscisse <- d[,col_abscisse]
    d$ordonnee <- d[,col_ordonnee]
    d$sousGroup <- d[,col_sousGroup]
    d$groupe <-gsub("/","_",d$groupe)
    d$groupe <-gsub("!","",d$groupe)
    d$sousGroup <-gsub("/","_",d$sousGroup)
    d$sousGroup <-gsub("!","",d$sousGroup)
    if(forcageMajusculeFiltre){
        d$groupe <- toupper(d$groupe)}
    if(forcageMajusculeSousGroupe){
        d$sousGroup <- toupper(d$sousGroup)}
    d <- subset(d,!(is.na(groupe)) & !(is.na(sousGroup)) & !(is.na(abscisse)) & !(is.na(ordonnee)) & groupe != "")
    vecSousGroup <- as.character(unique(d$sousGroup))
    if(is.null(val_filtre)){
        lesModalites <- unique(d$groupe)}
    else{ lesModalites <- val_filtre}
    repResult <- dir("resultats/")
#    if(!(col_filtre %in% repResult)){
#        dir.create(paste("resultats/",col_filtre,sep=""))}
#    nomRep1 <- paste("resultats/",col_filtre,"/",sep="")     
    d.autre <- d
    d.autre$groupe <- nomGenerique
    for(m in lesModalites) {
        d.reseau <-  subset(d,groupe==m)
        d.reseau$groupe <- m
        ggTable <- rbind(d.autre,d.reseau)
        seuilResum <- nrow(d.reseau) >= seuilSegment 
        ggTableResum <- aggregate(cbind(ordonnee, abscisse) ~ groupe, data = ggTable,quantile, c(.25,.5,.75))
        ggTableResum <- data.frame(ggTableResum[,1],ggTableResum[,2][,1:3],ggTableResum[,3][,1:3])
        colnames(ggTableResum) <- c("groupe","ordonnee.inf","ordonnee.med","ordonnee.sup","abscisse.inf","abscisse.med","abscisse.sup")
        if(ggTableResum$groupe[2]==nomGenerique){
            ggTableResum <- ggTableResum[c(2,1),]}             
        if(!(is.null(tab_figure_couleur))) {
            if(m %in% tab_figure_couleur$Modalite) {
                figure_couleur <- setNames(c(as.character(tab_figure_couleur$couleur[tab_figure_couleur$Modalite == nomGenerique]),
                                             as.character(tab_figure_couleur$couleur[tab_figure_couleur$Modalite == m]),couleurLocal),
                                           c(nomGenerique,m,""))
            } else {
                figure_couleur <- setNames(c(as.character(tab_figure_couleur$couleur[tab_figure_couleur$Modalite == nomGenerique]),
                                             as.character(tab_figure_couleur$couleur[tab_figure_couleur$Modalite == ""]),couleurLocal),
                                           c(nomGenerique,m,""))
            }
        }
#        repResult <- dir(nomRep1)
#        if(!(m %in% repResult)){
#            dir.create(paste(nomRep1,m,sep=""))}
#        nomRep <- paste(nomRep1,m,"/",sep="")      
#        if(!is.null(nomProtocole)) {
#            repResult <- dir(nomRep)
#            if(!(nomProtocole %in% repResult)){
#                dir.create(paste(nomRep,nomProtocole,sep=""))}
#            nomRep <- paste(nomRep,nomProtocole,"/",sep="")
#        }         
        d.reseau <- subset(d.reseau, !(is.na(sousGroup)))        
        figure_size<-  setNames(c(1,3,2.5), c(nomGenerique,m,""))
        figure_shape<-  setNames(c(16,16,20), c(nomGenerique,m,""))        
        vecSousGroup <- as.character(unique(d.reseau$sousGroup))        
        for(p in vecSousGroup) {            
            dp <-  subset(d.reseau,sousGroup == p)
            dp$groupe <- dp$sousGroup
            ggTableSous <- rbind(d.reseau,dp)
            ggTableSous <- rbind(d.autre,d.reseau,dp)
            names(figure_couleur)[3] <- p
            names(figure_shape)[3] <- p
            names(figure_size)[3] <- p                        
            gg <- ggplot(ggTableSous,aes(x=abscisse,y=ordonnee,colour=groupe,fill=groupe,shape=groupe,size=groupe))
            if(bagplot){
                gg <- gg + stat_bag(data=d.autre,prop=bagProp[1],colour=NA,alpha=.7) + stat_bag(data=d.autre,prop=bagProp[2],colour=NA,alpha=.4) + stat_bag(data=d.autre,prop=bagProp[3],colour=NA,alpha=.2)
            }else{
                gg <- gg + geom_point(alpha=.2)}
            gg <- gg + geom_hline(data=subset(ggTableResum,groupe == nomGenerique),aes(yintercept = ordonnee.med,colour=groupe),size=.5,linetype="dashed")
            gg <- gg + geom_vline(data=subset(ggTableResum,groupe == nomGenerique),aes(xintercept = abscisse.med,colour=groupe),size=.5,linetype="dashed")
            if(segmentSousSeuil) {
                gg <- gg + geom_segment(data=ggTableResum,aes(x = abscisse.med, y = ordonnee.inf, xend = abscisse.med, yend = ordonnee.sup),alpha=.8,size=2.5)
                gg <- gg + geom_segment(data=ggTableResum,aes(x = abscisse.inf, y = ordonnee.med, xend = abscisse.sup, yend = ordonnee.med),alpha=.8,size=2.5)
                if(!(seuilResum)) {
                    gg <- gg + geom_segment(data=subset(ggTableResum,groupe!=nomGenerique),aes(x = abscisse.med, y = ordonnee.inf, xend = abscisse.med, yend = ordonnee.sup),alpha=.5,size = 1.5,colour="white")
                    gg <- gg + geom_segment(data=subset(ggTableResum,groupe!=nomGenerique),aes(x = abscisse.inf, y = ordonnee.med, xend = abscisse.sup, yend = ordonnee.med),alpha=.5,size = 1.5,colour="white")
                }
            } else {
                gg <- gg + geom_segment(data=subset(ggTableResum,groupe==nomGenerique),aes(x = abscisse.med, y = ordonnee.inf, xend = abscisse.med, yend = ordonnee.sup),alpha=.8,size = 2.5)
                gg <- gg + geom_segment(data=subset(ggTableResum,groupe==nomGenerique),aes(x = abscisse.inf, y = ordonnee.med, xend = abscisse.sup, yend = ordonnee.med),alpha=.8,size = 2.5)
            }
            gg <- gg + geom_point(data=subset(ggTableSous,groupe != nomGenerique))
            if(!(is.null(tab_figure_couleur))){
                gg <- gg + scale_colour_manual(values = figure_couleur,name = "") + scale_fill_manual(values = figure_couleur,name = "",guide=FALSE)}
            gg <- gg + scale_shape_manual(values = figure_shape,name = "",guide=FALSE) + scale_size_manual(values = figure_size,guide=FALSE)
            gg <- gg + labs(list(title=figure_titre,x=figure_abscisse,y=figure_ordonnee))
            if(!is.null(colourProtocole)){
                gg <- gg + theme(legend.justification=c(1,0), legend.position=c(1,0),legend.text = element_text(size = 7),legend.background = element_rect(fill=NA), axis.ticks = element_line(colour = colourProtocole, size = 1), axis.ticks.length = unit(0.3, "cm"),plot.title = element_text(colour = colourProtocole)) }
            else{
                gg <- gg + theme(legend.justification=c(1,0), legend.position=c(1,0),legend.text = element_text(size = 7),legend.background = element_rect(fill=NA))}                       
            ggfile <- paste(nomRep,nomProtocole,"_",m,"-",p,".png",sep="")
            cat("Check",ggfile,":")
            ggsave(ggfile,gg)
            cat("\n")
            flush.console()
        }
    }
}



#####################################################
ggCompareLevel <- function(d,
                           col_abscisse = "abond_moyenne",
                           figure_abscisse = "Abondance",
                           col_ordonnee = "diversite_moyenne",
                           figure_ordonnee = "Diversite",
                           figure_titre = "Rhooo il dechire ce graphe",
                           col_filtre = "nom_reseau",
                           nomGenerique = "Global",
                           val_filtre = NULL,
                           figure_nom_filtre = NULL,
                           tab_figure_couleur= NULL,
                           colourProtocole = NULL,
                           nomProtocole = NULL,
                           bagplot = TRUE,
                           bagProp=c(.05,.5,.95),
                           seuilSegment=30,
                           segmentSousSeuil=FALSE,
                           forcageMajusculeFiltre=TRUE){

    d$groupe <- d[,col_filtre]
    d$abscisse <- d[,col_abscisse]
    d$ordonnee <- d[,col_ordonnee]
    d$groupe <-gsub("/","_",d$groupe)
    d$groupe <-gsub("!","",d$groupe)    
    
    if(forcageMajusculeFiltre){
        d$groupe <- toupper(d$groupe)}
    d <- subset(d,!(is.na(groupe)) & !(is.na(abscisse)) & !(is.na(ordonnee)) & groupe != "")
    if(is.null(val_filtre)){
        lesModalites <- unique(d$groupe) 
    }else{
        lesModalites <- val_filtre
    }
#    repResult <- dir("resultats/")
#    if(!(col_filtre %in% repResult)){
#        dir.create(paste("resultats/",col_filtre,sep=""))
#    }
#    if(!is.null(nomProtocole)){
#        repResult <- dir(paste("resultats/",col_filtre,sep=""))
#        if(!(nomProtocole %in% repResult)){
#            dir.create(paste("resultats/",col_filtre,"/",nomProtocole,sep=""))}
#        nomRep <- paste("resultats/",col_filtre,"/",nomProtocole,"/",sep="")
#    }else{
#        nomRep <- paste("resultats/",col_filtre,"/",sep="")   
#    }
    d.autre <- d
    d.autre$groupe <- nomGenerique
    d.reseau <-  subset(d,groupe %in% lesModalites)
    ggTable <- rbind(d.autre,d.reseau)
    ggTableResum <- aggregate(cbind(ordonnee, abscisse) ~ groupe, data = ggTable,quantile, c(.25,.5,.75))
    ggTableResum <- data.frame(ggTableResum[,1],ggTableResum[,2][,1:3],ggTableResum[,3][,1:3])
    colnames(ggTableResum) <- c("groupe","ordonnee.inf","ordonnee.med","ordonnee.sup","abscisse.inf","abscisse.med","abscisse.sup")
    ggSeuil <- aggregate(ordonnee ~ groupe, data=ggTable,length)
    ggSeuil$seuilResum <- ggSeuil$ordonnee >= seuilSegment
    colnames(ggSeuil)[ncol(ggSeuil)] <- "seuil"
    ggTableResum <- merge(ggTableResum,ggSeuil,by="groupe")
    t_figure_couleur <- subset(tab_figure_couleur,Modalite %in% c(nomGenerique,lesModalites))
    modaliteSansCouleur <- lesModalites[(!(lesModalites %in% t_figure_couleur$Modalite))]
    nbNxCol <- length(modaliteSansCouleur)
    mypalette<-brewer.pal(nbNxCol,"YlGnBu")
    figure_couleur <- setNames(c(as.character(t_figure_couleur$couleur),mypalette),c(as.character(t_figure_couleur$Modalite),modaliteSansCouleur))
    tab_coul <- data.frame(groupe=names(figure_couleur),couleur=figure_couleur)
    tab_coul <- merge(tab_coul,ggTableResum,"groupe")
    tab_coul$nom <- paste(tab_coul$groupe," (",tab_coul$ordonnee,")",sep="")
    figure_couleur <- setNames(as.character(tab_coul$couleur),tab_coul$groupe)
    figure_couleur_nom<- tab_coul$nom
    gg <- ggplot(ggTable,aes(x=abscisse,y=ordonnee,colour=groupe,fill=groupe))
    if(bagplot){
        gg <- gg + stat_bag(data=d.autre,prop=bagProp[1],colour=NA,alpha=.7) + stat_bag(data=d.autre,prop=bagProp[2],colour=NA,alpha=.4) + stat_bag(data=d.autre,prop=bagProp[3],colour=NA,alpha=.2) 
    }else{
        gg <- gg + geom_point(alpha=.2)
    }
    gg <- gg + geom_hline(data=subset(ggTableResum,groupe=="Autre"),aes(yintercept = ordonnee.med,colour=groupe),size=.5,linetype="dashed") + geom_vline(data=subset(ggTableResum,groupe=="Autre"),aes(xintercept = abscisse.med,colour=groupe),size=.5,linetype="dashed") 
    gg <- gg + geom_segment(data=ggTableResum,aes(x = abscisse.med, y = ordonnee.inf, xend = abscisse.med, yend = ordonnee.sup),alpha=.7,size = 2.5)
    gg <- gg + geom_segment(data=ggTableResum,aes(x = abscisse.inf, y = ordonnee.med, xend = abscisse.sup, yend = ordonnee.med),alpha=.7,size = 2.5)
    if(any(ggTableResum$seuil)){
        gg <- gg + geom_segment(data=subset(ggTableResum,!(seuil)),aes(x = abscisse.med, y = ordonnee.inf, xend = abscisse.med, yend = ordonnee.sup),alpha=.5,size = 1.5,colour="white")
        gg <- gg + geom_segment(data=subset(ggTableResum,!(seuil)),aes(x = abscisse.inf, y = ordonnee.med, xend = abscisse.sup, yend = ordonnee.med),alpha=.5,size = 1.5,colour="white")
    }
                    
    #browser()                    #  gg <- gg + geom_point(data=d.reseau,size=2)
    gg <- gg + scale_colour_manual(values = figure_couleur,name = "",labels =  figure_couleur_nom) + scale_fill_manual(values = figure_couleur,name = "",guide=FALSE)
    gg <- gg + labs(list(title=figure_titre,x=figure_abscisse,y=figure_ordonnee))
    if(!is.null(colourProtocole)){
        gg <- gg + theme(legend.justification=c(1,0), legend.position=c(1,0),legend.text = element_text(size = 7),legend.background = element_rect(fill=NA), axis.ticks = element_line(colour = colourProtocole, size = 1), axis.ticks.length = unit(0.3, "cm"),plot.title = element_text(colour = colourProtocole)) 
    }else{
        gg <- gg + theme(legend.justification=c(1,0), legend.position=c(1,0),legend.text = element_text(size = 7),legend.background = element_rect(fill=NA))
    }
    ggfile <- paste(nomRep,nomProtocole,"_",col_filtre,"_","comparaison.png",sep="")
    cat("Check",ggfile,":")    
    ggsave(ggfile,gg)
    cat("\n")
flush.console()
}


#########################################

#Lancement des fonctions :

  #Variables a definir :

#filename="BDD_PAPILLONS_2016.txt"
#color_filename<-"code_couleurs.csv"

  #func
#func="ggCompareLevel"
#func="ggfiltre1niveau"
#func="gglocal"

  #colSousGroupe
#col_sousGroup_usr = NULL    #ggfiltre #ggCompareLevel
#col_sousGroup_usr = "PARCELLENOM"   #gglocal

  #vec_col_filtre_usr
#vec_col_filtre_usr = c("CONDUITEPARCELLE")  #ggCompareLevel
#vec_col_filtre_usr = c("REGION")   #ggfiltre
#vec_col_filtre_usr = c("NOM_RESEAU") #gglocal



#Exe fonction :

#filtre1niveau(func=func,nom_fichier=filename,nom_fichierCouleur=color_filename,col_sousGroup=NULL)   #ggfiltre ou ggCompareLevel, depend de func et de vec_col_filtre_usr
#filtre1niveau(func=func,nom_fichier=filename,nom_fichierCouleur=color_filename,col_sousGroup = col_sousGroup_usr,vec_col_filtre=vec_col_filtre_usr) ## ==local

########################################################

filename=args[2]
color_filename=args[3]
func=args[4]

if(func=="ggCompareLevel"){
col_sousGroup_usr=NULL
vec_col_filtre_usr=c("CONDUITEPARCELLE")
}else if(func=="ggfiltre1niveau"){
col_sousGroup_usr=NULL
vec_col_filtre_usr=c("REGION")
}else if(func=="gglocal"){
col_sousGroup_usr="PARCELLENOM"
vec_col_filtre_usr=c("NOM_RESEAU")
}else{
#sortie erreur
write("Error, unknown function. Exit(1).", stderr())
q('no')
}

#create result dir
nomRep="resultats/"
dir.create(file.path(".", nomRep), showWarnings = FALSE)


filtre1niveau(func=func,nom_fichier=filename,nom_fichierCouleur=color_filename,col_sousGroup=col_sousGroup_usr,vec_col_filtre=vec_col_filtre_usr)
