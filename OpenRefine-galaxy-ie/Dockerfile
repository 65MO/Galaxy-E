FROM ubuntu:16.10
# These environment variables are passed from Galaxy to the container
# and help you enable connectivity to Galaxy from within the container.
# This means your user can import/export data from/to Galaxy.


USER root
ENV DEBIAN_FRONTEND=noninteractive \
    API_KEY=none \
    DEBUG=false \
    PROXY_PREFIX=none \
    GALAXY_URL=none \
    GALAXY_WEB_PORT=10000 \
    HISTORY_ID=none \
    REMOTE_HOST=none
	
RUN apt-get update &&\
    apt-get install -y wget


RUN apt-get install --no-install-recommends -y \
    wget procps nginx python python-pip net-tools nginx	
RUN apt-get install -y openjdk-8-jdk
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV PATH="/usr/lib/jvm/java-8-openjdk-amd64/bin:${PATH}"



RUN apt-get install -y python-pip
Run pip install --upgrade pip
RUN pip install -U setuptools
RUn pip install bioblend galaxy-ie-helpers

#Vim to modify ass porky
RUN apt-get install -y vim

#PERSONAL NOTE: You have have to install ullib before openrefine to avoid proxy port problem.
#Get urllib
RUN wget -O - --no-check-certificate https://github.com/ValentinChCloud/urllib2_file/archive/master.tar.gz | tar -xz
RUN mv urllib2_file-master urllib2_file; cd ./urllib2_file ; python setup.py test 

RUN cd ./urllib2_file ; python setup.py build ; python setup.py install ;

	


# download and "mount" OpenRefine
RUN wget -O - --no-check-certificate https://github.com/ValentinChCloud/OpenRefine/archive/master.tar.gz |tar -xz
RUN mv OpenRefine-master OpenRefine
RUN cd OpenRefine/ ;ls -al
RUN apt-get install unzip


# make some changes to Openrefine to export data to galaxy history, todo before openrefine build
ADD ./ExportRowsCommand.java /OpenRefine/main/src/com/google/refine/commands/project/ExportRowsCommand.java
RUN /OpenRefine/refine build


# Our very important scripts. Make sure you've run `chmod +x startup.sh
# monitor_traffic.sh` outside of the container!
ADD ./startup.sh /startup.sh
ADD ./monitor_traffic.sh /monitor_traffic.sh
#Import and export
ADD ./openrefine_import.sh /openrefine_import.sh
#Test

# /import will be the universal mount-point for Jupyter
# The Galaxy instance can copy in data that needs to be present to the
# container
RUN mkdir /import

#Get python api openrefine
RUN wget -O - --no-check-certificate https://github.com/ValentinChCloud/refine-python/archive/master.tar.gz | tar -xz
RUN mv refine-python-master refine-python



#TEST
RUN apt-get install -y curl
ADD ./openrefine_create_project_API.py /refine-python/openrefine_create_project_API.py

#Test export
ADD ./openrefine_export_project.py /refine-python/openrefine_export_project.py





# Nginx configuration
COPY ./proxy.conf /proxy.conf

VOLUME ["/import"]
WORKDIR /import/







# EXTREMELY IMPORTANT! You must expose a SINGLE port on your container.
EXPOSE 80
CMD /startup.sh
