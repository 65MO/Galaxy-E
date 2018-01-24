FROM rocker/shiny:latest

# Installing packages needed for check traffic on the container and kill if none
RUN apt-get update && apt-get install net-tools -y
RUN apt-get install procps -y
# Bash script to check traffic
RUN mkdir /srv/shiny-server/sample-apps/SIG
ADD SIG/global.r /srv/shiny-server/sample-apps/SIG/global.r
ADD SIG/server.R /srv/shiny-server/sample-apps/SIG/server.R
ADD SIG/shiny.Rproj /srv/shiny-server/sample-apps/SIG/shiny.Rproj
ADD SIG/ui.r /srv/shiny-server/sample-apps/SIG/ui.r
ADD ./monitor_traffic.sh /monitor_traffic.sh
COPY shiny-server.sh /usr/bin/shiny-server.sh
CMD ["/usr/bin/shiny-server.sh"]
