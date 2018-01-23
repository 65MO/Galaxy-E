FROM rocker/shiny:latest

# Installing packages needed for check traffic on the container and kill if none
RUN apt-get update && apt-get install net-tools -y
RUN apt-get install procps -y
# Bash script to check traffic
ADD ./monitor_traffic.sh /monitor_traffic.sh
COPY shiny-server.sh /usr/bin/shiny-server.sh
CMD ["/usr/bin/shiny-server.sh"]
