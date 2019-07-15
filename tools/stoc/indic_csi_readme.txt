CSI Temporal analysis indocator - FunctExeTemporalAnalysisofIndicatorTrait.r
This script compute the indicator per year and position, and create graphical vizualisation.

Script needs the followings inputs
 - stoc data filtered
 - species details file
 - specialization details file
 - spatial coordinates data file
 - file that stocks functions : "FunctTrendSTOCGalaxy.r"
 - optional : precomputed community file

Arguments are :
 - method : gam or glmmtmb
 - plot_smooth : add a vizualisation when used with gam method
 - ic : compute and show confidence interval in plots

Outputs are created in a Otuput repo.


How to execute, eg :
 # all files are available in github repo
 # Smooth vizu + no ic, method gam, no precomputed community file
 $ Rscript FunctExeTemporalAnalysisofIndicatorTrait.r test-data/Datafilteredfortrendanalysis2.tabular tabSpecies.csv species_indicateur_fonctionnel.tabular coordCarreSTOCfaux.tabular "ssi" "csi" "gam" "" "idindicatortrait" TRUE FALSE FunctTrendSTOCGalaxy.r


Gam method gives :
  - csi_gammCOMPLET_France.tabular
  - csi_gammParannee_France.tabular
  - figcsi_carre_France.png

 if smooth_plot option is set to TRUE, adds : 
  - csi_gammsmoothFrance.tabular
  - figcsi_plotFrance.png


Glmmtmb method gives :
  - csi_glmmTMB_France.png
  - ggdata_csiFrance.tabular
  - GlmmTMB_coefficient_csiFrance.tabular

