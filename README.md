[![Join the chat at https://gitter.im/Galaxy-E/Lobby](https://badges.gitter.im/Galaxy-E/Lobby.svg)](https://gitter.im/Galaxy-E/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

# Context

Following [GCC2016 lightning talk](https://gcc16.sched.com/event/7Zgd/65-millions-of-observers "65 millions of observers"), and in the context of the french National Museum of Natural History MNHN project "65 Millions d'observateurs" dedicated to enhance and expand participation to citizen sciences projects studying biodiversity, a proof of concept of analysis web platform in macroecology will be made. We propose for this to use the [Galaxy web platform](https://github.com/galaxyproject/galaxy). Here is the origin of a Galaxy-E, for Ecology ?

# Galaxy-E
This repository will gather ideas and development of Galaxy-E tools 

# A dedicated French version of Galaxy
Following the @dannon [PR](https://github.com/galaxyproject/galaxy/pull/3762) @ValentinChCloud will work on this task.

# Interesting tools
* Work with messy data from db
 * [OpenRefine](http://openrefine.org/) through Interactive Environment ?
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
   * [PostGIS](http://www.postgis.net/) usable through the [Galaxy pg datatype and relatde tools implementation] (https://github.com/bgruening/galaxytools/pull/642) /[Leaflet](http://leafletjs.com/) through Interactive Environment ?
   * [H2GIS](http://www.h2gis.org/support/) light and standalone GIS database
   * [GeoCMS](https://github.com/dotgee/geocms) GeoCMS is a complete open source solution for consuming and visualizing geospatial data
   * [Magrit](http://magrit.cnrs.fr/modules) for thematic GIS (in french and english)
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
