<!-- badges: start -->
[![R-CMD-check.yaml](https://github.com/JGCRI/gaia/actions/workflows/R-CDM-check.yaml/badge.svg?branch=main)](https://github.com/JGCRI/gaia/actions/workflows/R-CDM-check.yaml)
[![test-coverage.yaml](https://github.com/JGCRI/gaia/actions/workflows/test-coverage.yaml/badge.svg)](https://github.com/JGCRI/gaia/actions/workflows/test-coverage.yaml)
[![codecov](https://codecov.io/gh/JGCRI/gaia/branch/main/graph/badge.svg?token=XQ913U4IYM)](https://codecov.io/gh/JGCRI/gaia)
[![docs](https://github.com/JGCRI/gaia/actions/workflows/docs.yaml/badge.svg)](https://github.com/JGCRI/gaia/actions/workflows/docs.yaml)
<!-- badges: end -->



<!-- ------------------------>
<!-- ------------------------>
# <a name="Introduction"></a>Introduction
<!-- ------------------------>
<!-- ------------------------>

`gaia` is an open-source R package designed to estimate crop yield shocks in response to annual climate variations and CO2 concentrations at the country scale for 12 major crops. `gaia` streamlines the workflow from raw climate data processing to the production of different forms of yield shock, such as agricultural productivity changes at the region-basin level, which can be directly integrated into the latest Global Change Analysis Model (GCAM).

<br />

<p align="center">
<a href="https://jgcri.github.io/gaia/" target="_blank"><img src="https://github.com/JGCRI/jgcricolors/blob/main/vignettes/button_user_guide.PNG?raw=true" 
alt="https://jgcri.github.io/gaia/articles/vignette.html" height="60"/></a>
<img src="https://github.com/JGCRI/jgcricolors/blob/main/vignettes/button_divider.PNG?raw=true" height="40"/>
</p>

<!-- ------------------------>
<!-- ------------------------>
# <a name="Citation"></a>Citation
<!-- ------------------------>
<!-- ------------------------>

> Zhao, M., Waldhoff, S., Tebaldi, C., Snyder, A. 2024. gaia: An R package to estimate crop yield responses to temperature and precipitation. (In progress) Journal of Open Source Software, DOI: XXXX

<br/>

<!-- ------------------------>
<!-- ------------------------>
# <a name="InstallGuide"></a>Installation Guide
<!-- ------------------------>
<!-- ------------------------>

1. Download and install:
    - R (https://www.r-project.org/)
    - R studio (https://www.rstudio.com/)  


2. Open R studio:

```r
install.packages("devtools")
devtools::install_github("JGCRI/gaia")
```

or

```r
install.packages("remotes")
remotes::install_github("JGCRI/gaia")
```

Additional steps for UBUNTU from a terminal

```
sudo add-apt-repository ppa:ubuntugis/ppa
sudo apt-get update
sudo apt-get install libudunits2-dev libgdal-dev libgeos-dev libproj-dev libmagick++-dev
```

Additional steps for MACOSX from a terminal

```
brew install pkg-config
brew install gdal
```

<br/>


<!-- ------------------------>
<!-- ------------------------>
# <a name="Publications"></a>Related Publications
<!-- ------------------------>
<!-- ------------------------>

> Waldhoff, S.T., Wing, I.S., Edmonds, J., Leng, G. and Zhang, X., 2020. Future climate impacts on global agricultural yields over the 21st century. Environmental Research Letters, 15(11), p.114010. https://doi.org/10.1088/1748-9326/abadcb

<br/>

<!-- ------------------------>
<!-- ------------------------>
# <a name="Contributing"></a>Contributing
<!-- ------------------------>
<!-- ------------------------>

Whether you find a typo in the documentation, find a bug, or want to develop functionality that you think will make `gaia` more robust, you are welcome to contribute! The [contributing](https://github.com/JGCRI/gaia/blob/main/CONTRIBUTING.md) page will walk you through processes to contribute to `gaia`.