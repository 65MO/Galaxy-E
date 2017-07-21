# OpenRefine-galaxy-ie
Galaxy Interactive Environment for theOpenRefine spreadsheet application

To deploy Openrefine as IE in galaxy :
```
#!/bin/bash
cd $HOME && \
git clone -b release_17.01 https://github.com/galaxyproject/galaxy.git
#Set the .bashrc
echo "#Galaxy stuff">>~/.bashrc
echo 'export GALAXY_ROOT="$HOME/galaxy"'>>~/.bashrc
source ~/.bashrc
#Add this line to add mirror for debian and search for docker
########Make a if on debian use this #######
#############################################
#echo "deb http://httpredir.debian.org/debian jessie-backports main">>/etc/apt/sources.list
#Update modifications
#############################################
apt-get update -y
#Install docker
apt-get install -y docker.io
#Add the user to the group docker
#############################################
user_name=$(whoami)
usermod -a -G docker $user_name
#Add openrefine as interactive environnement
#############################################
mkdir $HOME/openrefine-install && cd /$HOME/openrefine-install && git clone https://github.com/ValentinChCloud/OpenRefine-galaxy-ie 
mkdir $HOME/galaxy/config/plugins/interactive_environments/openrefine
path_galaxy_openrefine=$(echo $HOME/galaxy/config/plugins/interactive_environments/openrefine)
path_install_openrefine=$(echo $HOME/openrefine-install/OpenRefine-galaxy-ie)
mv $path_install_openrefine/GIE/config $path_galaxy_openrefine && \
	mv $path_install_openrefine/GIE/static $path_galaxy_openrefine && \
		mv $path_install_openrefine/GIE/templates $path_galaxy_openrefine
			
			rm -r $HOME/openrefine-install/OpenRefine-galaxy-ie/GIE

			#Check if galaxy.ini already exists
			galaxy_ini_check_return=$(ls /root/galaxy/config/ |grep '^galaxy.ini$')
			if [ -n "$galaxy_ini_check_return" ]; then
				echo "The file already exits"
				else
					echo "Coping galaxy.ini.sample to galaxy.ini"
						cp $GALAXY_ROOT/config/galaxy.ini.sample $GALAXY_ROOT/config/galaxy.ini
						fi
						#Add the path to the interactives environnements if isn't already set
						#############################################
						test_path_interactive_set=$(cat $GALAXY_ROOT/config/galaxy.ini |grep "interactive_environment_plugins_directory =" |cut -d"=" -f2)
						if [ -n "$test_path_ineractive" ]; then
							echo "The path is already set : $test_path_interactive_set"
							else
								echo "Add the path to config/plugins/interactive_environments to galaxy.ini"
									sed -i 's/\(#interactive_environment_plugins_directory =\)/interactive_environment_plugins_directory = config\/plugins\/interactive_environments/' "$GALAXY_ROOT/config/galaxy.ini"
									fi
									#Add email user if give in line parameters
									#############################################
									if [ $# -ne "1" ]; then
										echo "bonjour"
										else
											sed -i "s/\(admin_users = .*\)/\1,$1/" "$GALAXY_ROOT/config/galaxy.ini"
											fi


											#Install node,sqlite3 and npm
											#Node
											apt-get install nodejs
											ln -s /usr/bin/nodejs /sur/bin/node
											wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.1/install.sh | bash
											source ~/.bashrc
											nvm install 0.10
											#Sqlite3
											apt-get install -y sqlite3
											#Npm
											apt-get install -y npm
											cd $GALAXY_ROOT/lib/galaxy/web/proxy/js && npm install
											#Build openrefie image
											#############################################
											cd $HOME/openrefine-install/OpenRefine-galaxy-ie
											docker build -t openrefine . 

```
