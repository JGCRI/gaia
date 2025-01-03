## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(warning = FALSE, message = FALSE) 

## ----eval=F-------------------------------------------------------------------
#  
#  # load gaia
#  library(gaia)
#  
#  # Path to the output folder. Change it to your desired location
#  output_dir <- file.path(getwd(), 'gaia_output')
#  
#  # Cropland-weighted historical and future climate data
#  data_dir <- gaia::get_example_data(
#    download_url = 'https://zenodo.org/records/13976521/files/weighted_climate.zip?download=1',
#    data_dir = output_dir
#  )
#  
#  # Path to the folder that holds cropland-area-weighted precipitation and temperature TXT files
#  # historical climate observation
#  climate_hist_dir <- file.path(data_dir, 'climate_hist')
#  # future projected climate
#  climate_impact_dir <- file.path(data_dir, 'canesm5')
#  

## ----eval=F-------------------------------------------------------------------
#  
#  # load gaia
#  library(gaia)
#  
#  # Path to the output folder. Change it to your desired location
#  output_dir <- file.path(getwd(), 'gaia_output')
#  
#  # Future Climate Data
#  data_dir <- gaia::get_example_data(
#    download_url = 'https://zenodo.org/records/13976521/files/gaia_example_climate.zip?download=1',
#    data_dir = output_dir
#  )
#  
#  # Path to the precipitation and temperature NetCDF files
#  # NOTE: Each variable can have more than one file
#  # projected climate data
#  pr_projection_file <- file.path(data_dir, 'pr_monthly_canesm5_w5e5_gcam-ref_2015_2100.nc')
#  tas_projection_file <- file.path(data_dir, 'tas_monthly_canesm5_w5e5_gcam-ref_2015_2100.nc')
#  

## ----eval=F, echo=T-----------------------------------------------------------
#  
#  # load gaia
#  library(gaia)
#  
#  # Path to the output folder. Change it to your desired location
#  output_dir <- file.path(getwd(), 'gaia_output')
#  
#  # Run gaia
#  # The full run with raw climate data can take up to an hour
#  gaia::yield_impact(
#    pr_hist_ncdf = NULL,                    # path to historical precipitation NetCDF file (must follow ISIMIP format); only if you wish to use your own historical precipitation observation
#    tas_hist_ncdf = NULL,                   # path to historical temperature NetCDF file (must follow ISIMIP format); only if you wish to use your own historical temperature observation
#    pr_proj_ncdf = pr_projection_file,      # path to future projected precipitation NetCDF file (must follow ISIMIP format)
#    tas_proj_ncdf = tas_projection_file,    # path to future projected temperature NetCDF file (must follow ISIMIP format)
#    timestep = 'monthly',                   # specify the time step of the NetCDF data (monthly or daily)
#    climate_hist_dir = climate_hist_dir,    # path to the folder that holds cropland weighted historical climate observations
#    historical_periods = c(1960:2001),      # vector of historical years selected for fitting
#    climate_model = 'canesm5',              # label of climate model name
#    climate_scenario = 'gcam-ref',          # label of climate scenario name
#    member = 'r1i1p1f1',                    # label of ensemble member name
#    bias_adj = 'w5e5',                      # label of climate data for bias adjustment for the global climate model (GCM)
#    cfe = 'no-cfe',                         # label of CO2 fertilization effect in the formula (default is no CFE)
#    gcam_version = 'gcam7',                 # output is different depending on the GCAM version (gcam6 or gcam7)
#    use_default_coeff = FALSE,              # set to TRUE when there is no historical climate data available
#    base_year = 2015                        # GCAM base year
#    start_year = 2015,                      # start year of the projected climate data
#    end_year = 2100,                        # end year of the projected climate data
#    smooth_window = 20,                     # number of years as smoothing window
#    co2_hist = NULL,                        # historical annual CO2 concentration. If NULL, will use default value
#    co2_proj = NULL,                        # projected annual CO2 concentration. If NULL, will use default value
#    diagnostics = TRUE,                     # set to TRUE to output diagnostic plots
#    output_dir = output_dir                 # path to the output folder
#  )
#  

