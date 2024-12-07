% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/gcam_agprodchange.R
\name{gcam_agprodchange}
\alias{gcam_agprodchange}
\title{gcam_agprodchange}
\usage{
gcam_agprodchange(
  data = NULL,
  climate_model = "gcm",
  climate_scenario = "rcp",
  member = "member",
  bias_adj = "ba",
  gcam_version = "gcam7",
  cfe = "no-cfe",
  diagnostics = TRUE,
  output_dir = file.path(getwd(), "output")
)
}
\arguments{
\item{data}{Default = NULL. output data from function yield_shock_projection, or similar format of data}

\item{climate_model}{Default = 'gcm'. string for climate model name (e.g., 'CanESM5')}

\item{climate_scenario}{Default = 'rcp'. string for climate scenario name (e.g., 'ssp245')}

\item{member}{Default = 'member'. string for the ensemble member name}

\item{bias_adj}{Default = 'ba'. string for the dataset used for climate data bias adjustment}

\item{gcam_version}{Default = 'gcam7'. string for the GCAM version. Only support gcam6 and gcam7}

\item{cfe}{Default = 'no-cfe'. string for whether the yield impact formula implimented CO2 fertilization effect.}

\item{diagnostics}{Default = TRUE. Logical for performing diagnostic plot}

\item{output_dir}{Default = file.path(getwd(), 'output'). String for output directory}
}
\description{
Map country level yield impacts to GCAM region-GLU level
Calculate agricultural productivity change by region GLU
Output agprodchange XML
}
