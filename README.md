[![Join the chat at https://gitter.im/Galaxy-E/Lobby](https://badges.gitter.im/Galaxy-E/Lobby.svg)](https://gitter.im/Galaxy-E/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)


[![DOI](https://zenodo.org/badge/108133531.svg)](https://zenodo.org/badge/latestdoi/108133531)




![Concarneau Galaxy-E team 2018](https://github.com/65MO/Galaxy-E/blob/master/galaxy/static/Galaxy-E-concarneau-team-2018.gif)
# Context

Following [GCC2016 lightning talk](https://gcc16.sched.com/event/7Zgd/65-millions-of-observers "65 millions of observers"), and in the context of the french National Museum of Natural History MNHN project "65 Millions d'observateurs" dedicated to enhance and expand participation to citizen sciences projects studying biodiversity, a proof of concept of analysis web platform in macroecology will be made. We propose for this to use the [Galaxy web platform](https://github.com/galaxyproject/galaxy). Here is the origin of a Galaxy-E, for Ecology ?

# Galaxy-E
This repository will gather ideas and development of Galaxy-E tools

# A dedicated French version of Galaxy
 ~~Following the @dannon [PR](https://github.com/galaxyproject/galaxy/pull/3762) @ValentinChCloud will work on this task.~~
New version of the galaxy client incomming, a new PR has been open [PR](https://github.com/galaxyproject/galaxy/pull/5089)

# Interesting Data sources
## Species data
* Using R for occurences data through the spocc package: https://github.com/ropensci/spocc
* Clean up occurences with scrubr https://github.com/ropensci/scrubr
* Global Biodiversity Information Facility (GBIF) : https://www.gbif.org/developer/summary
* IDigBio
* PlutoF
* BARCODE OF LIFE DATA SYSTEM (BOLD), Advancing biodiversity science through DNA-based species identification: http://boldsystems.org/index.php/resources/api?type=webservices. Example of API request can be:
  * `http://boldsystems.org/index.php/API_Public/specimen?taxon=Aves&geo=Costa%20Rica&format=tsv`
  * `http://boldsystems.org/index.php/API_Public/specimen?taxon=Dicentrarchus%20labrax&geo=France&format=tsv`
  * `http://boldsystems.org/index.php/API_Public/specimen?taxon=taxon=Aves|Reptilia&geo=France&format=tsv`
## Environmental data
* IPSL https://cse.ipsl.fr/donnees/114-prodiguer
* WorldClim - Global Climate Data http://www.worldclim.org/
* Copernicus Climate Change Service Providing climate data http://climate.copernicus.eu/
* Copernicus Marine Environment Monitoring Service Providing products & services for all marine applications http://marine.copernicus.eu/
* Copernicus Atmosphere air quality & atmospheric composition https://atmosphere.copernicus.eu/catalogue#/
* Copernicus Global Land Service Providing bio-geophysical products of global land surface http://land.copernicus.eu/global/products/NDVI (included [Corine Land Cover products](http://land.copernicus.eu/pan-european/corine-land-cover))
* CESBIO Carte d'occupation des sols. http://www.cesbio.ups-tlse.fr/multitemp/?p=10104
* GEONETCast global network of satellite-based data dissemination systems providing environmental data http://www.eumetsat.int/website/home/Data/DataDelivery/EUMETCast/GEONETCast/index.html
* Donéens agricoles via Agreste: http://agreste.agriculture.gouv.fr/
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
   * [R-Shiny](https://shiny.rstudio.com/) Interactive Environment
      * GIS shiny GIE through leaflet based shiny apps to display data by french regions and related plots
      * Statistics shiny GIE through [radiant](http://vnijs.github.io/radiant/)
      * Dashboard / restitution shiny GIE through [flexdashboard+shiny](https://rmarkdown.rstudio.com/flexdashboard/shiny.html) or [shiny dashboard](https://rstudio.github.io/shinydashboard/structure.html)
      * Macroecology through [Wallace](http://onlinelibrary.wiley.com/doi/10.1111/2041-210X.12945/full)
   * Shiny and reproducibility through `interactive document` concept
      * rmarkdown, a new way to build Shiny apps through [interactive documents](http://shiny.rstudio.com/articles/interactive-docs.html)
      ```
      Interactive documents will not replace standard Shiny apps since they cannot provide the design options that come with a ui.R or index.html file. However, interactive documents do create some easy wins:

    The R Markdown workflow makes it easy to build light-weight apps. You do not need to worry about laying out your app or building an HTML user interface for the app.

    You can use R Markdown to create interactive slideshows, something that is difficult to do with Shiny alone. To create a slideshow, change output: html_document to output: ioslides_presentation in the YAML front matter of your .Rmd file. R Markdown will divide your document into slides when you click “Run Document.” A new slide will begin whenever a header or horizontal rule (***) appears.

    Interactive documents enhance the existing R Markdown workflow. R Markdown makes it easy to write literate programs and reproducible reports. You can make these reports even more effective by adding Shiny to the mix.

To learn more about R Markdown and interactive documents, please visit rmarkdown.rstudio.com.
      ```
# Interesting R packages

* [glmmTMB](https://cran.r-project.org/web/packages/glmmTMB/index.html)
* [biomod2](https://cran.r-project.org/web/packages/biomod2/index.html)
* [ENMEval](https://github.com/bobmuscarella/ENMeval)
* [virtualspecies](https://cran.r-project.org/web/packages/virtualspecies/index.html)
* [sdmplay](https://cran.r-project.org/web/packages/SDMPlay/index.html)
* [migclim](https://cran.r-project.org/web/packages/MigClim/index.html)
* [zoon](https://github.com/zoonproject/zoon)
* [bdvis](https://github.com/vijaybarve/bdvis)

# Interesting initiatives

* [Kaggle](https://www.kaggle.com/rtatman/welcome-to-data-science-in-r)



# Collaborators

* Alan Amossé ([MNHN CESCO](http://cesco.mnhn.fr/) & [Concarneau marine biology station](http://concarneau.mnhn.fr/))
* Björn Grüning ([Freiburg University](http://www.bioinf.uni-freiburg.de/Galaxy/))
* [Boyan Angelov](https://boyanangelov.com/))
* Eloïse Trigodet ([MNHN CESCO](http://cesco.mnhn.fr/), [Concarneau marine biology station](http://concarneau.mnhn.fr/)) & [Brest IUEM University](https://www-iuem.univ-brest.fr/master_sml/fr/mentions-parcours/gestion-de-l-environnement)
* Mathias Rouan ([LETG](http://letg.cnrs.fr/auteur32.html))
* Nicolas Dubos ([MNHN CESCO](http://cesco.mnhn.fr/user/123))
* Thimothée Virgoulay ([MNHN CESCO](http://cesco.mnhn.fr/), [Concarneau marine biology station](http://concarneau.mnhn.fr/) & [Montpellier University](https://sns.edu.umontpellier.fr/master-sciences-numerique-pour-la-sante-montpellier/bcd/))
* Valentin Chambon ([MNHN CESCO](http://cesco.mnhn.fr/) & [Concarneau marine biology station](http://concarneau.mnhn.fr/))
* Yvan Le Bras ([MNHN CESCO](http://cesco.mnhn.fr/) & [Concarneau marine biology station](http://concarneau.mnhn.fr/))
* Yves Bas ([UMR CEFE](http://www.cefe.cnrs.fr/fr/recherche/bc/dpb/868-v/2827-yves-bas), [MNHN CESCO](http://cesco.mnhn.fr/))
