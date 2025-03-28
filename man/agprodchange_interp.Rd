% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/pkg_utils.R
\name{agprodchange_interp}
\alias{agprodchange_interp}
\title{agprodchange_interp}
\usage{
agprodchange_interp(data = NULL, gcam_timestep = 5)
}
\arguments{
\item{data}{= NULL. Data frame of the agprodchange}

\item{gcam_timestep}{Default = 5. Integer for the time step of GCAM (Select either 1 or 5 years for GCAM use)}
}
\value{
A data frame of the interpolated data
}
\description{
Check if the reference agricultural productivity has the same timestep as the user defined timestep
If not, linearly interpolate the value
}
\keyword{internal}
