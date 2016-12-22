# Github link
[RetoSchmucki Github regionalGAM code link](https://github.com/RetoSchmucki/regionalGAM)

Description from original RetoSchmucki/regionalGAM Github README:

## RegionalGAM

With the rapid expansion of monitoring efforts and the usefulness of conducting integrative analyses to inform conservation initiatives, the choice of a robust abundance index is crucial to adequately assess the species status. Butterfly Monitoring Schemes (BMS) operate in increasing number of countries with broadly the same methodology, yet they differ in their observation frequencies and often in the method used to compute annual abundance indices.

Here we implemented the method for computing an abundance index with the *regional GAM* approach, an extension of the two-stages model introduced by [Dennis et al. (2013)](http://onlinelibrary.wiley.com/doi/10.1111/2041-210X.12053/abstract). This index offers the best performance for a wide range of sampling frequency, providing greater robustness and unbiased estimates compared to the popular linear interpolation approach [(Schmucki et al. 2015)](http://onlinelibrary.wiley.com/doi/10.1111/1365-2664.12561/abstract).

#### Suggested citation

Schmucki R., Pe’er G., Roy D.B., Stefanescu C., Van Swaay C.A.M., Oliver T.H., Kuussaari M., Van Strien A.J., Ries L., Settele J., Musche M., Carnicer J., Schweiger O., Brereton T. M., Harpke A., Heliölä J., Kühn E. & Julliard R. (2016) A regionally informed abundance index for supporting integrative analyses across butterfly monitoring schemes. Journal of Applied Ecology. Vol. 53 (2) 501–510. DOI: 10.1111/1365-2664.12561


#### Installation

To install this package from GitHub, you will fist need to install the package `devtools` that is available from CRAN. From there, simply use the the function `install_github()` to install the `RegionalGAM` package on your system. Note that this package was build with R 3.2, so you might have to update your R installation. If you are unable to install this package, you might consider sourcing the R script that can be found here: [RegionalGAM source code] (https://github.com/RetoSchmucki/regionalGAM/blob/master/R/dennis_gam_initial_functions.R)

```R
install.packages("devtools")
library(devtools)
install_github("RetoSchmucki/regionalGAM")
```

For reporting errors and issues related to this package and its functions, please open a [issue here](https://github.com/RetoSchmucki/regionalGAM/issues)

#### Example

The package comes with a data set that contains butterfly count for the Gatekeeper (Pironia tithonus) collected between 2003 and 2012 and extracted from five European BMSs (UK, NL, FR, DE, and Catalonia-ES) for monitoring sites found in the Cold Temperate and Moist bioclimatic region [see Metzger et al. 2013](http://www.research-innovation.ed.ac.uk/Opportunities/global-environmental-stratification-map.aspx#page=features). This data set is associated with the results provided in Schmucki et al. 2015.

```R
library(RegionalGAM)

data("gatekeeper_CM")
head(gatekeeper_CM)
```

The `gatekeeper_CM` data set contains counts for x sites. From this dataset we can compute the regional flight curve that define the expected pattern of abundance of adult butterfly in this specific region. The dataset provided to the function `fligth_curve` must correspond the specific region. In a near future, I am planning to implement additional functions that will facilitate will divide your data into specific regions, stay tuned. 

Note that the data set is structured with six columns, defining 1. species name, 2. monitoring site, 3. observation year, 4. observation month, 5. observation day, and 6. butterfly count. The extra column, TREND, found in the `gatekeeper_CM` data is not required in the `flight_curve()` function. 

```R	
dataset1 <- gatekeeper_CM[,c("SPECIES","SITE","YEAR","MONTH","DAY","COUNT")]

# compute the annual flight curve, you might get yourself a coffee as this might take some time.
pheno <- flight_curve(dataset1)
	
# plot pheno for year 2005
plot(pheno$DAYNO[pheno$year==2005],pheno$nm[pheno$year==2005],pch=19,cex=0.7,type='o',col='red',xlab="day",ylab="relative abundance")
```

We can now use the annual flight curve contained in the object `pheno` to impute expected count values where weekly counts are missing and thereby compute at each site, the cumulated butterfly days, or weeks as we are dividing the index by seven, over a monitoring season as annual abundance index. Here we will compute abundance indices for a subset of site, showing that you don't need to have the use the same sites that where used for computing the flight curves. But of course, the climate region should correspond as we assume that this curve is region specific.

```R
dataset2 <- gatekeeper_CM[gatekeeper_CM$TREND==1,c("SPECIES","SITE","YEAR","MONTH","DAY","COUNT")]
	
data.index <- abundance_index(dataset2, pheno)
```

With the abundance index computed for each site and monitoring year, we can now compute a collated index for each year and estimate the temporal trend. This can be done with the software [TRIM](http://www.cbs.nl/en-GB/menu/themas/natuur-milieu/methoden/trim/default.htm), or in R as shown here. Note that this is a short and minimalist example for trend estimation and more step might be needed to produce sound trend analysis (e.g. stratification per habitat type, bootstrap confidence interval estimation).

```R
# load required packages
library(nlme)
library(MASS)
```

A collated index correspond to the expected value for a year, when taking into account the variation contained among sites. Here we also add an autoregressive term to account for temporal autocorrelation in the time series `corAR1`.

```R
# compute collated annual indices
glmm.mod_fullyear <- glmmPQL(regional_gam~ as.factor(YEAR)-1,data=data.index,family=quasipoisson,random=~1|SITE, correlation = corAR1(form = ~ YEAR | SITE),verbose = FALSE)
summary(glmm.mod_fullyear)

# extract collated index and plot against years
col.index <- as.numeric(glmm.mod_fullyear$coefficients$fixed)
year <- unique(data.index$YEAR)
plot(year,col.index,type='o', xlab="year",ylab="collated index")
```

From the collated indices, you can now compute a temporal trend for that species in this region. Here we first use a simple linear model and explore for temporal autocorrelation that we will account in our final model.

```R
# model temporal trend with a simple linear regression
mod1 <- gls(col.index ~ year)
summary(mod1)

# check for temporal autocorrelation in the residuals
acf(residuals(mod1,type="normalized"))

# adjust the model to account for autocorrelation in the residuals
mod2 <- gls(col.index ~ year, correlation = corARMA(p=2))
summary(mod2)
	
# check for remaining autocorrelation in the residuals
acf(residuals(mod2,type="normalized"))

# plot abundance with trend line
plot(year,col.index, type='o',xlab="year",ylab="collated index")
abline(mod2,lty=2,col="red")
```

Here the temporal trend is the year effect estimated in your final model. Note that more sophisticated models can be implemented and that confidence intervals around collated indices could be estimated with a bootstrap procedure.

#### TO DO
* Improve function documentation
* Add GAM function with big-data optimization
* Include flexibility in start and end day definition
* Include a map object for bioclimatic regions to build regional datasets


