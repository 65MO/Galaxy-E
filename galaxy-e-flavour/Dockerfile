FROM bgruening/galaxy-stable


MAINTAINER ValentinChCloud


ADD galaxy-e_tool_list.yml $GALAXY_ROOT/my_tool_list.yml
RUN install-tools $GALAXY_ROOT/my_tool_list.yml


WORKDIR /galaxy-central
# Mark folders as imported from the host.
VOLUME ["/export/", "/data/", "/var/lib/docker"]

# Expose port 80 (webserver), 21 (FTP server), 8800 (Proxy)
EXPOSE :80
EXPOSE :21
EXPOSE :8800

# Autostart script that is invoked during container start
CMD ["/usr/bin/startup"]
