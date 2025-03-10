## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(warning = FALSE, message = FALSE) 

## ----eval=F-------------------------------------------------------------------
#  data_dir <- 'path/to/downloaded/folder'

## ----eval=F-------------------------------------------------------------------
#  
#  # load gaia
#  library(gaia)
#  
#  # Path to the output folder. Change it to your desired location
#  output_dir <- 'gaia_output'
#  
#  # Cropland-weighted historical and future climate data
#  data_dir <- gaia::get_example_data(
#    download_url = 'https://zenodo.org/records/14888816/files/weighted_climate.zip?download=1',
#    data_dir = output_dir
#  )

## ----eval=F-------------------------------------------------------------------
#  # Path to the folder that holds cropland-area-weighted precipitation and temperature TXT files
#  # historical climate observation
#  climate_hist_dir <- file.path(data_dir, 'climate_hist')
#  # future projected climate
#  climate_impact_dir <- file.path(data_dir, 'canesm5')
#  

## ----eval=F-------------------------------------------------------------------
#  data_dir <- 'path/to/downloaded/folder'

## ----eval=F-------------------------------------------------------------------
#  
#  # load gaia
#  library(gaia)
#  
#  # Path to the output folder. Change it to your desired location
#  output_dir <- 'gaia_output'
#  
#  # Future Climate Data
#  data_dir <- gaia::get_example_data(
#    download_url = 'https://zenodo.org/records/14888816/files/gaia_example_climate.zip?download=1',
#    data_dir = output_dir
#  )
#  

## ----eval=F-------------------------------------------------------------------
#  # Path to the precipitation and temperature NetCDF files
#  # NOTE: Each variable can have more than one file
#  # projected climate data
#  pr_projection_file <- file.path(data_dir, 'pr_monthly_canesm5_w5e5_ssp245_2015_2030.nc')
#  tas_projection_file <- file.path(data_dir, 'tas_monthly_canesm5_w5e5_ssp245_2015_2030.nc')
#  

## ----eval=F, echo=T-----------------------------------------------------------
#  
#  # load gaia
#  library(gaia)
#  
#  # Path to the output folder. Change it to your desired location
#  output_dir <- 'gaia_output'
#  
#  # Run gaia
#  # The full run with raw future climate data can take up to an hour
#  gaia::yield_impact(
#    pr_hist_ncdf = NULL,                    # path to historical precipitation NetCDF file (must follow ISIMIP format); only if you wish to use your own historical precipitation observation
#    tas_hist_ncdf = NULL,                   # path to historical temperature NetCDF file (must follow ISIMIP format); only if you wish to use your own historical temperature observation
#    pr_proj_ncdf = pr_projection_file,      # path to future projected precipitation NetCDF file (must follow ISIMIP format)
#    tas_proj_ncdf = tas_projection_file,    # path to future projected temperature NetCDF file (must follow ISIMIP format)
#    timestep = 'monthly',                   # specify the time step of the NetCDF data (monthly or daily)
#    climate_hist_dir = climate_hist_dir,    # path to the folder that holds cropland weighted historical climate observations
#    historical_periods = c(1960:2001),      # vector of historical years selected for fitting
#    climate_model = 'canesm5',              # label of climate model name
#    climate_scenario = 'ssp245',            # label of climate scenario name
#    member = 'r1i1p1f1',                    # label of ensemble member name
#    bias_adj = 'w5e5',                      # label of climate data for bias adjustment for the global climate model (GCM)
#    cfe = 'no-cfe',                         # label of CO2 fertilization effect in the formula (default is no CFE)
#    gcam_version = 'gcam7',                 # output is different depending on the GCAM version (gcam6 or gcam7)
#    use_default_coeff = FALSE,              # set to TRUE when there is no historical climate data available
#    base_year = 2015,                       # GCAM base year
#    start_year = 2015,                      # start year of the projected climate data
#    end_year = 2030,                        # end year of the projected climate data
#    smooth_window = 20,                     # number of years as smoothing window
#    co2_hist = NULL,                        # historical annual CO2 concentration. If NULL, will use default value
#    co2_proj = NULL,                        # projected annual CO2 concentration. If NULL, will use default value
#    crop_select = NULL,                     # set to NULL for the default crops
#    diagnostics = TRUE,                     # set to TRUE to output diagnostic plots
#    output_dir = output_dir                 # path to the output folder
#  )
#  

## ----eval=F, echo=F-----------------------------------------------------------
#  crop_mirca$crop_name[!is.na(crop_mirca$crop_sage)]

