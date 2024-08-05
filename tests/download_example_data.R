


download_test_data <- function() {

  # download test data
  output_dir_i <- file.path(getwd(), 'output')

  data_dir_i <- gaea::get_example_data(
    download_url = 'https://zenodo.org/records/13179630/files/weighted_climate.zip?download=1',
    data_dir = output_dir_i)

}

# Run the function if this script is being sourced
if (!interactive()) {
  download_test_data()
}
