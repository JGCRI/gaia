# yield_impact

The wrapper function that runs the entire workflow from climate data
processing to yield shock estimation to agricultural productivity change
calculation for the Global Change Analysis Model (GCAM).

## Usage

``` r
yield_impact(
  pr_hist_ncdf = NULL,
  pr_proj_ncdf = NULL,
  tas_hist_ncdf = NULL,
  tas_proj_ncdf = NULL,
  timestep = "monthly",
  historical_periods = NULL,
  climate_hist_dir = NULL,
  climate_impact_dir = NULL,
  climate_model = "gcm",
  climate_scenario = "rcp",
  member = "member",
  bias_adj = "ba",
  cfe = "no-cfe",
  gcam_version = "gcam7",
  gcam_timestep = 5,
  gcamdata_dir = NULL,
  crop_calendar_file = NULL,
  crop_select = NULL,
  use_default_coeff = FALSE,
  base_year = 2015,
  start_year = NULL,
  end_year = NULL,
  smooth_window = 20,
  co2_hist = NULL,
  co2_proj = NULL,
  diagnostics = TRUE,
  output_dir = file.path(getwd(), "output")
)
```

## Arguments

- pr_hist_ncdf:

  Default = NULL. List of paths for historical precipitation NetCDF
  files from ISIMIP

- pr_proj_ncdf:

  Default = NULL. List of paths for projected precipitation NetCDF files
  from ISIMIP

- tas_hist_ncdf:

  Default = NULL. List of paths for historical temperature NetCDF files
  from ISIMIP

- tas_proj_ncdf:

  Default = NULL. List of paths for projected temperature NetCDF files
  from ISIMIP

- timestep:

  Default = 'monthly'. String for input climate data time step (e.g.,
  'monthly', 'daily')

- historical_periods:

  Default = NULL. Vector for years to subset from the historical climate
  data. If NULL, use the default climate data period

- climate_hist_dir:

  Default = NULL. String for path to the historical precipitation and
  temperature files by irrigation type and crop type. The climate files
  must follow the same structure as the output of the weighted_climate
  function. Provide path to this argument when pr_hist_ncdf and
  tas_hist_ncdf are NULL.

- climate_impact_dir:

  Default = NULL. String for path to the projected precipitation and
  temperature files by irrigation type and crop type. The climate files
  must follow the same structure as the output of the weighted_climate
  function. Provide path to this argument when pr_proj_ncdf and
  tas_proj_ncdf are NULL.

- climate_model:

  Default = 'gcm'. String for climate model name (e.g., 'CanESM5')

- climate_scenario:

  Default = 'rcp'. String for climate scenario name (e.g., 'ssp245')

- member:

  Default = 'member'. String for the ensemble member name

- bias_adj:

  Default = 'ba'. String for the dataset used for climate data bias
  adjustment

- cfe:

  Default = 'no-cfe'. String for whether the yield impact formula
  implemented CO2 fertilization effect

- gcam_version:

  Default = 'gcam7'. String for the GCAM version. Only support gcam6 and
  gcam7

- gcam_timestep:

  Default = 5. Integer for the time step of GCAM (Select either 1 or 5
  years for GCAM use)

- gcamdata_dir:

  Default = NULL. String for directory to the gcamdata folder within the
  specific GCAM version. The gcamdata need to be run with drake to have
  the CSV outputs beforehand.

- crop_calendar_file:

  Default = NULL. String for the path of the crop calendar file. If
  crop_calendar_file is provided, crop_select will be set to crops in
  crop calendar. User provided crop_calendar_file can include any crops
  MIRCA2000 crops: "wheat", "maize", "rice", "barley", "rye", "millet",
  "sorghum", "soybean", "sunflower", "root_tuber", "cassava",
  "sugarcane", "sugarbeet", "oil_palm", "rape_seed", "groundnuts",
  "pulses", "citrus", "date_palm", "grapes", "cotton", "cocoa",
  "coffee", "others_perennial", "fodder_grasses", "other_annual"

- crop_select:

  Default = NULL. Vector of strings for the selected crops from our
  database. If NULL, the default crops will be used in the crop
  calendar: c("cassava", "cotton", "maize", "rice", "root_tuber",
  "sorghum", "soybean", "sugarbeet", "sugarcane", "sunflower", "wheat").
  The additional crops available for selection from our crop calendar
  database are: "barley", "groundnuts", "millet", "pulses", "rape_seed",
  "rye"

- use_default_coeff:

  Default = FALSE. Binary for using default regression coefficients. Set
  to TRUE will use the default coefficients instead of calculating
  coefficients from the historical climate data.

- base_year:

  Default = 2015. Integer for the base year (for GCAM)

- start_year:

  Default = NULL. Integer for the start year of the projected data

- end_year:

  Default = NULL. Integer for the end year of the projected data

- smooth_window:

  Default = 20. Integer for smoothing window in years

- co2_hist:

  Default = NULL. Data table for historical CO2 concentration in columns
  \[year, co2_conc\]. If NULL, use built-in CO2 emission data

- co2_proj:

  Default = NULL. Data table for projected CO2 concentration in columns
  \[year, co2_conc\]. If NULL, use built-in CO2 emission data

- diagnostics:

  Default = TRUE. Logical for performing diagnostic plot

- output_dir:

  Default = file.path(getwd(), 'output'). String for output directory

## Value

A data frame of formatted agricultural productivity change for GCAM
