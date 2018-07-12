#!/usr/bin/Rscript

library(spocc)


##Def functions :
help<-function(){
    cat("HELP\n")
    cat("Spocc::occ, Search on a single species name, or many. And search across a single or many data sources.\n\n")
    cat("Need 3 args :\n")
    cat("    - query : (character) One to many scientific names.\n")
    cat("    - from : (character)  Data source to get data from, any combination of gbif, bison, inat,ebird, ecoengine and/or vertnet.\n")
    cat("    - limit : (numeric) Number of records to return. This is passed across all sources.\n")
    q("no")
}

formatSpName <- function(spName) paste(strsplit(spName, split=' ')[[1]], collapse='_') ###Wallace function

####################################

args = commandArgs(trailingOnly=TRUE)

#Help display
if(args[1]=="-h" || args[1]=="--help" || length(args)<3){help()}

#Get args
sname<-args[1]
dbase_input<-args[2]
max<-as.integer(args[3])
link_taxref<-args[4] #v11.0 #dl 01/06/2018 #https://inpn.mnhn.fr/telechargement/referentielEspece/taxref/11.0/menu

#Set taxref doc path
path_taxref<-"/media/linux-65mo/Linux/65MO/Galaxy-E/tools/occurence_datasource/taxref/TAXREFv11.txt"

#Get all databases
bases<-strsplit(dbase_input,",")
dbase<-c()
for (base in bases){
    dbase<-c(dbase,base)
}

#Get occurrences
results <- spocc::occ(query=sname, from=dbase, limit=max, has_coords=TRUE)

#Dispay results
if(length(dbase)==1){
    results_data <- results[[dbase[1]]]$data[[formatSpName(sname)]]
}else{
    res <- occ2df(results)
    results_data <- res
}

results_data<-as.matrix(results_data)

#If empty
if(length(results_data)==0){cat("\nNo occurrences found.\nLittle tip : Check your input typo, some databases are case sensitive : Genus species.\n")}

#Write them
write.table(file="output.tab",results_data,sep="\t",row.names=FALSE)

if(link_taxref=="dont_link_taxref"){q("no")}


####################
##Link with taxref##
####################
#Def grep sname
grep_system<-paste("grep '",sname,"' ",path_taxref,sep="")
#Header
taxref_header<-("REGNE	PHYLUM	CLASSE	ORDRE	FAMILLE	SOUS_FAMILLE	TRIBU	GROUP1_INPN	GROUP2_INPN	CD_NOM	CD_TAXSUP	CD_SUP	CD_REF	RANG	LB_NOM	LB_AUTEUR	NOM_COMPLET	NOM_COMPLET_HTML	NOM_VALIDE	NOM_VERN	NOM_VERN_ENG	HABITAT	FR	GF	MAR	GUA	SM	SB	SPM	MAY	EPA	REU	SA	TA	TAAF	PF	NC	WF	CLI	URL\n")

#Concatenate
tryCatch(
    {inpn_taxref<-system(command=grep_system,intern=TRUE)},
    error=function(e){
        cat("\nQuery not found in taxref.\n")
        quit("no")},
    warning=function(w){
        cat("\nQuery not found in taxref.\n")
        quit("no")}
    )
inpn_taxref<-paste(inpn_taxref,collapse='\n')
res_taxref_grep<-paste(taxref_header,inpn_taxref)

#Write it !
write(res_taxref_grep,file="res_taxref_grep.tab")
