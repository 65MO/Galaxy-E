#!/bin/sh

# Make sure the directory for individual app logs exists
mkdir -p /var/log/shiny-server
chown shiny.shiny /var/log/shiny-server
chown shiny.shiny /import

chown -R shiny.shiny /srv/shiny-server/sample-apps/vegan
chmod +x /monitor_traffic.sh
exec /monitor_traffic.sh &


echo "#Galaxy stuff">>~/.bashrc
echo "export HISTORY_ID=\"$HISTORY_ID\"">>/etc/profile
echo "export API_KEY=\"$API_KEY\"">>/etc/profile
echo "export GALAXY_URL=\"$GALAXY_URL\"">>/etc/profile
echo "export GALAXY_WEB_PORT=\"$GALAXY_WEB_PORT\"">>/etc/profile

exec shiny-server 2>&1
