#!/bin/bash

sed -i "s|PROXY_PREFIX|${PROXY_PREFIX}|" /proxy.conf;
cp /proxy.conf /etc/nginx/sites-enabled/default;

# Here you would normally start whatever service you want to start. In our
# example we start a simple directory listing service on port 8000


#load dataset into openrefine
python /get_notebook.py
files=(/import/*)
until [[ -f "$files" ]]
do
	echo "Importing data from galaxy history "
	sleep 4
done

exec /OpenRefine/refine -m $REFINE_MEMORY &

#Check if openrefine is up to work
STATUS=$(curl --include 'http://127.0.0.1:3333' 2>&1)
while [[ ${STATUS} =~ "refused" ]]
do
  echo "Waiting for openrefine: $STATUS \n"
  STATUS=$(curl --include 'http://127.0.0.1:3333' 2>&1)
  sleep 4
done
# Createnew project with the dataset
cd /refine-python
python openrefine_create_project_API.py "/import/$DATASET_NAME" &

# Launch traffic monitor which will automatically kill the container if traffic
# stops
exec /monitor_traffic.sh &
#And nginx in foreground mode.
nginx -g 'daemon off;'
