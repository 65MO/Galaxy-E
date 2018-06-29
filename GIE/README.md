# shiny-GIE

### Genesis

* Based on the work of [William Digan](https://www.researchgate.net/profile/William_Digan) on [CARPEM](https://academic.oup.com/gigascience/article/6/11/1/4557139) https://github.com/CARPEM/GalaxyDocker and exchanges with Hans-Rudolf Hotz ([Friedrich Miescher Institute for Biomedical Research](http://www.fmi.ch/)).
* Using the docker [rocker/shiny](https://github.com/rocker-org/shiny) to install Shiny.

### Concept

* The idea of this Galaxy R Shiny implementation is that integrators need to modify the Shiny app to integrate it on Galaxy through the Galaxy Interactive Environemnt functionality. So Galaxy-E project has created an easy way to integrate Shiny apps following 3 steps:
 * Build your shiny app Dockerfile
   * using the ```rocker/shiny:latest``` as a Docker based image as you can see on this [Dockerfile](https://github.com/65MO/Galaxy-E/blob/master/GIE/Shiny_GIS/geoExploreR/Dockerfile)
   * adding the original Shiny app source code to the Docker as made here with the [SIG](https://github.com/65MO/Galaxy-E/tree/master/GIE/Shiny_GIS/geoExploreR/SIG) folder
   * adding to the Docker a monitor_traffic.sh file as the one you can find here: https://github.com/65MO/Galaxy-E/tree/master/GIE/Shiny_GIS/geoExploreR
   * adding to the Docker all modified R Shiny related parts as here only the [shiny-server.sh](https://github.com/65MO/Galaxy-E/tree/master/GIE/Shiny_GIS/geoExploreR) file
   * specifying the mandatory R packages as mentionned [in this Dockerfile](https://github.com/65MO/Galaxy-E/blob/master/GIE/Shiny_GIS/geoExploreR/Dockerfile)
 * Update your dedicated Galaxy server GIE folder as mention in this Galaxy-E [template](https://github.com/65MO/Galaxy-E/tree/master/GIE/GIE)
 * Add your R Shiny app related Docker image to the config/allowed_images.yml as you can see in [the Galaxy-E example](https://github.com/65MO/Galaxy-E/blob/master/GIE/GIE/config/allowed_images.yml)

This original concept can propose an easy way to use R Shiny apps on Galaxy datasets without using advanced functionnalities. For example, we are thinking this is a good template to have a Shiny app dedicated to interactive visualization.

If you need to use the [Galaxy IE helpers](https://github.com/bgruening/galaxy_ie_helpers), to facilitate more advanced import/export tasks, you can refer to the [Galaxy-E Wallace Shiny app Dockerfile](https://github.com/ValentinChCloud/Wallace-galaxy-ie/blob/11361b59d40ce09fea61300ec97d9c90cc27a83d/Dockerfile) to see an example. Here we just install it through the `pip install bioblend galaxy-ie-helpers && \` Dockerfile line then copy/paste [import](https://github.com/ValentinChCloud/Wallace-galaxy-ie/blob/11361b59d40ce09fea61300ec97d9c90cc27a83d/import_csv_user.py)/[export](https://github.com/ValentinChCloud/Wallace-galaxy-ie/blob/11361b59d40ce09fea61300ec97d9c90cc27a83d/export.py) dedicated scripts into the Docker.


### Shiny apps Docker images

To download and use Galaxy-E GIE Shiny apps Docker images, you can refer to the [galaxy4ecology dockerhub repositories](https://hub.docker.com/search/?isAutomated=0&isOfficial=0&page=1&pullCount=0&q=galaxy4ecology&starCount=0) .
