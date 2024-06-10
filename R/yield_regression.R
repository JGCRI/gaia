#' yield_regression
#'
#' Yield regressions and create figures
#' using average growing season temperature and precipitation, max and min months
#'
#' @param formula string for regression formula
#' @param diagnostics Default = TRUE. Logical for performing diagnostic plot
#' @param output_dir Default = file.path(getwd(), 'output'). String for output directory
#' @export

yield_regression <- function(formula = NULL,
                             diagnostics = TRUE,
                             output_dir = file.path(getwd(), 'output')){

  # Decided not to use irrigation equipped land because data is so spotty
  # Tested with panel data regression, but can't use weighting in panel data
  # plm estimates are nearly identical to unweighted lm, FE estimates
  # Decided to use weighted (harvested area) FE and not use plm.

  if(is.null(formula)) {
    formula <- waldhoff_formula
  }

  message(paste0('Starting step: yield_regression'))
  message(paste0('Using formula: ', formula))

  # conduct regression for each crop
  for(crop_i in mapping_mirca_sage$crop_mirca){

    # read in the historical crop data and weather data
    d_crop <- gaea::input_data(folder_path = file.path(output_dir, "data_processed"),
                               input_file = paste("historic_vars_", crop_i, ".csv", sep = ""),
                               skip_number = 0,
                               quietly = TRUE)

    # prepare for regression analysis
    d_crop_reg <- gaea::prep_regression(d_crop)

    # regression analysis with fixed effects
    d_crop_reg_fe <- gaea::regression_fixed_effects(d = d_crop_reg,
                                                    crop_name = crop_i,
                                                    formula = formula)

    # plot
    if(diagnostics == TRUE){
      gaea::plot_fit(d_crop_reg_fe, crop_name = crop_i)
    }


  }



}
