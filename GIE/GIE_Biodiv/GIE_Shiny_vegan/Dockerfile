FROM rocker/shiny:3.5.1

# Installing packages needed for check traffic on the container and kill if none
RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup && \
    echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache && \
    apt-get -qq update && apt-get install --no-install-recommends -y net-tools procps &&\
    # Installing R package dedicated to the shniy app
    Rscript -e "install.packages('shinydashboard')" &&\
    Rscript -e "install.packages('vegan')"



# DEV !!! You should get the data from a git repo
COPY vegan_gui-master /srv/shiny-server/sample-apps/vegan
# Bash script to check traffic
ADD ./monitor_traffic.sh /monitor_traffic.sh
COPY shiny-server.sh /usr/bin/shiny-server.sh


# Galaxy
RUN apt-get install --no-install-recommends -y python-pip python-dev
RUN pip install --upgrade pip 
RUN pip install -U setuptools && \
    pip install bioblend galaxy-ie-helpers && \
    Rscript -e "install.packages('rPython')" && \
    # Installing R package dedicated to the shniy app
    # Bash script to check traffic
    mkdir -p /opt/python/galaxy-export


COPY ./__init__.py /usr/local/lib/python2.7/dist-packages/galaxy_ie_helpers/__init__.py
COPY ./import_list_history.py /import_list_history.py
COPY ./import_csv_user.py /import_csv_user.py
COPY ./global.r /srv/shiny-server/sample-apps/vegan
# DEV

RUN apt-get install -y vim 
COPY ./shiny-server.conf /etc/shiny-server/shiny-server.conf

CMD ["/usr/bin/shiny-server.sh"]
