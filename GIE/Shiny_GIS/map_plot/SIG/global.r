# global.R
# Code here is in scope to both ui.R and server.R

#Load required library
library(leaflet)

# Get dataset from CSV
inputstn <- read.csv("/srv/shiny-server/data/inputdata.txt", header=TRUE)

