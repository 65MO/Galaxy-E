FROM rocker/shiny:latest

# Installing packages needed for check traffic on the container and kill if none
RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup && \
    echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache && \
    apt-get -qq update && apt-get install --no-install-recommends -y net-tools procps git-all libssl-dev libcurl4-openssl-dev libxml2-dev libxml2 build-essential python-pip && \
    pip install --upgrade pip && \
    pip install -U setuptools && \
    pip install bioblend galaxy-ie-helpers && \
    # Installing R package dedicated to the shniy app
    Rscript -e "install.packages('igraph')" && \
    Rscript -e "install.packages('dplyr')" && \
    Rscript -e "install.packages('radiant', repos = c('https://radiant-rstats.github.io/minicran/', 'https://cloud.r-project.org', 'https://cran.r-project.org'))" && \
    # Bash script to check traffic
    mkdir /srv/shiny-server/sample-apps/STAT && \


    git clone https://github.com/radiant-rstats/radiant.git /srv/shiny-server/sample-apps/STAT/


COPY shiny-server.sh /usr/bin/shiny-server.sh
COPY .Rprofile /home/shiny/.Rprofile
COPY global.R /usr/local/lib/R/site-library/radiant.data/app/global.R
ADD ./monitor_traffic.sh /monitor_traffic.sh
COPY ./shiny-server.conf /etc/shiny-server/shiny-server.conf
CMD ["/usr/bin/shiny-server.sh"]
