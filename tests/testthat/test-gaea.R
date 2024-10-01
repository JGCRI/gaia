library(sf)

testthat::skip_on_cran()
testthat::skip_on_travis()

# download data
output_dir_i <- file.path(getwd(), 'output')

data_dir_i <- gaea::get_example_data(
  download_url = 'https://zenodo.org/records/13179630/files/weighted_climate.zip?download=1',
  data_dir = output_dir_i)


# ------------------------------------
# Testing Outputs from Major Functions
# ------------------------------------

test_that("crop_calendars runs correctly", {

  out_crop_calendars <- run_crop_calendars()

  testthat::expect_snapshot(out_crop_calendars)

  # testthat::expect_snapshot_file(
  #   testthat::test_path('output', 'data_processed', 'crop_calendar.csv'))

})

test_that("data_aggregation runs correctly", {

  out_data_aggregation <- run_data_aggregation(data_dir = data_dir_i)

  testthat::expect_snapshot(out_data_aggregation)

  # testthat::expect_snapshot_file(
  #   testthat::test_path('output', 'data_processed', 'weather_canesm5_gcam-ref_wheat.csv'))
  # testthat::expect_snapshot_file(
  #   testthat::test_path('output', 'data_processed', 'historic_vars_wheat.csv'))


})


test_that("yield_regression runs correctly", {

  out_yield_regression <- run_yield_regression()

  testthat::expect_snapshot(out_yield_regression)

  # testthat::expect_snapshot_file(
  #   testthat::test_path('output', 'data_processed', 'reg_out_wheat_fit_lnyield_mmm_quad_noco2_nogdp.csv'))
  # testthat::expect_snapshot_file(
  #   testthat::test_path('output', 'data_processed', 'weather_yield_wheat.csv'))
  # testthat::expect_snapshot_file(
  #   testthat::test_path('output', 'figures', 'model_wheat_fit_lnyield_mmm_quad_noco2_nogdp.pdf'))
})

test_that("yield_shock_projection runs correctly", {

  out_yield_projections <- run_yield_shock_projection()

  testthat::expect_snapshot(out_yield_projections)

  # testthat::expect_snapshot_file(
  #   testthat::test_path('output', 'yield_impacts_annual', 'yield_canesm5_gcam-ref_wheat.csv'))
  # testthat::expect_snapshot_file(
  #   testthat::test_path('output', 'yield_impacts_smooth', 'yield_canesm5_gcam-ref_wheat.csv'))
  # testthat::expect_snapshot_file(
  #   testthat::test_path('output', 'data_processed', 'format_yield_change_rel2015.csv'))
  # testthat::expect_snapshot_file(
  #   testthat::test_path('output', 'figures', 'annual_projected_climate_impacts_canesm5_gcam-ref_wheat_fit_lnyield_mmm_quad_noco2_nogdp.pdf'))
  # testthat::expect_snapshot_file(
  #   testthat::test_path('output', 'figures', 'smooth_projected_climate_impacts_canesm5_gcam-ref_wheat_fit_lnyield_mmm_quad_noco2_nogdp.pdf'))
  # testthat::expect_snapshot_file(
  #   testthat::test_path('output', 'maps', 'map_canesm5_gcam-ref_wheat_2090.pdf'))
})


test_that("gcam_agprodchange runs correctly", {

  out_yield_projections <- run_yield_shock_projection()
  out_gcam_agprodchange <- run_gcam_agprodchange(data = out_yield_projections)

  testthat::expect_snapshot(out_gcam_agprodchange)

  # testthat::expect_snapshot_file(
  #   testthat::test_path('output', 'gcam7_agprodchange_no-cfe', 'agyield_impact_canesm5_r1i1p1f1_w5e5v2_gcam-ref.xml'))
  # testthat::expect_snapshot_file(
  #   testthat::test_path('output', 'gcam7_agprodchange_no-cfe', 'figures_yield_impacts', 'Wheat.png'))
  # testthat::expect_snapshot_file(
  #   testthat::test_path('output', 'gcam7_agprodchange_no-cfe', 'figures_agprodchange', 'Wheat.png'))
})
