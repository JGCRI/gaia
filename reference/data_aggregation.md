# data_aggregation

This function calculates crop growing seasons using climate variables
processed by weighted_climate along with crop calendars for both
historical and projected periods. This function prepares climate and
yield data for subsequent model fitting.

## Usage

``` r
data_aggregation(
  climate_hist_dir = NULL,
  climate_impact_dir = NULL,
  climate_model = "gcm",
  climate_scenario = "rcp",
  historical_periods = NULL,
  crop_calendar_file = NULL,
  start_year = NULL,
  end_year = NULL,
  co2_hist = NULL,
  co2_proj = NULL,
  output_dir = file.path(getwd(), "output")
)
```

## Arguments

- climate_hist_dir:

  Default = NULL. String for path to the processed historical climate
  data folder

- climate_impact_dir:

  Default = NULL. String for path to the processed future climate data
  folder using weighted_climate function

- climate_model:

  Default = NULL. String for climate model (e.g., 'CanESM5')

- climate_scenario:

  Default = NULL. String for climate scenario (e.g., 'ssp245')

- historical_periods:

  Default = NULL. Vector for years to subset from the historical climate
  data. If NULL, use the default climate data period

- crop_calendar_file:

  Default = NULL. String for the path of the crop calendar file. If
  crop_calendar_file is provided, crop_select will be set to crops in
  crop calendar. User provided crop_calendar_file can include any crops
  MIRCA2000 crops: "wheat", "maize", "rice", "barley", "rye", "millet",
  "sorghum", "soybean", "sunflower", "root_tuber", "cassava",
  "sugarcane", "sugarbeet", "oil_palm", "rape_seed", "groundnuts",
  "pulses", "citrus", "date_palm", "grapes", "cotton", "cocoa",
  "coffee", "others_perennial", "fodder_grasses", "others_annual"

- start_year:

  Default = NULL. Integer for the start year of the projected data

- end_year:

  Default = NULL. Integer for the end year of the projected data

- co2_hist:

  Default = NULL. Data table for historical CO2 concentration in columns
  \[year, co2_conc\]. If NULL, use built-in CO2 emission data

- co2_proj:

  Default = NULL. Data table for projected CO2 concentration in columns
  \[year, co2_conc\]. If NULL, use built-in CO2 emission data

- output_dir:

  Default = file.path(getwd(), 'output'). String for output directory

## Value

A list of historical and projected weather variables and crop data.
