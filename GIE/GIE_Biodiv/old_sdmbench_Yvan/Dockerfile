FROM rocker/shiny:3.5.1

# Installing packages needed for check traffic on the container and kill if none
RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup && \
    echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache
    
RUN apt-get -qq update 
RUN apt-get install --no-install-recommends -y net-tools procps openssl libssl-dev 
RUN apt-get install -y libgeos-dev libgit2-dev libxml2-dev
    # Installing R package dedicated to the shniy app
RUN apt-get update && apt-get install -y libgdal-dev 
#libgeos-dev libxml2-dev 
RUN Rscript -e "install.packages('devtools')"
   
#RUN Rscript -e "install.packages('keras')"

RUN apt-get install -y openjdk-8-jdk
RUN R CMD javareconf 
RUN Rscript -e "install.packages('rJava')"

RUN Rscript -e "devtools::install_github('boyanangelov/sdmbench')"
    #Rscript -e "remote::install_github("boyanangelov/sdmbench")" && \
RUN apt-get -qq update && apt-get install --no-install-recommends -y python-pip  python-dev virtualenv

RUN Rscript -e "keras::install_keras(tensorflow = 'default')"

RUN Rscript -e "install.packages('maptools')" 

RUN Rscript -e "install.packages('sdmbench')"
COPY ./global.r /srv/shiny-server/sample-apps/sdmbench/
# Bash script to check traffic
COPY sdmbench-master /srv/shiny-server/sample-apps/sdmbench/
ADD ./monitor_traffic.sh /monitor_traffic.sh
COPY shiny-server.sh /usr/bin/shiny-server.sh
CMD ["/usr/bin/shiny-server.sh"]
