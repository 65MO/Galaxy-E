#!/usr/bin/env Rscript
#Use a Rdata file and attributes to extract
#Get every argument and write a file with its values(s)


#get the rdata file
args = commandArgs(trailingOnly=TRUE)
rdata<-load(args[1])
rdata<-get(rdata)
sum<-summary(rdata) 

#get the selected attributes to explore
attributes_selected <- commandArgs(trailingOnly=TRUE)[2]
attributes<-strsplit(attributes_selected, ",") #List of elements

write.table(sum,file = "summary.tsv")
len<-length(attributes[[1]])

for (i in 1:len){
	attribute<-attributes[[1]][i] #Get the attribute i 
	if(! any(names(rdata)==attribute)){
		error<-paste(attribute, " doesn't exist in the RData. Check the inputs files")
		write(error, stderr())
	}
	file<-paste(attributes[[1]][i],".tsv",sep="") #Filename definition

	attribute_val<-eval(parse(text=paste("rdata$",attribute,sep=""))) #Extract the value(s)

	if(is.null(attribute_val)){ #Galaxy can't produce output if NULL
		write.table("Return NULL value",file = file)
		next #Exit loop
	}

	if (typeof(attribute_val)=="list"){ #Need to be corrected, fail in galaxy but not in R
		if(length(attribute_val)=="0"){
			sink(file=file)
			print("Empty list :") #If the list is empty without element, file is empty and an error occur in galaxy
			print(attribute_val)
			sink()
			next
		}else{
			attribute_val<-as.data.frame(do.call(rbind, attribute_val))
		}
	}else if (typeof(attribute_val)=="language"){ #OK
		attribute_val<-toString(attribute_val,width = NULL)
	}
	write.table(attribute_val,file = file)

}
