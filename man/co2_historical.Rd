% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data.R
\docType{data}
\name{co2_historical}
\alias{co2_historical}
\title{co2_historical}
\format{
An object of class \code{data.table} (inherits from \code{data.frame}) with 57 rows and 2 columns.
}
\source{
ftp://aftp.cmdl.noaa.gov/products/trends/co2/co2_annmean_mlo.txt
}
\usage{
co2_historical
}
\description{
Historical annual mean CO2 concentration from NOAA https://gml.noaa.gov/ccgg/trends/global.html
}
\examples{
\dontrun{
 library(gaia);
 co2_historical <- gaia::co2_historical
}
}
\keyword{datasets}
