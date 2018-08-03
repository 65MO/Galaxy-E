#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

#Rscript clim_data.R 'worldclim' 'var' 'resolution' 'OutputFormat'
if (length(args)==0 | args[1]=="-h" | args[1]=="--help"){
  print ("Rscript clim_data.R \'worldclim\' \'var\' \'resolution\' \'OutputFormat\'")
  q('no')
} 

library('raster')#,quietly = TRUE, warn.conflicts = FALSE) 
library(sp,quietly = TRUE, warn.conflicts = FALSE)
library('Cairo')
library(ncdf4,quietly = TRUE, warn.conflicts = FALSE)
library(rgdal,quietly = TRUE, warn.conflicts = FALSE)


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

#France mask
fra <- getData("GADM",country="FRA",level=0)
fra_mask <- mask(global.var, fra)

#Define variables with eval
var_to_plot<-"prec1"
global_var_to_plot_expression<-paste("global.var$",var_to_plot,sep="")
global_var_to_plot<-eval(parse(text=global_var_to_plot_expression))
fra_var_to_plot_expression<-paste("fra_mask$",var_to_plot,sep="")
fra_var_to_plot<-eval(parse(text=fra_var_to_plot_expression))


#Plotting results
#Worldmap
jpeg(file="worldclim_data_figure.jpeg",width=800,height=500,bg="white")
plot(global_var_to_plot)
dev.off

#Francemap
jpeg(file="worldclim_data_figureFRA.jpeg",bg="white")
plot(fra_var_to_plot, xlim = c(-7, 12), ylim = c(40, 52), axes=TRUE)
dev.off

#North America : 
#plot(global_var_to_plot,xlim=c(-180,-50),ylim=c(10,75))
#Europe
#plot(global_var_to_plot,xlim=c(-28,48),ylim=c(34,72))



q('no')
