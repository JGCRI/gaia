# get_example_data

Download and extract data from a URL.

## Usage

``` r
get_example_data(
  download_url = "",
  file_extension = "zip",
  data_dir = file.path(getwd(), "example"),
  check_exist = TRUE
)
```

## Arguments

- download_url:

  Default = ”. Link to the downloadable dataset

- file_extension:

  Default = 'zip'. String of file extension without "."

- data_dir:

  Default= file.path(getwd(), 'example'). Path of desired location to
  download data

- check_exist:

  Default = TRUE. Binary to check if the example data already exists. If
  TRUE, then function gives error if the downloaded folder already exist

## Value

A string of path that the data is downloaded to

## Details

This function downloads a ZIP file from the specified URL and extracts
its contents. While it is designed for downloading gaia example data, it
can be used for any dataset as long as the provided URL points to a
single ZIP file.

## Examples

``` r
if (FALSE) { # \dontrun{
get_example_data(download_url = "https://example.com/data.zip", data_dir = "downloaded_data")
} # }
```
