# co2_projection

Projected global annual mean CO2 concentration (in parts per million)
based on GCAM7 Reference scenario, which is aligned with RCP7.0.
Obtained from running default GCAM7 Reference scenario. This is the
default CO2 projection used in gaia. User can update the CO2
concentration if preferred by using the argument co2_proj from
yield_impact function.

## Usage

``` r
co2_projection
```

## Format

R data frame

## Source

https://gmd.copernicus.org/articles/12/677/2019/gmd-12-677-2019.html

## Examples

``` r
if (FALSE) { # \dontrun{
 library(gaia);
 co2_projection <- gaia::co2_projection
} # }
```
