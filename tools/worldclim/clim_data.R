#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

#Rscript clim_data.R 'worldclim' 'var' 'resolution' 'OutputFormat' #'FRA' #'prec1'
if (length(args)==0 | args[1]=="-h" | args[1]=="--help"){
  print ("Rscript clim_data.R \'worldclim\' \'var\' resolution \'OutputFormat\' #\'FRA' #\'prec1\'")
  q('no')
} 

library('raster')#,quietly = TRUE, warn.conflicts = FALSE) 
library(sp,quietly = TRUE, warn.conflicts = FALSE)
##library('Cairo')
library(ncdf4,quietly = TRUE, warn.conflicts = FALSE)
##library(rgdal,quietly = TRUE, warn.conflicts = FALSE)


usr_data=args[1]
usr_var=args[2]
usr_res=as.numeric(args[3])
usr_of=args[4]



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


#################
##Visualisation##
#################

if(length(args[5])>=0 && length(args[6])>=0){
  usr_var_to_plot=args[5]
  usr_plot_region=args[6]

  list_country_mask<-c("FRA","DEU","GBR","ESP","ITA")

  if(usr_plot_region %in% list_country_mask){
  #Country mask
    country <- getData("GADM",country=usr_plot_region,level=0)
    country_mask <- mask(global.var, country)
    country_var_to_plot_expression<-paste("country_mask$",usr_var_to_plot,sep="")
  }else{ #All map and resize manualy
    country_var_to_plot_expression<-paste("global.var$",usr_var_to_plot,sep="")
  }


  country_var_to_plot<-eval(parse(text=country_var_to_plot_expression))

####### PLOT LIM PER usr_plot_region

  #PLotmap
  jpeg(file="worldclim_plot_usr_country.jpeg",bg="white")

  if(usr_plot_region=="FRA"){
    #FRA
    plot(country_var_to_plot, xlim = c(-7, 12), ylim = c(40, 52), axes=TRUE,xlab="Longitude",ylab="Latitude",main="Worldclim data - France")
  }else if(usr_plot_region=="GBR"){
    #GBR
    plot(country_var_to_plot, xlim = c(-10, 5), ylim = c(46, 63), axes=TRUE,xlab="Longitude",ylab="Latitude",main="Worldclim data - UK")
  }else if(usr_plot_region=="NA"){
    #North America : 
    plot(country_ar_to_plot,xlim=c(-180,-50),ylim=c(10,75),xlab="Longitude",ylab="Latitude",main="Worldclim data - North America")
  }else if(usr_plot_region=="EU"){
    #Europe
    plot(country_var_to_plot,xlim=c(-28,48),ylim=c(34,72),xlab="Longitude",ylab="Latitude",main="Worldclim data - Europe")
  }else if(usr_plot_region=="DEU"){
    #DEU
    plot(country_var_to_plot, xlim = c(5, 15), ylim = c(45, 57),axes=TRUE,xlab="Longitude",ylab="Latitude",main="Worldclim data - Germany")
  }else if(usr_plot_region=="ESP"){
    #ESP
    plot(country_var_to_plot, xlim = c(-10, 6), ylim = c(35, 45), axes=TRUE,xlab="Longitude",ylab="Latitude", main="Worldclim data - Spain")
  }else if(usr_plot_region=="ITA"){
    #ITA
    plot(country_var_to_plot, xlim = c(4, 20), ylim = c(35, 48), axes=TRUE,xlab="Longitude",ylab="Latitude", main="Worldclim data - Italy")
  }else if(usr_plot_region=="WM"){
    #Worldmap
    plot(country_var_to_plot,xlab="Longitude",ylab="Latitude",main="Worldclim data")
  }else if(usr_plot_region=="AUS"){
    #AUS
    plot(country_var_to_plot,xlim=c(110,155),ylim=c(-45,-10),xlab="Longitude",ylab="Latitude",axes=TRUE,main="Worldclim data - Australia")
  }else{
    write("Error with country code.", stderr())  
    q('no')
  }

  dev.off
} 

#Exit
q('no')
