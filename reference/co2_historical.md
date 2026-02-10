# co2_historical

Historical annual mean CO2 concentration (in parts per million) from
NOAA https://gml.noaa.gov/ccgg/trends/global.html

## Usage

``` r
co2_historical
```

## Format

An object of class `data.table` (inherits from `data.frame`) with 57
rows and 2 columns.

## Source

ftp://aftp.cmdl.noaa.gov/products/trends/co2/co2_annmean_mlo.txt

## Examples

``` r
if (FALSE) { # \dontrun{
 library(gaia);
 co2_historical <- gaia::co2_historical
} # }
```
