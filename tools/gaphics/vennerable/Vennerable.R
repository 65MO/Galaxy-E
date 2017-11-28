#!/usr/bin/R

# R script to call Vennerable package from galaxy
# info: alex.bossers@wur.nl
#
# version:
#   2015-04-21 fixed <NA> values bug
#   .......... Initial version
#

# R --slave --vanilla --file=PlotBar.R --args inputFile x_data weighting outputFile plottype resolution imagetype
# 1     2       3             4           5       6        7       8         9        10        11         12

#get cmd line args
args <- commandArgs()
in.file <- args[6]
xData       <- args[7]   # data labels xData of format "a, b, c" and can include spaces
weighting   <- args[8]
out.file    <- args[9]
plottype    <- args[10]
resolution  <- args[11] # in dpi
imagetype   <- args[12] # svg, pdf or png

#open lib
library(Vennerable)
options(bitmapType='cairo')

# for labels of bars or bar groups presume column names from data
if (xData != "default") {
	# read without header input file (must be tabular)
	a_data <- read.delim(in.file, header=F, na.strings="")      # replace empty by <NA> for TAB delimited file
	colnames (a_data) <- strsplit(xData,",")[[1]]               # insert headers from galaxy input
	annot_data <- lapply(a_data, na.omit)                       # remove empty values for counting
	Vannot <- Venn(annot_data)
} else {
	# read with header input file (must be tabular)
	a_data <- read.delim(in.file, na.strings="")                # replace any empty values by <NA> for AB delimited headered file
	annot_data <- lapply(a_data, na.omit)                       # remove empty values for counting
	Vannot <- Venn(annot_data)
}

#set output imagetype (svg pdf or png)
#R 3.0.2 and default cairo libs should handle it all ok
#it could be that X11 should be loaded for non-pdf
if (imagetype == "svg") {
	svg(out.file)
} else if (imagetype == "png") {
	png(out.file, width = 1600, height = 1600, res = resolution)
} else {
	pdf(out.file)
}

# plot it
if (plottype == "ChowRuskey") {
	plot(Vannot, type = plottype)
	
} else if (plottype == "AWFE") {
	plot(Vannot, doWeights = weighting, type = plottype)
	
} else if (plottype == "circles") {
	plot(Vannot)
	
} else if (plottype == "ellipses"){
	plot(Vannot, type = "ellipses")
	
} else if (plottype == "squares"){
	plot(Vannot, type = "squares")
	
} else if (plottype == "battle"){
	plot(Vannot, type = "battle")
}

cat ("Wrapper version 1.2c (empty value bug fixed), running Vennerable v3.0-82\n Info/bugs: alex.bossers@wur.nl\n")
dev.off()