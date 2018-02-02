FROM rocker/shiny:latest

# Installing packages needed for check traffic on the container and kill if none
echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup && \
    echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache && \
    apt-get -qq update && apt-get install --no-install-recommends -y net-tools procps && \
    # Installing R package dedicated to the shniy app
    Rscript -e "install.packages('leaflet')" && \
    # Bash script to check traffic
    mkdir /srv/shiny-server/sample-apps/SIG

COPY global.r /srv/shiny-server/sample-apps/SIG/global.r
COPY server.R /srv/shiny-server/sample-apps/SIG/server.R
COPY shiny.Rproj /srv/shiny-server/sample-apps/SIG/shiny.Rproj
COPY ui.r /srv/shiny-server/sample-apps/SIG/ui.r
ADD ./monitor_traffic.sh /monitor_traffic.sh
COPY shiny-server.sh /usr/bin/shiny-server.sh

CMD ["/usr/bin/shiny-server.sh"]