## ----eval=F, echo=T-----------------------------------------------------------
#  
#  # load gaia
#  library(gaia)
#  
#  # Path to the output folder. Change it to your desired location
#  output_dir <- 'gaia_output'
#  
#  # Run gaia
#  gaia::yield_impact(
#    climate_hist_dir = climate_hist_dir,    # path to the folder that holds cropland weighted historical climate observations
#    climate_impact_dir = climate_impact_dir,# path to the folder that holds cropland weighted projected climate
#    timestep = 'monthly',                   # specify the time step of the NetCDF data (monthly or daily)
#    climate_model = 'canesm5',              # label of climate model name
#    climate_scenario = 'ssp245',            # label of climate scenario name
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
#    crop_select = NULL,                     # set to NULL for the default crops
#    diagnostics = TRUE,                     # set to TRUE to output diagnostic plots
#    output_dir = output_dir                 # path to the output folder
#  )
#  

## ----eval=F, echo=T-----------------------------------------------------------
#  library(gaia)
#  
#  # Path to the output folder where you wish to save the outputs. Change it accordingly
#  output_dir <- 'gaia_output'
#  
#  # calculate weigted climate
#  weighted_climate(pr_ncdf = pr_projection_file ,
#                   tas_ncdf = tas_projection_file ,
#                   timestep = 'monthly',
#                   climate_model = 'canesm5',
#                   climate_scenario = 'ssp245',
#                   time_periods = seq(2015, 2030, 1),
#                   output_dir = output_dir,
#                   name_append = NULL)
#  

## ----eval=T, echo=F, message=F, results='hide'--------------------------------

input_climate <- gaia::input_data(folder_path = file.path(getwd(), 'vignetteFigs'),
                                  input_file = 'canesm5_ssp245_month_precip_country_rfc_crop08_2015_2100.txt')


## ----eval=TRUE, echo=FALSE----------------------------------------------------
library(tibble)
library(kableExtra)
knitr::kable(input_climate[1:12], 
             caption = '**Table 1.** Soybean-area-weighted precipitation from the weighted_climate function.') %>% 
  kable_styling(bootstrap_options = "striped", full_width = T, position = 'center') %>% 
  footnote(general = 'This only shows the first 12 lines of the example data. Value -9999 indicates there is no cropland area for such crop in the country.')

## ----eval=F, echo=T-----------------------------------------------------------
#  
#  # Path to the output folder where you wish to save the outputs. Change it accordingly
#  output_dir <- 'gaia_output'
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
#  # calculate crop calendars
#  crop_cal <- crop_calendars(crop_select = c("barley", "millet"),
#                             output_dir = output_dir)
#  
#  # print result
#  crop_cal
#  

## ----eval=T, echo=T, message=F, results='hide'--------------------------------

# adding a new crop: oil_palm. The crop name should follow the crop names listed above.
# Construct the structure of the data with oil_palm
crop_add <- expand.grid(iso = c('cog', 'gha', 'lbr'),
                        crops = c(names(crop_cal)[2:(ncol(crop_cal) - 2)], 'oil_palm')) %>%
  dplyr::mutate(value = ifelse(crops == 'oil_palm', 1, 0)) %>% 
  tidyr::pivot_wider(names_from = 'crops', values_from = 'value', values_fill = 0)

# planting and harvesting month for countries with oil_palm
crop_harvest_plant <- data.frame(iso = c('cog', 'gha', 'lbr'),
                                 plant = c(2, 2, 2),
                                 harvest  = c(9, 10, 9))

# complete the data structure with oil_palm added
crop_add <- dplyr::left_join(crop_add, crop_harvest_plant, by = 'iso')

# bind the data to create updated crop calendars
crop_cal_update <- crop_cal %>% 
  dplyr::bind_rows(crop_add) %>% 
  tidyr::replace_na(list(oil_palm = 0)) %>% 
  dplyr::select(-plant, -harvest, everything(), plant, harvest)

# view updated crop calendar
crop_cal_update


## ----eval=T, echo=F-----------------------------------------------------------
library(dplyr)
library(kableExtra)
knitr::kable(crop_cal_update[1:10], 
             caption = '**Table 3.** Updated crop calendar with oil palm') %>% 
  kable_styling(bootstrap_options = "striped", full_width = T, position = 'center') %>% 
  footnote(general = 'This only shows the first 10 lines of the example data.')

## ----eval=F, echo=T-----------------------------------------------------------
#  # Optional: save the update crop calendar to CSV if you haven't already
#  # you can choose to use gaia's output_data function to write output
#  gaia::output_data(
#    data = crop_cal_update,
#    file_name = 'crop_calendar_update.csv',
#    save_path = 'path/to/desired/folder'
#  )
#  

## ----eval=F, echo=T-----------------------------------------------------------
#  
#  # Path to the output folder where you wish to save the outputs. Change it accordingly
#  output_dir <- 'gaia_output'
#  
#  # crop calendars
#  crop_cal <- crop_calendars(crop_calendar_file = 'path/to/your/crop/calendar/file',
#                             output_dir = output_dir)
#  

