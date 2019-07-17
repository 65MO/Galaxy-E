Estimate temporal evolution of of population per species  - FunctTrendSTOCGalaxy.r
This script analyse the temporal evolution of species population and create graphical vizualisation.


Script needs the followings inputs
 - stoc or community data filtered with at least 4 columns: year, site, species, and abundance (with 0, wich corresponds to "observed" or predicted 0 abundance)
may come from the tools "makeTableAnalysis" (Preprocess population data and change the format) followed by "FilteringLowRareSP" (remove species with too low abundance or that have zero abundance everywhere and reformat the file)
 - species name and indicator status file with at least 2 columns: the species name or species ID (found in the community data or in stoc data) and his status as indicator species

Arguments are :
 - figure : create also figures as output
 - spExclude: list of species (using the the species name or ID, the one found in the community data) that you want to exclude
 - assessIC : compute and show confidence interval in plots (TRUE or FALSE, by default is TRUE)
 - description: create figure with 3 panels, one for the predicted abundance for the period, one with the occurence (number of sites with the species) (TRUE or FALSE, by default is TRUE)


How to execute, eg :
 # all files are available in github repo
 $ Rscript FunctTrendSTOCGalaxy.r test-data/Datafilteredfortrendanalysis2.tabular tabSpecies.csv  

Outputs are created in an Output repo :
GLM gives 1 graph per species and 2 tables:
 - nameofspecies_id.png
 - tendanceGlobalEspece_id.tabular
 - variationsAnnuellesEspece_id.tabular

R library needed
r-lme4  version 1.1.18.1
r-ggplot2  version 3.0.0
r-speedglm  version 0.3.2
r-arm  version 1.10.1
r-reshape  version 0.8.8
r-data.table  version 1.12.0
r-reshape2   version 1.4.3