## ----eval=F, echo=T-----------------------------------------------------------
#  
#  # load gaia
#  library(gaia)
#  
#  # Path to the output folder. Change it to your desired location
#  output_dir <- file.path(getwd(), 'gaia_output')
#  
#  # Run gaia
#  gaia::yield_impact(
#    climate_hist_dir = climate_hist_dir,    # path to the folder that holds cropland weighted historical climate observations
#    climate_impact_dir = climate_impact_dir,# path to the folder that holds cropland weighted projected climate
#    timestep = 'monthly',                   # specify the time step of the NetCDF data (monthly or daily)
#    climate_model = 'canesm5',              # label of climate model name
#    climate_scenario = 'gcam-ref',          # label of climate scenario name
#    member = 'r1i1p1f1',                    # label of ensemble member name
#    bias_adj = 'w5e5',                      # label of climate data for bias adjustment
#    cfe = 'no-cfe',                         # label of CO2 fertilization effect in the formula (default is no CFE)
#    gcam_version = 'gcam7',                 # output is different depending on the GCAM version (gcam6 or gcam7)
#    use_default_coeff = FALSE,              # set to TRUE when there is no historical climate data available
#    base_year = 2015,                       # GCAM base year
#    start_year = 2015,                      # start year of the projected climate data
#    end_year = 2100,                        # end year of the projected climate data
#    smooth_window = 20,                     # number of years as smoothing window
#    co2_hist = NULL,                        # historical annual CO2 concentration. If NULL, will use default value
#    co2_proj = NULL,                        # projected annual CO2 concentration. If NULL, will use default value
#    diagnostics = TRUE,                     # set to TRUE to output diagnostic plots
#    output_dir = output_dir                 # path to the output folder
#  )
#  

## ----eval=F, echo=T-----------------------------------------------------------
#  library(gaia)
#  
#  # Path to the output folder where you wish to save the outputs. Change it accordingly
#  output_dir <- file.path(getwd(), 'gaia_output')
#  
#  # calculate weigted climate
#  weighted_climate(pr_ncdf = pr_projection_file ,
#                   tas_ncdf = tas_projection_file ,
#                   timestep = 'monthly',
#                   climate_model = 'canesm5',
#                   climate_scenario = 'gcam-ref',
#                   time_periods = seq(2015, 2100, 1),
#                   output_dir = output_dir,
#                   name_append = NULL)
#  

## ----eval=T, echo=F, message=F, results='hide'--------------------------------

input_climate <- gaia::input_data(folder_path = file.path(getwd(), 'vignetteFigs'),
                                  input_file = 'canesm5_gcam-ref_month_precip_country_rfc_crop08_2015_2100.txt')


## ----eval=TRUE, echo=FALSE----------------------------------------------------
library(dplyr)
library(kableExtra)
knitr::kable(input_climate[1:12], 
             caption = '**Table 1.** Soybean-area-weighted precipitation from the weighted_climate function.') %>% 
  kable_styling(bootstrap_options = "striped", full_width = T, position = 'center') %>% 
  footnote(general = 'This only shows the first 12 lines of the example data. Value -9999 indicates there is no cropland area for such crop in the country.')

## ----eval=F, echo=T-----------------------------------------------------------
#  
#  # Path to the output folder where you wish to save the outputs. Change it accordingly
#  output_dir <- file.path(getwd(), 'gaia_output')
#  
#  # calculate crop calendars
#  crop_cal <- crop_calendars(output_dir = output_dir)
#  
#  # print result
#  crop_cal
#  

## ----eval=T, echo=F, message=F, results='hide'--------------------------------

crop_cal <- gaia::input_data(folder_path = file.path(getwd(), 'vignetteFigs'),
                              input_file = 'crop_calendar.csv')


## ----eval=T, echo=F-----------------------------------------------------------
library(dplyr)
library(kableExtra)
knitr::kable(crop_cal[1:10], 
             caption = '**Table 2.** Crop calendar') %>% 
  kable_styling(bootstrap_options = "striped", full_width = T, position = 'center') %>% 
  footnote(general = 'This only shows the first 10 lines of the example data.')

## ----eval=F, echo=T-----------------------------------------------------------
#  
#  # Path to the output folder where you wish to save the outputs. Change it accordingly
#  output_dir <- file.path(getwd(), 'gaia_output')
#  
#  # aggregate crop and climate information at the country level
#  data_agg <- data_aggregation(climate_hist_dir = climate_hist_dir,
#                               climate_impact_dir = climate_impact_dir,
#                               climate_model = 'canesm5',
#                               climate_scenario = 'gcam-ref',
#                               output_dir = output_dir)
#  

## ----eval=T, echo=F, message=F, results='hide'--------------------------------

