library(data.table)

f2p <- function(x) #get date-time data from recording file names
{
  if (is(x)[1] == "data.frame") {pretemps <- vector(length = nrow(x))}
  op <- options(digits.secs = 3)
  pretemps <- paste(substr(x, nchar(x) - 18, nchar(x)-4), ".", substr(x, nchar(x) - 2, nchar(x)), sep = "")
  strptime(pretemps, "%Y%m%d_%H%M%OS",tz="UTC")-7200
}

args <- commandArgs(trailingOnly = TRUE)
print(args)
EchelleErreur=c(99,50,10,1)

#for test
i=1
inputest=list.files("C:/Users/Yves Bas/Documents/GitHub/65MO_Galaxy-E/raw_scripts/Vigie-Chiro/output_IdValid_input_BilanEnrichi/",full.names=T)
#for (i in 1:length(inputest))
#{
  args=c(inputest[i])

IdC2=fread(args[1])
#dirty - compute error risk by species (minimum error among files)
RisqueErreurT=aggregate(IdC2$IdProb,by=list(IdC2$IdExtrap),FUN=function(x) ceiling((1-max(x))*100))
#dirty - compute error risk accoring to observer/validator
RisqueErreurOV=aggregate(IdC2$ConfV,by=list(IdC2$IdExtrap)
                         ,FUN=function(x) max(as.numeric(as.factor(x)))) 
RisqueErreurOV2=EchelleErreur[RisqueErreurOV$x]
#compute minimum error risk between man and machine
RisqueErreur=pmin(RisqueErreurT$x,RisqueErreurOV2)

#compute number of files validated per species
NbValid=aggregate(IdC2$IdV,by=list(IdC2$IdExtrap)
                                 ,FUN=function(x) sum(x!="")) 

DiffC50=vector()
DiffT50=vector()
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


