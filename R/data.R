
#' co2_historical
#'
#' Historical annual mean CO2 concentration from NOAA https://gml.noaa.gov/ccgg/trends/global.html
#'
#' @source ftp://aftp.cmdl.noaa.gov/products/trends/co2/co2_annmean_mlo.txt
#' @examples
#' \dontrun{
#'  library(gaia);
#'  co2_historical <- gaia::co2_historical
#' }
"co2_historical"


#' co2_projection
#'
#' Projected global annual mean CO2 concentration based on GCAM7 Reference scenario, which is aligned with RCP7.0. Obtained from running default GCAM7 Reference scenario. This is the default CO2 projection used in gaia. User can update the CO2 concentration if preferred by using the argument co2_proj from yield_impact function.
#'
#' @source https://gmd.copernicus.org/articles/12/677/2019/gmd-12-677-2019.html
#' @format R data frame
#' @examples
#' \dontrun{
#'  library(gaia);
#'  co2_projection <- gaia::co2_projection
#' }
"co2_projection"


#' agprodchange_ni_gcam7
#'
#' Agricultural productivity change from GCAM7 Reference scenario
#'
#' @source https://jgcri.github.io/gcam-doc/inputs_supply.html
#' @format R data frame
#' @examples
#' \dontrun{
#'  library(gaia);
#'  agprodchange_ni_gcam7 <- gaia::agprodchange_ni_gcam7
#' }
"agprodchange_ni_gcam7"

#' agprodchange_ni_gcam6
#'
#' #' Agricultural productivity change from GCAM6 Reference scenario
#'
#' @source https://jgcri.github.io/gcam-doc/inputs_supply.html
#' @format R data frame
#' @examples
#' \dontrun{
#'  library(gaia);
#'  agprodchange_ni_gcam6 <- gaia::agprodchange_ni_gcam6
#' }
"agprodchange_ni_gcam6"

#' coef_default
#'
#' @source Regression coefficients derived from the default historical WATCH climate data
#' @format R data frame
#' @examples
#' \dontrun{
#'  library(gaia);
#'  coef_default <- gaia::coef_default
#' }
"coef_default"

#' country_id
#'
#' @source country ID and name mapping
#' @format R data frame
#' @examples
#' \dontrun{
#'  library(gaia);
#'  country_id <- gaia::country_id
#' }
"country_id"
