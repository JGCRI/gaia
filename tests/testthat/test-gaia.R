# library(sf)

testthat::skip_on_cran()
testthat::skip_on_travis()

# download data
output_dir_i <- file.path(getwd(), 'output')

data_dir_i <- gaia::get_example_data(
  download_url = 'https://zenodo.org/records/14888816/files/weighted_climate.zip?download=1',
  data_dir = output_dir_i)

ncdf_dir_i <- gaia::get_example_data(
  download_url = 'https://zenodo.org/records/14888816/files/gaia_example_climate.zip?download=1',
  data_dir = output_dir_i)


# ------------------------------------
# Testing Outputs from Major Functions
# ------------------------------------

test_that("weighted_climate function test", {

  pr_ncdf_i <- file.path(ncdf_dir_i, 'pr_monthly_canesm5_w5e5_ssp245_2015_2030.nc')
  tas_ncdf_i <- file.path(ncdf_dir_i, 'tas_monthly_canesm5_w5e5_ssp245_2015_2030.nc')

  run_weighted_climate(pr_ncdf = pr_ncdf_i,
                       tas_ncdf = tas_ncdf_i,
                       timestep = "monthly",
                       climate_model = "canesm5",
                       climate_scenario = "ssp245",
                       time_periods = seq(2015, 2030, 1),
                       output_dir = file.path(getwd(), "output", "weighted_climate_test"))

})

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


test_that("clean_yield test", {

  fao_yield_i <- gaia::input_data(
    folder_path = system.file('extdata', package = 'gaia'),
    input_file = 'Production_Crops_Livestock_E_All_Data_NOFLAG.csv',
    skip_number = 0
  )

  fao_yield_clean <- gaia::clean_yield(fao_yield = fao_yield_i,
                                       fao_to_mirca = fao_to_mirca)

  testthat::expect_snapshot(fao_yield_clean)

})

# ------------------------------------
# Testing Errors
# ------------------------------------
test_that("agprodchange_ref test and error message", {

  testthat::expect_error(
    agprodchange_ref(
      gcam_version = "gcam7",
      gcam_timestep = 3,
      base_year = 2015,
      climate_scenario = 'ssp5',
      gcamdata_dir = file.path(system.file('extdata', package = 'gaia'), 'gcamdata')
    ),
    class = 'error'
  )

  apg_ssp1 <- agprodchange_ref(
    gcam_version = "gcam7",
    gcam_timestep = 5,
    base_year = 2015,
    climate_scenario = 'ssp1',
    gcamdata_dir = NULL
  )

  apg_ssp2 <- agprodchange_ref(
    gcam_version = "gcam7",
    gcam_timestep = 5,
    base_year = 2015,
    climate_scenario = 'ssp2',
    gcamdata_dir = NULL
  )

  apg_ssp3 <- agprodchange_ref(
    gcam_version = "gcam7",
    gcam_timestep = 5,
    base_year = 2015,
    climate_scenario = 'ssp3',
    gcamdata_dir = NULL
  )

  apg_ssp4 <- agprodchange_ref(
    gcam_version = "gcam7",
    gcam_timestep = 5,
    base_year = 2015,
    climate_scenario = 'ssp4',
    gcamdata_dir = NULL
  )

  testthat::expect_snapshot(apg_ssp1)
  testthat::expect_snapshot(apg_ssp2)
  testthat::expect_snapshot(apg_ssp3)
  testthat::expect_snapshot(apg_ssp4)

})

test_that("get_example_data message", {

  testthat::expect_message(
    get_example_data(
      download_url = 'https://zenodo.org/records/14888816/files/weighted_climate.zip?download=1',
      data_dir = output_dir_i
    )
  )


})


test_that("get_mirca2000_data message", {

  testthat::expect_message(
    get_mirca2000_data(
      data_dir = file.path(output_dir_i, 'gcam7_agprodchange_no-cfe')
    )
  )


})
