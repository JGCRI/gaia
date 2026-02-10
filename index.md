# Introduction

`gaia` is an open-source R package designed to estimate crop yield
shocks in response to annual temperature and precipitation variations
and CO₂ concentrations at the country scale for 17 major crops. `gaia`
streamlines the workflow from raw climate data processing to the
production of different forms of yield shocks, such as agricultural
productivity changes at the region-basin level, which can be directly
integrated into the latest Global Change Analysis Model (GCAM).

  

[![https://jgcri.github.io/gaia/articles/vignette.html](https://github.com/JGCRI/gaia/blob/main/vignettes/vignetteFigs/button_user_guide.png?raw=true)](https://jgcri.github.io/gaia/articles/vignette.html)
![](https://github.com/JGCRI/jgcricolors/blob/main/vignettes/button_divider.PNG?raw=true)

# Citation

> Zhao, M., Morris, S.T., Tebaldi, C., Snyder, A., (2025). gaia: An R
> package to estimate crop yield responses to temperature and
> precipitation. Journal of Open Source Software, 10(111), 7538,
> <https://doi.org/10.21105/joss.07538>

  

# Installation Guide

1.  Download and install:
    - R (<https://www.r-project.org/>)
    - R studio (<https://www.rstudio.com/>)
2.  Open R studio:

``` r
install.packages("devtools")
devtools::install_github("JGCRI/gaia")
```

or

``` r
install.packages("remotes")
remotes::install_github("JGCRI/gaia")
```

Additional steps for UBUNTU from a terminal

    sudo add-apt-repository ppa:ubuntugis/ppa
    sudo apt-get update
    sudo apt-get install libudunits2-dev libgdal-dev libgeos-dev libproj-dev libmagick++-dev

Additional steps for MACOSX from a terminal

    brew install pkg-config
    brew install gdal

  

# Related Publications

> Waldhoff, S.T., Wing, I.S., Edmonds, J., Leng, G. and Zhang, X., 2020.
> Future climate impacts on global agricultural yields over the 21st
> century. Environmental Research Letters, 15(11), p.114010.
> <https://doi.org/10.1088/1748-9326/abadcb>

  

# Contributing

Whether you find a typo in the documentation, find a bug, or want to
develop functionality that you think will make `gaia` more robust, you
are welcome to contribute! The
[contributing](https://jgcri.github.io/gaia/CONTRIBUTING.html) page will
walk you through processes to contribute to `gaia`.
