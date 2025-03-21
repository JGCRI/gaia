% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/pkg_utils.R
\name{output_data}
\alias{output_data}
\title{output_data}
\usage{
output_data(
  data = NULL,
  save_path = file.path(getwd(), "output"),
  file_name = NULL,
  is_figure = FALSE,
  data_info = "Data"
)
}
\arguments{
\item{data}{Default = NULL. Data frame}

\item{save_path}{Default = NULL. String for path to the output folder}

\item{file_name}{Default = NULL. String for file name}

\item{is_figure}{Default = FALSE. Binary for saving figure}

\item{data_info}{Default = 'Data'. String for describing the data information}
}
\value{
No return value, called for the side effects of writing output files
}
\description{
write output
}
\keyword{internal}
