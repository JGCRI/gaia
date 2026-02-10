# yield_shock_projection

Projects yield shocks for future climate scenarios using the fitted
model and temperature, precipitation, and CO2 projections from the
climate scenario.

## Usage

``` r
yield_shock_projection(
  use_default_coeff = FALSE,
  climate_model = "gcm",
  climate_scenario = "rcp",
  base_year = 2015,
  start_year = NULL,
  end_year = NULL,
  gcam_timestep = 5,
  smooth_window = 20,
  diagnostics = TRUE,
  output_dir = file.path(getwd(), "output")
)
```

## Arguments

- use_default_coeff:

  Default = FALSE. Binary for using default regression coefficients. Set
  to TRUE will use the default coefficients instead of calculating
  coefficients from the historical climate data.

- climate_model:

  Default = NULL. String for climate model (e.g., 'CanESM5')

- climate_scenario:

  Default = NULL. String for climate scenario (e.g., 'ssp245')

- base_year:

  Default = 2015. Integer for the base year (for GCAM)

- start_year:

  Default = NULL. Integer for the start year of the data

- end_year:

  Default = NULL. Integer for the end year of the data

- gcam_timestep:

  Default = 5. Integer for the time step of GCAM (Select either 1 or 5
  years for GCAM use)

- smooth_window:

  Default = 20. Integer for smoothing window in years

- diagnostics:

  Default = TRUE. Logical for performing diagnostic plot

- output_dir:

  Default = file.path(getwd(), 'output'). String for output directory

## Value

A data frame of formatted smoothed annual crop yield shocks under
climate impacts
