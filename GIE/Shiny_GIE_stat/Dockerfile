FROM rocker/shiny:latest

# Installing packages needed for check traffic on the container and kill if none
RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup && \
    echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache && \
    apt-get -qq update && apt-get install --no-install-recommends -y net-tools procps && \
    # Installing R package dedicated to the shniy app
    Rscript -e "install.packages('leaflet', repos = c('https://radiant-rstats.github.io/minicran/', 'https://cloud.r-project.org', 'https://cran.r-project.org'))" && \
    # Bash script to check traffic
    mkdir /srv/shiny-server/sample-apps/STAT



RUN git clone https://github.com/radiant-rstats/radiant.git /srv/shiny-server/sample-apps/STAT/


COPY shiny-server.sh /usr/bin/shiny-server.sh
COPY .Rprofile /home/shiny/.Rprofile

CMD ["/usr/bin/shiny-server.sh"]
