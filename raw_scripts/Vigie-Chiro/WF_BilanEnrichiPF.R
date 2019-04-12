#part="5ae5c0b367dbdd000e64cb4b"
part="D:/Participations_Vigie-chiro"
args=c(paste0("C:/Users/Yves Bas/Downloads/participation-",part,"-observations.csv"),"ClassifEspC2b_180222.learner")

IdCorrect_2ndLayer="C:/Users/Yves Bas/Documents/GitHub/65MO_Galaxy-E/tools/Vigie-Chiro/IdCorrect_2ndLayer.R"
IdValid="C:/Users/Yves Bas/Documents/GitHub/65MO_Galaxy-E/tools/Vigie-Chiro/IdValid.R"
BilanEnrichiPF="C:/Users/Yves Bas/Documents/GitHub/65MO_Galaxy-E/tools/Vigie-Chiro/BilanEnrichiPF.R"



if(dir.exists(part))
{
  listFpart=list.files(part,pattern="participation-",full.names=T)
  listpart=substr(list.files(part,pattern="participation-"),15,38)
}else{
  listpart=part  
  }

for (h in 1:length(listpart))
     {
  print(paste(h,Sys.time()))
       args[1]=listFpart[h]


args[3]=basename(args[1])


source(IdCorrect_2ndLayer)
write.table(DataCorrC2,paste0(substr(args[1],nchar(args[1])-40,nchar(args[1])-17),"-DataCorrC2.csv"),row.names=F,sep="\t")

args=c(paste0(listpart[h],"-DataCorrC2.csv"),"Referentiel_seuils_C2.csv")

source(IdValid)
write.table(IdC2,paste0(substr(args[1],1,nchar(args[1])-15),"-IdC2.csv"),row.names=F,sep="\t")

args=c(paste0(listpart[h],"-IdC2.csv"),"refPF.csv","SpeciesList.csv")
source(BilanEnrichiPF)
saveWidget(SummHTML,paste0(substr(args[1],1,nchar(args[1])-9),"-summary.html"))
write.table(SummPart,paste0(substr(args[1],1,nchar(args[1])-9),"-summary.csv"),sep="\t",row.names=F)
saveWidget(SummHTMLN,paste0(substr(args[1],1,nchar(args[1])-9),"-nightly.html"))
write.table(SummPartN,paste0(substr(args[1],1,nchar(args[1])-9),"-nightly.csv"),sep="\t",row.names=F)
saveWidget(SummHTMLH,paste0(substr(args[1],1,nchar(args[1])-9),"-hourly.html"))
write.table(SummPartH,paste0(substr(args[1],1,nchar(args[1])-9),"-hourly.csv"),sep="\t",row.names=F)
}