## ----eval=F, echo=T-----------------------------------------------------------
#  
#  # Path to the output folder where you wish to save the outputs. Change it accordingly
#  output_dir <- 'gaia_output'
#  
#  # aggregate crop and climate information at the country level
#  data_agg <- data_aggregation(climate_hist_dir = climate_hist_dir,
#                               climate_impact_dir = climate_impact_dir,
#                               climate_model = 'canesm5',
#                               climate_scenario = 'ssp245',
#                               output_dir = output_dir)
#  

## ----eval=T, echo=F, message=F, results='hide'--------------------------------

crop_projection <- gaia::input_data(folder_path = file.path(getwd(), 'vignetteFigs'),
                                    input_file = 'weather_canesm5_ssp245_soybean.csv')

crop_hist <- gaia::input_data(folder_path = file.path(getwd(), 'vignetteFigs'),
                              input_file = 'historic_vars_soybean.csv')


## ----eval=T, echo=F-----------------------------------------------------------
library(dplyr)
library(kableExtra)

knitr::kable(crop_hist[1:10], 
             caption = '**Table 4.** Aggregated historical information for soybean.') %>% 
  kable_styling(bootstrap_options = "striped", full_width = T, position = 'center') %>% 
  footnote(general = 'This only shows the first 10 lines of the example data.')

## ----eval=T, echo=F-----------------------------------------------------------
library(dplyr)
library(kableExtra)

knitr::kable(crop_projection[1:10], 
             caption = '**Table 5.** Aggregated future weather information for soybean.') %>% 
  kable_styling(bootstrap_options = "striped", full_width = T, position = 'center') %>% 
  footnote(general = 'This only shows the first 10 lines of the example data.')

## ----eval=F, echo=T-----------------------------------------------------------
#  
#  # Path to the output folder where you wish to save the outputs. Change it accordingly
#  output_dir <- 'gaia_output'
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
             caption = '**Table 6.** Fitted model for soybean.') %>% 
  kable_styling(bootstrap_options = "striped", full_width = T, position = 'center') %>% 
  footnote(general = 'This only shows the first 10 lines of the example data.')

## ----eval=F, echo=T-----------------------------------------------------------
#  
#  # Path to the output folder where you wish to save the outputs. Change it accordingly
#  output_dir <- 'gaia_output'
#  
#  # calculate projected yield shocks
#  out_yield_shock <- yield_shock_projection(use_default_coeff = FALSE,
#                                            climate_model = 'canesm5',
#                                            climate_scenario = 'ssp245',
#                                            base_year = 2015,
#                                            start_year = 2015,
#                                            end_year = 2100,
#                                            smooth_window = 20,
#                                            diagnostics = TRUE,
#                                            output_dir = output_dir)
#  

## ----eval=T, echo=F, message=F, results='hide'--------------------------------

annual_yield <- gaia::input_data(folder_path = file.path(getwd(), 'vignetteFigs'),
                                 input_file = 'annual_yield_canesm5_ssp245_soybean.csv')

smooth_yield <- gaia::input_data(folder_path = file.path(getwd(), 'vignetteFigs'),
                                 input_file = 'smoothed_yield_canesm5_ssp245_soybean.csv')


## ----eval=T, echo=F-----------------------------------------------------------
library(dplyr)
library(kableExtra)

knitr::kable(annual_yield[1:10], 
             caption = '**Table 7.** Annual yield shocks for soybean.') %>% 
  kable_styling(bootstrap_options = "striped", full_width = T, position = 'center') %>% 
  footnote(general = 'This only shows the first 10 lines of the example data.')


## ----eval=T, echo=F-----------------------------------------------------------
library(dplyr)
library(kableExtra)

knitr::kable(smooth_yield[1:10], 
             caption = '**Table 8.** 20-year smoothed yield shocks for soybean.') %>% 
  kable_styling(bootstrap_options = "striped", full_width = T, position = 'center') %>% 
  footnote(general = 'This only shows the first 10 lines of the example data.')


## ----eval=F, echo=T-----------------------------------------------------------
#  
#  # Path to the output folder where you wish to save the outputs. Change it accordingly
#  output_dir <- 'gaia_output'
#  
#  # calculate region-basin agricultural productivity growth rate for GCAM
#  gcam_apg <- gcam_agprodchange(data = out_yield_shock,
#                                climate_model = 'canesm5',
#                                climate_scenario = 'ssp245',
#                                member = 'r1i1p1f1',
#                                bias_adj = 'w5e5',
#                                cfe = 'no-cfe',
#                                gcam_version = 'gcam7',
#                                diagnostics = TRUE,
#                                output_dir = output_dir)
#  

