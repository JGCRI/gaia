% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/pkg_utils.R
\name{get_example_data}
\alias{get_example_data}
\title{get_example_data}
\usage{
get_example_data(
  download_url = "",
  file_extension = "zip",
  data_dir = file.path(getwd(), "example"),
  check_exist = TRUE
)
}
\arguments{
\item{download_url}{Default = ''. Link to the downloadable dataset}

\item{file_extension}{Default = 'zip'. String of file extension without "."}

\item{data_dir}{Default= file.path(getwd(), 'example'). Path of desired location to download data}

\item{check_exist}{Default = TRUE. Binary to check if the example data already exists. If TRUE, then function gives error if the downloaded folder already exist}
}
\value{
A string of path that the data is downloaded to
}
\description{
Download and extract data from a URL.
}
\details{
This function downloads a ZIP file from the specified URL and extracts its contents.
While it is designed for downloading gaia example data, it can be used for any dataset
as long as the provided URL points to a single ZIP file.
}
\examples{
\dontrun{
get_example_data(download_url = "https://example.com/data.zip", data_dir = "downloaded_data")
}
}
