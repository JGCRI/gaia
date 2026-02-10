# gcam_agprodchange

Remaps country-level yield shocks to GCAM-required spatial scales (e.g.,
region, basin, and intersections), based on harvested areas, and
aggregates crops to GCAM commodities. This function applies the
projected shocks to GCAM scenario agricultural productivity growth rates
(the unit used to project future yields in GCAM) and creates
ready-to-use XML outputs for GCAM.

## Usage

``` r
gcam_agprodchange(
  data = NULL,
  gcamdata_dir = NULL,
  climate_model = "gcm",
  climate_scenario = "rcp",
  member = "member",
  bias_adj = "ba",
  gcam_version = "gcam7",
  gcam_timestep = 5,
  cfe = "no-cfe",
  base_year = 2015,
  diagnostics = TRUE,
  output_dir = file.path(getwd(), "output")
)
```

## Arguments

- data:

  Default = NULL. Output data frame from function
  yield_shock_projection, or similar format of data

- gcamdata_dir:

  Default = NULL. String for directory to the gcamdata folder within the
  specific GCAM version. The gcamdata need to be run with drake to have
  the CSV outputs beforehand.

- climate_model:

  Default = 'gcm'. String for climate model name (e.g., 'CanESM5')

- climate_scenario:

  Default = 'rcp'. String for climate scenario name (e.g., 'ssp245')

- member:

  Default = 'member'. String for the ensemble member name

- bias_adj:

  Default = 'ba'. String for the dataset used for climate data bias
  adjustment

- gcam_version:

  Default = 'gcam7'. String for the GCAM version. Only support gcam6 and
  gcam7

- gcam_timestep:

  Default = 5. Integer for the time step of GCAM (Select either 1 or 5
  years for GCAM use)

- cfe:

  Default = 'no-cfe'. String for whether the yield impact formula
  implimented CO2 fertilization effect.

- base_year:

  Default = 2015. Integer for the base year (for GCAM)

- diagnostics:

  Default = TRUE. Logical for performing diagnostic plot

- output_dir:

  Default = file.path(getwd(), 'output'). String for output directory

## Value

A data frame of formatted agricultural productivity change for GCAM