crop_projection <- gaia::input_data(folder_path = file.path(getwd(), 'vignetteFigs'),
                                    input_file = 'weather_canesm5_gcam-ref_soybean.csv')

crop_hist <- gaia::input_data(folder_path = file.path(getwd(), 'vignetteFigs'),
                              input_file = 'historic_vars_soybean.csv')


## ----eval=T, echo=F-----------------------------------------------------------
library(dplyr)
library(kableExtra)

knitr::kable(crop_hist[1:10], 
             caption = '**Table 3.** Aggregated historical information for soybean.') %>% 
  kable_styling(bootstrap_options = "striped", full_width = T, position = 'center') %>% 
  footnote(general = 'This only shows the first 10 lines of the example data.')


knitr::kable(crop_projection[1:10], 
             caption = '**Table 4.** Aggregated weather information for soybean.') %>% 
  kable_styling(bootstrap_options = "striped", full_width = T, position = 'center') %>% 
  footnote(general = 'This only shows the first 10 lines of the example data.')


## ----eval=F, echo=T-----------------------------------------------------------
#  
#  # Path to the output folder where you wish to save the outputs. Change it accordingly
#  output_dir <- file.path(getwd(), 'gaia_output')
#  
#  # perform empirical regression
#  yield_regression(diagnostics = TRUE,
#                   output_dir = output_dir)
#  

## ----eval=T, echo=F, message=F, results='hide'--------------------------------

fit_model <- gaia::input_data(folder_path = file.path(getwd(), 'vignetteFigs'),
                              input_file = 'reg_out_soybean_fit_lnyield_mmm_quad_noco2_nogdp.csv')


## ----eval=T, echo=F-----------------------------------------------------------
library(dplyr)
library(kableExtra)
knitr::kable(fit_model[1:10], 
             caption = '**Table 5.** Fitted model for soybean.') %>% 
  kable_styling(bootstrap_options = "striped", full_width = T, position = 'center') %>% 
  footnote(general = 'This only shows the first 10 lines of the example data.')

## ----eval=F, echo=T-----------------------------------------------------------
#  
#  # Path to the output folder where you wish to save the outputs. Change it accordingly
#  output_dir <- file.path(getwd(), 'gaia_output')
#  
#  # calculate projected yield shocks
#  out_yield_shock <- yield_shock_projection(use_default_coeff = FALSE,
#                                            climate_model = 'canesm5',
#                                            climate_scenario = 'gcam-ref',
#                                            base_year = 2015,
#                                            start_year = 2015,
#                                            end_year = 2100,
#                                            smooth_window = 20,
#                                            diagnostics = TRUE,
#                                            output_dir = output_dir)
#  

## ----eval=T, echo=F, message=F, results='hide'--------------------------------

annual_yield <- gaia::input_data(folder_path = file.path(getwd(), 'vignetteFigs'),
                                 input_file = 'annual_yield_canesm5_gcam-ref_soybean.csv')

smooth_yield <- gaia::input_data(folder_path = file.path(getwd(), 'vignetteFigs'),
                                 input_file = 'smoothed_yield_canesm5_gcam-ref_soybean.csv')


## ----eval=T, echo=F-----------------------------------------------------------
library(dplyr)
library(kableExtra)

knitr::kable(annual_yield[1:10], 
             caption = '**Table 6.** Annual yield shocks for soybean.') %>% 
  kable_styling(bootstrap_options = "striped", full_width = T, position = 'center') %>% 
  footnote(general = 'This only shows the first 10 lines of the example data.')


knitr::kable(smooth_yield[1:10], 
             caption = '**Table 7.** 20-year smoothed yield shocks for soybean.') %>% 
  kable_styling(bootstrap_options = "striped", full_width = T, position = 'center') %>% 
  footnote(general = 'This only shows the first 10 lines of the example data.')


## ----eval=F, echo=T-----------------------------------------------------------
#  
#  # Path to the output folder where you wish to save the outputs. Change it accordingly
#  output_dir <- file.path(getwd(), 'gaia_output')
#  
#  # calculate region-basin agricultural productivity growth rate for GCAM
#  gcam_apg <- gcam_agprodchange(data = out_yield_shock,
#                                climate_model = 'canesm5',
#                                climate_scenario = 'gcam-ref',
#                                member = 'r1i1p1f1',
#                                bias_adj = 'w5e5',
#                                cfe = 'no-cfe',
#                                gcam_version = 'gcam7',
#                                diagnostics = TRUE,
#                                output_dir = output_dir)
#  

