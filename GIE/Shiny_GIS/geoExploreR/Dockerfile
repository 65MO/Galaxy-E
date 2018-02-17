FROM rocker/shiny:latest

# Installing packages needed for check traffic on the container and kill if none
RUN apt-get update && apt-get install net-tools -y
RUN apt-get install procps -y
# Installing R package dedicated to the shniy app
RUN Rscript -e "install.packages('leaflet')"
RUN Rscript -e "install.packages('shinydashboard')"
RUN Rscript -e "install.packages('shinyjs')"
RUN Rscript -e "install.packages('ggvis')"
RUN Rscript -e "install.packages('dplyr')"
RUN Rscript -e "install.packages('RColorBrewer')"
RUN Rscript -e "install.packages('raster')"
RUN Rscript -e "install.packages('gstat')"
RUN Rscript -e "install.packages('rgdal')"
RUN Rscript -e "install.packages('Cairo')"


# Bash script to check traffic
RUN mkdir /srv/shiny-server/sample-apps/SIG
COPY global.R /srv/shiny-server/sample-apps/SIG/global.R
COPY server.R /srv/shiny-server/sample-apps/SIG/server.R
COPY ui.R /srv/shiny-server/sample-apps/SIG/ui.R
ADD ./monitor_traffic.sh /monitor_traffic.sh
COPY global.R /srv/shiny-server/sample-apps/SIG/global.R
COPY geoExploreR.Rproj /srv/shiny-server/sample-apps/SIG/geoExploreR.Rproj
COPY shiny-server.sh /usr/bin/shiny-server.sh
CMD ["/usr/bin/shiny-server.sh"]
