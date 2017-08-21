#!/bin/bash

sed -i "s|PROXY_PREFIX|${PROXY_PREFIX}|" /proxy.conf;
cp /proxy.conf /etc/nginx/sites-enabled/default;

# Here you would normally start whatever service you want to start. In our
# example we start a simple directory listing service on port 8000


#load dataset into openrefine

files=(/import/*)
until [[ -f "$files" ]]
do
	echo "Importing data from galaxy history "
	sleep 4
done

res=$(ls /import/)
res_cut=$(ls /import/ |cut -d" " -f2)
cp "/import/$res" "/import/$res_cut"
../OpenRefine/refine  &
count=0
#Check if openrefine is up to work
STATUS=$(curl --include 'http://127.0.0.1:3333' 2>&1)
while [[ ${STATUS} =~ "refused" ]]
do
  echo "Waiting for openrefine: $STATUS \n"
  STATUS=$(curl --include 'http://127.0.0.1:3333' 2>&1)
  sleep 4
 # count=$(($count+5))
  #if [ $count -eq 20 ] ; then
   #     echo "Je casse et je reprends"
   #     ../OpenRefine/refine  &
   #     kill $(ps -ef | awk '/refine/{print $2}'|head -1)
   #     count=0
 # fi

done
# Createnew project with the dataset
cd /refine-python
python openrefine_create_project_API.py "/import/$res_cut" &

# Launch traffic monitor which will automatically kill the container if traffic
# stops
/monitor_traffic.sh &
#And nginx in foreground mode.
nginx -g 'daemon off;'
