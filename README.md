[![Join the chat at https://gitter.im/Galaxy-E/Lobby](https://badges.gitter.im/Galaxy-E/Lobby.svg)](https://gitter.im/Galaxy-E/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

# Context

Following [GCC2016 lightning talk](https://gcc16.sched.com/event/7Zgd/65-millions-of-observers "65 millions of observers"), and in the context of the french National Museum of Natural History MNHN project "65 Millions d'observateurs" dedicated to enhance and expand participation to citizen sciences projects studying biodiversity, a proof of concept of analysis web platform in macroecology will be made. We propose for this to use the [Galaxy web platform](https://github.com/galaxyproject/galaxy). Here is the origin of a Galaxy-E, for Ecology ?

# Galaxy-E
This repository will gather ideas and development of Galaxy-E tools 

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
 * regionalGAM
 * rtrim
 * MSI-tool
* [Species distribution modeling](https://cran.r-project.org/web/packages/dismo/vignettes/sdm.pdf)
* GIS data handling
 * Sites extraction
 * Conversion
 * Buffering
 * Calculate mean by buffer
* Visualize GIS data
 * [PostGIS](http://www.postgis.net/)/[Leaflet](http://leafletjs.com/) through Interactive Environment ?
 * [H2GIS](http://www.h2gis.org/support/) light and standalone GIS database
 * [Magrit](http://magrit.cnrs.fr/modules) for thematic GIS (in french and english)
* Dashboards for a community intensively oriented toward R
    * [R-Shiny](https://shiny.rstudio.com/) through Interactive Environment ?




# Collaborators

* Björn Grüning ([Freiburg University](http://www.bioinf.uni-freiburg.de/Galaxy/))
* Mathias Rouan ([LETG](http://letg.cnrs.fr/auteur32.html))
* Nicolas Dubos ([MNHN CESCO](http://cesco.mnhn.fr/user/123))
* Thimothée Virgoulay ([MNHN CESCO](http://cesco.mnhn.fr/), [Concarneau marine biology station](http://concarneau.mnhn.fr/) & [Montpellier University](https://sns.edu.umontpellier.fr/master-sciences-numerique-pour-la-sante-montpellier/bcd/))
* Yvan Le Bras ([MNHN CESCO](http://cesco.mnhn.fr/) & [Concarneau marine biology station](http://concarneau.mnhn.fr/))
* Yves Bas ([UMR CEFE](http://www.cefe.cnrs.fr/fr/recherche/bc/dpb/868-v/2827-yves-bas), [MNHN CESCO](http://cesco.mnhn.fr/))
