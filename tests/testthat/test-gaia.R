# library(sf)

testthat::skip_on_cran()
testthat::skip_on_travis()

# download data
output_dir_i <- file.path(getwd(), 'output')

data_dir_i <- gaia::get_example_data(
  download_url = 'https://zenodo.org/records/14888816/files/weighted_climate.zip?download=1',
  data_dir = output_dir_i)


# ------------------------------------
# Testing Outputs from Major Functions
# ------------------------------------

test_that("crop_calendars function test", {

  # test default crops
  out_crop_calendars_default <- run_crop_calendars(crop_select = NULL,
                                                   output_dir = output_dir_i)

  # test all available crops
  out_crop_calendars <- run_crop_calendars(output_dir = output_dir_i)

  testthat::expect_snapshot(out_crop_calendars_default)
  testthat::expect_snapshot(out_crop_calendars)

})

test_that("data_aggregation function test", {

  # test function with user provided co2
  out_data_aggregation_custom <- run_data_aggregation(data_dir = data_dir_i)

  # test function with default co2
  out_data_aggregation <- run_data_aggregation(data_dir = data_dir_i,
                                               co2_hist = NULL,
                                               co2_proj = NULL,)

  testthat::expect_snapshot(out_data_aggregation_custom)
  testthat::expect_snapshot(out_data_aggregation)


})


test_that("yield_regression function test", {

  out_yield_regression <- run_yield_regression()

  testthat::expect_snapshot(out_yield_regression)

})

test_that("yield_shock_projection function test", {

  out_yield_projections <- run_yield_shock_projection()

  testthat::expect_snapshot(out_yield_projections)

})


test_that("gcam_agprodchange function test", {

  out_yield_projections <- run_yield_shock_projection()
  out_gcam_agprodchange <- run_gcam_agprodchange(data = out_yield_projections)

  testthat::expect_snapshot(out_gcam_agprodchange)

})
