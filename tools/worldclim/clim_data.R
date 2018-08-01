#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

#Rscript clim_data.R 'worldclim' 'var' 'resolution' 'OutputFormat'
if (length(args)==0 | args[1]=="-h" | args[1]=="--h"){
  print ("Rscript clim_data.R \'worldclim\' \'var\' \'resolution\' \'OutputFormat\'")
  q('no')
} 

library('raster')#,quietly = TRUE, warn.conflicts = FALSE) 
library(sp,quietly = TRUE, warn.conflicts = FALSE)
#library(ncdf4,quietly = TRUE, warn.conflicts = FALSE)
#library(rgdal,quietly = TRUE, warn.conflicts = FALSE)


usr_data=args[1]
usr_var=args[2]
usr_res=as.numeric(args[3])
usr_of=args[4]
#usr_country=args[]

# Retrieve 'var' data from WorldClim
global.var <- getData(usr_data, download = TRUE, var = usr_var, res = usr_res)

# Check if we actualy get some
if (length(global.var)==0){
  print("No data found.")
}else{
  writeRaster(global.var, "output_writeRaster", format=usr_of,overwrite=TRUE)
  final_msg<-paste("WorldClim data for ", usr_var, " at resolution ", usr_res, " in ", usr_of, " format", sep="")
  print(final_msg)
}

q('no')
