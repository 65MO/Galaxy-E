#!/usr/bin/env Rscript
#This script copies the original from rebird that is not fully working yet. 
#https://cran.r-project.org/web/packages/rebird/index.html


library(httr)
library(methods)
library(dplyr)


args = commandArgs(trailingOnly=TRUE)
sname<-args[1]
lati<-as.numeric(args[2])
lon<-as.numeric(args[3])
dist_km<-as.numeric(args[4])
nb_days<-as.numeric(args[5])
maxi<-as.numeric(args[6])


urlhttps <- paste0('https://ebird.org/ws1.1/', 'data/obs/', 'geo_spp/recent')

ebird_compact <- function(x) Filter(Negate(is.null), x)

args <- ebird_compact(list(fmt='json', sci=sname,
                           lat=round(lati,2), lng=round(lon,2),
                           maxResults=maxi,dist=dist_km,back=nb_days,
                           locale=NULL))



ebird_GET <- function(url, args, ...){
  tt <- GET(url, query = args, ...)
  ss <- content(tt, as = "text", encoding = "UTF-8")
  json <- jsonlite::fromJSON(ss, FALSE)
  if (tt$status_code > 202) {
    warning(sprintf("%s", json[[1]]['errorMsg']))
    NA
  } else {
    if (!is.list(json)) { 
      return(NA) 
    } else {
      json <- lapply(json, function(x) lapply(x, function(a) {
        if (length(a) == 0) { 
          NA 
        } else if (length(a) > 1) {
          paste0(a, collapse = ",")
        } else {
          if (is(a, "list")) {
            a[[1]]
          } else {
            a
          }
        }
      }))
      bind_rows(lapply(json, as_data_frame))
    }
  }
}

data<-ebird_GET(urlhttps, args)
write.table(data,file="content_data.tab",row.names=FALSE,sep='\t')
