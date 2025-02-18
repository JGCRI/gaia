#' yield_regression
#'
#' Yield regressions and create figures
#' using average growing season temperature and precipitation, max and min months
#'
#' @param formula Default = NULL. String for regression formula
#' @param diagnostics Default = TRUE. Logical for performing diagnostic plot
#' @param output_dir Default = file.path(getwd(), 'output'). String for output directory
#' @returns No return value, called for the side effects of processing and writing output files
#' @export

yield_regression <- function(formula = NULL,
                             diagnostics = TRUE,
                             output_dir = file.path(getwd(), "output")) {
  # Decided not to use irrigation equipped land because data is so spotty
  # Tested with panel data regression, but can't use weighting in panel data
  # plm estimates are nearly identical to unweighted lm, FE estimates
  # Decided to use weighted (harvested area) FE and not use plm.

  if (is.null(formula)) {
    formula <- waldhoff_formula
  }

  message(paste0("Starting step: yield_regression"))
  message(paste0("Using formula: ", formula))

  # get the selected crops
  hist_var_files <- list.files(file.path(output_dir, "data_processed"), 'historic_vars')
  crop_select <- gsub('.csv', '', gsub('historic_vars_', '', hist_var_files))

  # conduct regression for each crop
  for (crop_i in crop_select) {
    # read in the historical crop data and weather data
    d_crop <- gaia::input_data(
      folder_path = file.path(output_dir, "data_processed"),
      input_file = paste("historic_vars_", crop_i, ".csv", sep = ""),
      skip_number = 0,
      quietly = TRUE
    )

    # prepare for regression analysis
    d_crop_reg <- gaia::prep_regression(d_crop)

    # regression analysis with fixed effects
    d_crop_reg_fe <- gaia::regression_fixed_effects(
      d = d_crop_reg,
      crop_name = crop_i,
      formula = formula,
      output_dir = output_dir
    )

    # plot
    if (diagnostics == TRUE) {
      gaia::plot_fit(
        data = d_crop_reg_fe,
        crop_name = crop_i,
        output_dir = output_dir
      )
    }
  }
}
