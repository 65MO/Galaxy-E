FROM rocker/shiny:latest

# Installing packages needed for check traffic on the container and kill if none
RUN apt-get update && apt-get install net-tools -y
RUN apt-get install procps -y
# Installing R package dedicated to the shniy app
RUN Rscript -e "install.packages('leaflet')"

# Bash script to check traffic
RUN mkdir /srv/shiny-server/sample-apps/SIG
COPY global.r /srv/shiny-server/sample-apps/SIG/global.r
COPY server.R /srv/shiny-server/sample-apps/SIG/server.R
COPY ui.r /srv/shiny-server/sample-apps/SIG/ui.r
ADD ./monitor_traffic.sh /monitor_traffic.sh
COPY shiny-server.sh /usr/bin/shiny-server.sh
CMD ["/usr/bin/shiny-server.sh"]
