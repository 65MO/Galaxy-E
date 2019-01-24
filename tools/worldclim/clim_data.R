#!/usr/bin/env Rscript


args <- commandArgs(trailingOnly = TRUE)

#Rscript clim_data.R 'worldclim' 'var' 'resolution' 'OutputFormat' #'FRA' #'prec1'
if (length(args)==0 | args[1]=="-h" | args[1]=="--help"){
  print ("general script execution : Rscript clim_data.R \'worldclim\' \'var\' resolution \'OutputFormat\' #\'variable-to-plot\' #\'region_code\'")
  print ("eg : Rscript clim_data.R \'worldclim\' \'prec\' 10 \'raster\' #\'prec1' #\'FRA\'")
  q('no')
} 


#Climatic variables dictionaries
months<-c("January","February","March","April","May","June","July","August","September","October","November","December")
bioclimatic_vars<-c("Annual Mean Temperature", "Mean Diurnal Range (Mean of monthly (max temp - min temp))", "Isothermality (BIO2/BIO7) (x 100)","Temperature Seasonality (standard deviation x100)","Max Temperature of Warmest Month","Min Temperature of Coldest Month","Temperature Annual Range (BIO5-BIO6)","Mean Temperature of Wettest Quarter","Mean Temperature of Driest Quarter","Mean Temperature of Warmest Quarter","Mean Temperature of Coldest Quarter","Annual Precipitation","Precipitation of Wettest Month","Precipitation of Driest Month","Precipitation Seasonality (Coefficient of Variation)","Precipitation of Wettest Quarter","Precipitation of Driest Quarter","Precipitation of Warmest Quarter","Precipitation of Coldest Quarter")

#Function to create custom plot title
get_plot_title<-function(usr_var,usr_var_to_plot){
  match<-str_extract(usr_var_to_plot,"[0-9]+")
  if(usr_var %in% c("prec","tmin","tmax")){
      printable_var<-(months[as.integer(match)])
      if(usr_var=="prec"){
        printable_var<-paste(printable_var," precipitations (mm)",sep="")
      }else if(usr_var=="tmin"){
        printable_var<-paste(printable_var," minimum temperature (°C *10)",sep="")
      }else{
        printable_var<-paste(printable_var," maximum temperature (°C *10)",sep="")
      }
  }else if(usr_var=="bio"){
      printable_var<-(bioclimatic_vars[as.integer(match)])
      printable_var<-paste("Bioclimatic variable - ",printable_var,sep="")
  }
  title<-paste("Worldclim data - ",printable_var,".",sep="")
  return(title)
}


#Call libraries
library('raster',quietly=TRUE) 
library(sp,quietly = TRUE, warn.conflicts = FALSE)
library(ncdf4,quietly = TRUE, warn.conflicts = FALSE)
library(stringr)


#Get args
usr_data=args[1]
usr_var=args[2]
usr_res=as.numeric(args[3])
usr_of=args[4]


# Retrieve 'var' data from WorldClim
global.var <- getData(usr_data, download = TRUE, var = usr_var, res = usr_res)

# Check if we actualy get some
if (length(global.var)==0){
  cat("No data found.")
}else{
  writeRaster(global.var, "output_writeRaster", format=usr_of,overwrite=TRUE)
  final_msg<-paste("WorldClim data for ", usr_var, " at resolution ", usr_res, " in ", usr_of, " format\n", sep="")
  cat(final_msg)
}






#################
##Visualisation##
#################

#Get args
if(length(args[5])>=0 && length(args[6])>=0){
  usr_var_to_plot=args[5]
  usr_plot_region=args[6]
}else{q('no')}

list_region_mask<-c("FRA","DEU","GBR","ESP","ITA")

if(usr_plot_region %in% list_region_mask){
#Country mask
  region <- getData("GADM",country=usr_plot_region,level=0)
  region_mask <- mask(global.var, region)
  region_var_to_plot_expression<-paste("region_mask$",usr_var_to_plot,sep="")
}else{ #All map and resize manualy
  region_var_to_plot_expression<-paste("global.var$",usr_var_to_plot,sep="")
}


region_var_to_plot<-eval(parse(text=region_var_to_plot_expression))

#PLotmap
jpeg(file="worldclim_plot_usr_region.jpeg",bg="white")

title<-get_plot_title(usr_var,usr_var_to_plot)


if(usr_plot_region=="FRA"){
  #FRA
  plot(region_var_to_plot, xlim = c(-7, 12), ylim = c(40, 52), axes=TRUE,xlab="Longitude",ylab="Latitude",main=title)
}else if(usr_plot_region=="GBR"){
  #GBR
  plot(region_var_to_plot, xlim = c(-10, 5), ylim = c(46, 63), axes=TRUE,xlab="Longitude",ylab="Latitude",main=title)
}else if(usr_plot_region=="NA"){
  #North America : 
  plot(region_ar_to_plot,xlim=c(-180,-50),ylim=c(10,75),xlab="Longitude",ylab="Latitude",main=title)
}else if(usr_plot_region=="EU"){
  #Europe
  plot(region_var_to_plot,xlim=c(-28,48),ylim=c(34,72),xlab="Longitude",ylab="Latitude",main=title)
}else if(usr_plot_region=="DEU"){
  #DEU
  plot(region_var_to_plot, xlim = c(5, 15), ylim = c(45, 57),axes=TRUE,xlab="Longitude",ylab="Latitude",main=title)
}else if(usr_plot_region=="ESP"){
  #ESP
  plot(region_var_to_plot, xlim = c(-10, 6), ylim = c(35, 45), axes=TRUE,xlab="Longitude",ylab="Latitude", main=title)
}else if(usr_plot_region=="ITA"){
  #ITA
  plot(region_var_to_plot, xlim = c(4, 20), ylim = c(35, 48), axes=TRUE,xlab="Longitude",ylab="Latitude", main=title)
}else if(usr_plot_region=="WM"){
  #Worldmap
  plot(region_var_to_plot,xlab="Longitude",ylab="Latitude",main=title)
}else if(usr_plot_region=="AUS"){
  #AUS
  plot(region_var_to_plot,xlim=c(110,155),ylim=c(-45,-10),xlab="Longitude",ylab="Latitude",axes=TRUE,main=title)
}else{
  write("Error with country code.", stderr())  
  q('no')
}

garbage_output<-dev.off
 
#Exit
q('no')
