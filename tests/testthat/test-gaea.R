library(gaea); library(testthat);

timestep = 'monthly'
# climate_model = 'canesm5'
# climate_scenario = 'gcam-ref'
# time_periods = seq(2015, 2020, 1)
output_dir = file.path(getwd(), 'output')

# Run tests for each function
test_that("weighted_climate runs correctly", {
  testthat::expect_error(gaea::weighted_climate(timestep = NULL))
})

# Run tests for each function
test_that("crop_calendars runs correctly", {
  crop_cal <- gaea::crop_calendars(output_dir = output_dir)
  testthat::expect_snapshot_file(
    testthat::test_path('output', 'data_processed', 'crop_calendar.csv'))
})
