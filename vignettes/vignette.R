## ----eval=FALSE---------------------------------------------------------------
#  
#  # load gaea
#  library(gaea)
#  
#  # NOTE: please change `data_dir` to your desired location for downloaded data
#  data_dir <- gaea::get_example_data(
#    download_url = 'https://zenodo.org/records/13179630/files/gaea_example_climate.zip?download=1',
#    data_dir = 'path/to/desired/location'
#  )
#  
#  # Path to the climate NetCDF files
#  # NOTE: Each variable can have more than one file
#  # historical climate data
#  pr_historical_file <- file.path(data_dir, 'pr_monthly_canesm5_w5e5_rcp7_1950_2014.nc')
#  tas_historical_file <- file.path(data_dir, 'tas_monthly_canesm5_w5e5_rcp7_1950_2014.nc')
#  
#  # projected climate data
#  pr_projection_file <- file.path(data_dir, 'pr_monthly_canesm5_w5e5_rcp7_2015_2100.nc')
#  tas_projection_file <- file.path(data_dir, 'tas_monthly_canesm5_w5e5_rcp7_2015_2100.nc')
#  
#  # Run gaea
#  # The full run with raw climate data can take up to an hour
#  gaea::yield_impact(
#    pr_hist_ncdf = pr_historical_file,
#    tas_hist_ncdf = tas_historical_file,
#    pr_proj_ncdf = pr_projection_file,
#    tas_proj_ncdf = tas_projection_file,
#    timestep = 'monthly',                   # specify the time step of the NetCDF data (monthly or daily)
#    historical_periods = c(1950:2014),      # vector of historical years selected for fitting
#    climate_model = 'canesm5',              # label of climate model name
#    climate_scenario = 'gcam-ref',          # label of climate scenario name
#    member = 'r1i1p1f1',                    # label of ensemble member name
#    bias_adj = 'w5e5',                      # label of climate data for bias adjustment
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
#    output_dir = 'path/to/output/folder'    # path to the output folder
#  )
#  

