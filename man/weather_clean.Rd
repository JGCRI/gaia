% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/yield_impacts_functions.R
\name{weather_clean}
\alias{weather_clean}
\title{weather_clean}
\usage{
weather_clean(
  file = NULL,
  crop_name = NULL,
  weather_var = NULL,
  irr_type = NULL,
  time_periods = NULL
)
}
\arguments{
\item{file}{Default = NULL. String for the path to the climate file}

\item{crop_name}{Default = NULL. String for the crop name}

\item{weather_var}{Default = NULL. String for the weather var name}

\item{irr_type}{Default = NULL. String for the irrigation type. Options: 'irr', 'rf'}

\item{time_periods}{Default = NULL. vector for years to subset from the climate data. If NULL, use the default climate data period}
}
\value{
A data frame of formatted weather data
}
\description{
Function to clean the input weather files (historic and model projections) for regression analysis
}
\keyword{internal}
