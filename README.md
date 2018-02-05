[![Join the chat at https://gitter.im/Galaxy-E/Lobby](https://badges.gitter.im/Galaxy-E/Lobby.svg)](https://gitter.im/Galaxy-E/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)




![Alt Text](https://github.com/65MO/Galaxy-E/blob/master/galaxy/static/Galaxy-E-concarneau-team-fin.gif)
# Context

Following [GCC2016 lightning talk](https://gcc16.sched.com/event/7Zgd/65-millions-of-observers "65 millions of observers"), and in the context of the french National Museum of Natural History MNHN project "65 Millions d'observateurs" dedicated to enhance and expand participation to citizen sciences projects studying biodiversity, a proof of concept of analysis web platform in macroecology will be made. We propose for this to use the [Galaxy web platform](https://github.com/galaxyproject/galaxy). Here is the origin of a Galaxy-E, for Ecology ?

# Galaxy-E
This repository will gather ideas and development of Galaxy-E tools 

# A dedicated French version of Galaxy
 ~~Following the @dannon [PR](https://github.com/galaxyproject/galaxy/pull/3762) @ValentinChCloud will work on this task.~~
New version of the galaxy client incomming, a new PR has been open [PR](https://github.com/galaxyproject/galaxy/pull/5089)

# Interesting Data sources
* WorldClim - Global Climate Data http://www.worldclim.org/
* Copernicus Climate Change Service Providing climate data http://climate.copernicus.eu/
* Copernicus Marine Environment Monitoring Service Providing products & services for all marine applications http://marine.copernicus.eu/
* Copernicus Atmosphere air quality & atmospheric composition https://atmosphere.copernicus.eu/catalogue#/
* Copernicus Global Land Service Providing bio-geophysical products of global land surface http://land.copernicus.eu/global/products/NDVI (included [Corine Land Cover products](http://land.copernicus.eu/pan-european/corine-land-cover))
* CESBIO Carte d'occupation des sols. http://www.cesbio.ups-tlse.fr/multitemp/?p=10104
* GEONETCast global network of satellite-based data dissemination systems providing environmental data http://www.eumetsat.int/website/home/Data/DataDelivery/EUMETCast/GEONETCast/index.html
* Bio-ORACLE Marine data layers for ecological modelling: http://www.bio-oracle.org/ (R invocation through ```sdmpredictors::list_layers("Bio-ORACLE", version=2)``` )
* MARSPEC monthly layers for temperature and salinity (R invocation through ```paleo: sdmpredictors::list_layers("MARSPEC")```) and paleo layers for these (R invocation through ```paleo: sdmpredictors::list_layers_paleo("MARSPEC")```): http://onlinelibrary.wiley.com/doi/10.1890/12-1358.1/abstract
* Use of sdmpredictor R package: 
```library(sdmpredictors)

# exploring the marine (you can also choose terrestrial) datasets 
datasets <- list_datasets(terrestrial = FALSE, marine = TRUE)
```
* Hub’eau Water related data (fishes,…) http://www.hubeau.fr/
* CRBPO data https://crbpodata.mnhn.fr/
* Movebank data https://www.movebank.org/
* API-Agro import agrifood related data http://www.api-agro.fr/
* Free GIS geographic datasets: http://freegisdata.rtwilson.com/
* Global Environmental Layers: http://worldgrids.org/doku.php
* World Conservation Monitoring Centre: https://www.unep-wcmc.org/
 * World Database on Protected Areas (WDPA) is the most comprehensive global database on terrestrial and marine protected areas.: https://protectedplanet.net/
* Chelsea Climate (Climatologies at high resolution for the earth’s land surface areas ): http://chelsa-climate.org/
* E-OBS gridded dataset : http://www.ecad.eu/download/ensembles/download.php

# Interesting tools
* Work with messy data from db
 * [OpenRefine](http://openrefine.org/) Implemented as GIE [docker repo](DockerHub repo : https://hub.docker.com/r/valentinchdock/openrefine-galaxy-ie/)
 * Other solutions:
    * [DataCleaner](https://datacleaner.org/) 
    * [Karma](http://usc-isi-i2.github.io/karma/) A Data Integration Tool
* Tadarida tools suite: A Toolbox for Animal Detection on Acoustic Recordings Integrating Discriminant Analysis
 * [Ubat slicer](https://github.com/mont29/ubat/): Tadarida pre-processing
 * [Tadarida-D](https://github.com/YvesBas/Tadarida-D)
 * [Tadarida-C](https://github.com/YvesBas/Tadarida-C)
 * [Tadarida-L](https://github.com/YvesBas/Tadarida-L)
* STOC (Temporal monitoring of common birds)
 * Simple punctual sampling
    * Regional scale: scriptSTOCeps.R
 * Capture
* STERF (Temporal Follow-up of France Rhopalocera)
   
   * TRIM is now also available as R package (rtrim, via install.packages("rtrim") from CRAN). This will make it much more easy for many of you to calculate trends. But remember to have the input file in good order (so with missing values and zeroes). Of course you can also use the result of Reto's regional_gam (https://github.com/RetoSchmucki/regionalGAM/blob/master/README.md) as input.
   * Manuals and helpfiles are available via https://github.com/markvanderloo/rtrim
   * CBS also made their Multi Species Indicator tool available: https://www.cbs.nl/nl-nl/maatschappij/natuur-en-milieu/indexen-en-trends--trim--/msi-tool. With this tool you can build your own indicators from the results of rtrim.
      * regionalGAM
      * rtrim
      * MSI-tool
* [Species distribution modeling](https://cran.r-project.org/web/packages/dismo/vignettes/sdm.pdf)
* [Maxent](https://biodiversityinformatics.amnh.org/open_source/maxent/)
* GIS data handling
   * [Geospatial Abstracation Data Librairy](http://www.gdal.org/)
   * Impute missing value: https://github.com/RetoSchmucki/CESCO_R-scripts/blob/master/replace%20missing%20values%20in%20raster.r
   * Sites extraction
   * Conversion
   * Buffering
   * Calculate mean by buffer
* Visualize GIS data
   * Through "classical" GIS specialists oriented solutions:
      * [Geoserver](http://geoserver.org/)
      * [QGIS server](https://github.com/jancelin/docker-qgis-server) ou [QGIS desktop](https://github.com/jancelin/docker-qgis-desktop). A particular interesting QGIS based tool : [LizMap](https://www.3liz.com/lizmap.html) et [LizMap Docker](https://github.com/jancelin/docker-lizmap)
      * [GeoCMS](https://github.com/dotgee/geocms) GeoCMS is a complete open source solution for consuming and visualizing geospatial data
      * ~~[OpenEV](http://openev.sourceforge.net/) a software library and application for viewing and analysing raster and vector geospatial data (last release 2007!)~~
   * To manage data:
      * [PostGIS](http://www.postgis.net/) with a [Docker version](https://github.com/jancelin/docker-postgis-rpi) usable through the [Galaxy pg datatype and relatde tools implementation](https://github.com/bgruening/galaxytools/pull/642) /[Leaflet](http://leafletjs.com/) through Interactive Environment ? 
      * [H2GIS](http://www.h2gis.org/support/) light and standalone GIS database
   * Through GIS non-specialists oriented solutions:
      * [Magrit](http://magrit.cnrs.fr/modules) for thematic GIS (in french and english)
* GIS data analysis
   * [WhiteboxTools advanced geospatial data analysis engine](https://github.com/jblindsay/whitebox-geospatial-analysis-tools/tree/master/whitebox_tools#available-tools)
   * [GeoTools The Open Source Java GIS Toolkit](http://www.geotools.org/)
   * [Grass Geographic Resources Analysis Support System](https://grass.osgeo.org/)
   * [NCAR Command Language](https://www.ncl.ucar.edu/index.shtml)
* Taxa automated recognition through [TensorFlow](https://tensorflow.wq.io/about)
* Dashboards for a community intensively oriented toward R
   * [R-Shiny](https://shiny.rstudio.com/) through Interactive Environment ?




# Collaborators

* Alan Amossé ([MNHN CESCO](http://cesco.mnhn.fr/) & [Concarneau marine biology station](http://concarneau.mnhn.fr/))
* Björn Grüning ([Freiburg University](http://www.bioinf.uni-freiburg.de/Galaxy/))
* Eloïse Trigodet ([MNHN CESCO](http://cesco.mnhn.fr/), [Concarneau marine biology station](http://concarneau.mnhn.fr/)) & [Brest IUEM University](https://www-iuem.univ-brest.fr/master_sml/fr/mentions-parcours/gestion-de-l-environnement)
* Mathias Rouan ([LETG](http://letg.cnrs.fr/auteur32.html))
* Nicolas Dubos ([MNHN CESCO](http://cesco.mnhn.fr/user/123))
* Thimothée Virgoulay ([MNHN CESCO](http://cesco.mnhn.fr/), [Concarneau marine biology station](http://concarneau.mnhn.fr/) & [Montpellier University](https://sns.edu.umontpellier.fr/master-sciences-numerique-pour-la-sante-montpellier/bcd/))
* Valentin Chambon ([MNHN CESCO](http://cesco.mnhn.fr/) & [Concarneau marine biology station](http://concarneau.mnhn.fr/))
* Yvan Le Bras ([MNHN CESCO](http://cesco.mnhn.fr/) & [Concarneau marine biology station](http://concarneau.mnhn.fr/))
* Yves Bas ([UMR CEFE](http://www.cefe.cnrs.fr/fr/recherche/bc/dpb/868-v/2827-yves-bas), [MNHN CESCO](http://cesco.mnhn.fr/))
