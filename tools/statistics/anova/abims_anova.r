#!/usr/local/public/bin/Rscript
# version="1.1"

# date: 06-06-2012
# update: 18-02-2014
# **Authors** Gildas Le Corguille  ABiMS - UPMC/CNRS - Station Biologique de Roscoff - gildas.lecorguille|at|sb-roscoff.fr 

# abims_anova.r version 20140218

library(batch)


# function avova
anova = function (file, sampleinfo, mode="column", condition=1, interaction=F, method="BH", threshold=0.01, selection_method="intersection", sep=";", dec=".", outputdatapvalue="anova.data.output", outputdatafiltered="anova.datafiltered.output") {
	
 
	if (sep=="tabulation") sep="\t"
    	if (sep=="semicolon") sep=";"
    	if (sep=="comma") sep=","

	anova_formula_operator = "+"
	if (interaction) anova_formula_operator = "*"
  
  	# -- import --
	data=read.table(file, header = TRUE, row.names=1, sep = sep, quote="\"", dec = dec, fill = TRUE, comment.char="",na.strings = "NA")
	
  	if (mode == "row") data=t(data)
	
	sampleinfoTab=read.table(sampleinfo, header = TRUE, row.names=1, sep = sep, quote="\"")
	rownames(sampleinfoTab) = make.names(rownames(sampleinfoTab))

	
	# -- group --
	match_data_sampleinfoTab = match(rownames(data),rownames(sampleinfoTab))
	if (sum(is.na(match_data_sampleinfoTab)) > 0) {
	  write("ERROR: There is a problem during to match sample names from the data matrix and from the sample info (presence of NA).", stderr())
	  write("You may need to use change the mode (column/row)", stderr())
	  write("10 first sample names in the data matrix:", stderr())
	  write(head(colnames(data)), stderr())
	  write("10 first sample names in the sample info:", stderr())
	  write(head(rownames(sampleinfoTab)), stderr())
	  quit("no",status=10)
	}
  
	
	# -- anova --
  
  	# formula
	grps=list()
	anova_formula_s = "data ~ "
	cat("\ncontrasts:\n")
	for (i in 1:length(condition)) {
	  grps[[i]] = factor(sampleinfoTab[,condition[i]][match_data_sampleinfoTab])
	  anova_formula_s = paste(anova_formula_s, "grps[[",i,"]]",anova_formula_operator, sep="")
	  cat(condition[i],"\t",levels(grps[[i]]),"\n")
	# write("Current groups: ", stderr())
	# write(grp[[i]], stderr())
	}
	anova_formula_s = substr(anova_formula_s, 1, nchar(anova_formula_s)-1)
	anova_formula = as.formula(anova_formula_s)


	
	# anova
	manovaObjectList = manova(anova_formula)
	manovaList = summary.aov(manovaObjectList)
	
  	# condition renaming
	manovaRownames = gsub(" ","",rownames(manovaList[[1]]))
	manovaNbrPvalue = length(manovaRownames)-1
	manovaRownames = manovaRownames[-(manovaNbrPvalue+1)]
	
	for (i in 1:length(condition)) {
	  manovaRownames = sub(paste("grps\\[\\[",i,"\\]\\]",sep=""),condition[i],manovaRownames)
  	  anova_formula_s = sub(paste("grps\\[\\[",i,"\\]\\]",sep=""),condition[i],anova_formula_s)
	}

  	# log
  	cat("\nanova_formula",anova_formula_s,"\n")
	
	# p-value
	aovPValue = sapply(manovaList,function(x){x[-(manovaNbrPvalue+1),5]})
	if(length(condition) == 1) aovPValue = t(aovPValue)
	rownames(aovPValue) = paste("pvalue_",manovaRownames,sep="")
  
	# p-value adjusted
	if(length(condition) == 1) {
		aovAdjPValue = t(p.adjust(aovPValue,method=method))
	} else {
		aovAdjPValue = apply(aovPValue,2,p.adjust, method=method)
	}
	rownames(aovAdjPValue) = paste("pvalueadjusted.",method,".",manovaRownames,sep="")
	
	# selection
	colSumThreshold = colSums(aovAdjPValue <= threshold)
	if (selection_method == "intersection") {
		datafiltered = data[,colSumThreshold == nrow(aovAdjPValue )]
	} else {
		datafiltered = data[,colSumThreshold != 0]
	}
	
	#data=rbind(data, aovPValue, aovAdjPValue)
	data=rbind(data, aovAdjPValue)

	
	if (mode == "row") {
	  data=t(data)
	  datafiltered=t(datafiltered)
	}
	
	# -- output / return --
	write.table(data, outputdatapvalue, sep=sep, quote=F, col.names = NA)
	write.table(datafiltered, outputdatafiltered, sep=sep, quote=F, col.names = NA)
	
	# log 
	cat("\nthreshold:",threshold,"\n")
	cat("result:",nrow(datafiltered),"/",nrow(data),"\n")
  
	quit("no",status=0)
}

# log
cat("ANOVA\n\n")
cat("Arguments\n")
args <- commandArgs(trailingOnly = TRUE)
print(args)

listArguments = parseCommandArgs(evaluate=FALSE)
do.call(anova, listArguments)



