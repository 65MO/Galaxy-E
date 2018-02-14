library(data.table)
library(DT)
library(htmlwidgets)

f2p <- function(x) #get date-time data from recording file names
{
  if (is(x)[1] == "data.frame") {pretemps <- vector(length = nrow(x))}
  op <- options(digits.secs = 3)
  pretemps <- paste(substr(x, nchar(x) - 18, nchar(x)-4), ".", substr(x, nchar(x) - 2, nchar(x)), sep = "")
  strptime(pretemps, "%Y%m%d_%H%M%OS",tz="UTC")-7200
}

args <- commandArgs(trailingOnly = TRUE)
#print(args) #for debug
EchelleErreur=c(99,50,10,1)

#for test
#i=5
#inputest=list.files("C:/Users/Yves Bas/Documents/GitHub/65MO_Galaxy-E/raw_scripts/Vigie-Chiro/output_IdValid_input_BilanEnrichi/",full.names=T)
#for (i in 1:length(inputest))
#{
#   args=c(inputest[i],"refPF.csv","GroupList_HF.csv")
   
   
IdC2=fread(args[1])
refPF=fread(args[2])
GroupList=fread(args[3])

if(substr(IdC2$`nom du fichier`[1],2,2)!="a")
{
  print("Protocole non conforme, ce script doit etre lance pour un protocole Point Fixe")
}else{
  

#compute error risk by species (minimum error among files)
#to be replaced by glm outputs if I'll have time
RisqueErreurT=aggregate(IdC2$IdProb,by=list(IdC2$IdExtrap),FUN=function(x) ceiling((1-max(x))*100))
barplot(RisqueErreurT$x,names.arg=RisqueErreurT$Group.1,las=2)
#compute error risk accoring to observer/validator (a little dirty because it relies on alphabetical order of confidence classes: POSSIBLE < PROBABLE < SUR)
RisqueErreurOV=aggregate(IdC2$ConfV,by=list(IdC2$IdExtrap)
                         ,FUN=function(x) max(as.numeric(as.factor(x)))) 
RisqueErreurOV2=EchelleErreur[RisqueErreurOV$x]
#compute minimum error risk between man and machine
RisqueErreur=pmin(RisqueErreurT$x,RisqueErreurOV2)

#compute number of files validated per species
FichValid=aggregate(IdC2$IdV,by=list(IdC2$IdExtrap,IdC2$'nom du fichier')
                                 ,FUN=function(x) sum(x!="")) 
NbValid2=aggregate(FichValid$x,by=list(FichValid$Group.1),FUN=function(x) sum(x>0))

DiffC50=vector() # to store the median of confidence difference between unvalidated records and validated ones
DiffT50=vector() # to store the median of time difference between unvalidated records and validated ones
for (j in 1:nlevels(as.factor(IdC2$IdExtrap)))
{
  IdSp=subset(IdC2
              ,IdC2$IdExtrap==levels(as.factor(IdC2$IdExtrap))[j])
  IdSp=IdSp[order(IdSp$IdProb),]
  IdSpV=subset(IdSp,IdSp$IdV!="")
  if(nrow(IdSpV)>0)
  {
  cuts <- c(-Inf, IdSpV$IdProb[-1]-diff(IdSpV$IdProb)/2, Inf)
  CorrC=findInterval(IdSp$IdProb, cuts)
  CorrC2=IdSpV$IdProb[CorrC]
  DiffC=abs(IdSp$IdProb-CorrC2)
  DiffC50=c(DiffC50,median(DiffC))
  
  IdSp=IdSp[order(IdSp$TimeNum),]
  IdSpV=subset(IdSp,IdSp$IdV!="")
  cuts <- c(-Inf, IdSpV$TimeNum[-1]-diff(IdSpV$TimeNum)/2, Inf)
  CorrT=findInterval(IdSp$TimeNum, cuts)
  CorrT2=IdSpV$TimeNum[CorrT]
  DiffT=abs(IdSp$TimeNum-CorrT2)
  DiffT50=c(DiffT50,median(DiffT))
  }else{
    DiffC50=c(DiffC50,Inf)
    DiffT50=c(DiffT50,Inf)
  }
}
#compute an index of validation effort per species
EffortV=1/DiffC50/DiffT50
EffortClass=(EffortV>0.0005)+(EffortV>0.005)+RisqueErreurOV$x
cbind(RisqueErreurOV,EffortV,DiffC50,DiffT50)
barplot(EffortClass-1,names.arg=NbValid2$Group.1,las=2)
ClassEffortV=c("-","FAIBLE","SUFFISANT","SUFFISANT","FORT","FORT")
EffortClassMot=ClassEffortV[EffortClass]


#get date-night
pourDateNuit=IdC2$TimeNum-12*3600 #bricolage-decalage de 12 heures pour ramener a la date du debut de nuit
DateNuit=as.Date.POSIXct(pourDateNuit) # date of the beginning of the night
DateJour=as.Date.POSIXct(IdC2$TimeNum) # date (UTC+0)
IdC2$DateNuit=DateNuit
IdC2$DateJour=DateJour
NbNuit=as.numeric(max(IdC2$DateNuit)-min(IdC2$DateNuit))+1

#compare activity / reference frame
ActMoy=aggregate(IdC2$`nom du fichier`
                 ,by=list(IdC2$IdExtrap),FUN=function(x) length(x)/NbNuit)
ListSpref=match(ActMoy$Group.1,refPF$Espece)
Subref=refPF[ListSpref]
QualifAct=vector()
for (k in 1:nrow(ActMoy))
{
  if(is.na(Subref$Q25[k]))
  {
    QualifAct=c(QualifAct,NA)
  }else{
    cuts=cbind(-Inf,as.numeric(Subref$Q25[k]),as.numeric(Subref$Q75[k])
               ,as.numeric(Subref$Q98[k]),Inf)
  
    QualifAct=c(QualifAct,findInterval(ActMoy$x[k],cuts,left.open=T))
  }
}
ClassAct=c("FAIBLE","MODEREE","FORTE","TRES FORTE")
QualifActMot=ClassAct[QualifAct]

#compute activity by nights (to be completed)
#ActNuit=aggregate(IdC2$`nom du fichier`,by=list(IdC2$DateNuit,IdC2$IdExtrap),FUN=length)

#organize the csv summary
SummPart0=cbind(Nesp=levels(as.factor(IdC2$IdExtrap))
                ,RisqueErreur,NbValid=NbValid2$x,EffortValid=EffortClassMot
                ,Contacts_Nuit=round(ActMoy$x),Niveau_Activite=QualifActMot)


InfoSp=c('GroupFR','NomFR','Scientific name','Nesp')
GroupShort=GroupList[,InfoSp,with=FALSE]
SummPart=merge(GroupShort,SummPart0,by="Nesp")
IndexGroupe=c("Autre","Sauterelle","Chauve-souris")
SummPart$IndexSumm=match(SummPart$GroupFR,IndexGroupe)
SummPart=SummPart[with(SummPart
                       ,order(IndexSumm,as.numeric(Contacts_Nuit),decreasing=T)),]
colnames(SummPart)=c("Code","Groupe","Nom francais","Nom scientifique"
                     ,"Risque d'erreur (%)","Nb Validations"
                     ,"Effort de validation","Nb de Contacts par Nuit"
                     ,"Niveau d'Activite","IndexG")

#to do: extend colors to other columns to improve readability
SummHTML=datatable(SummPart, rownames = FALSE) %>%
  formatStyle(columns = "Risque d'erreur (%)", 
              background = styleInterval(c(1, 10, 50), c("white", "khaki", "orange", "orangered"))) %>%
  formatStyle(columns = "Effort de validation", 
              background = styleEqual(c("-","FAIBLE","SUFFISANT","FORT"), c("white", "cyan", "royalblue", "darkblue"))) %>%
  formatStyle(columns = "Niveau d'Activite", 
              background = styleEqual(c("FAIBLE","MODEREE","FORTE","TRES FORTE"), c("palegoldenrod", "greenyellow", "limegreen", "darkgreen")))

saveWidget(SummHTML,"output.html")
write.table(SummPart,"output.tabular",sep="\t",row.names=F)

}





