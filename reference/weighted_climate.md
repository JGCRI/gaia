# weighted_climate

Processes CMIP6 daily or monthly climate NetCDF data formatted in
accordance with the ISIMIP simulation protocols (more details here) and
calculates cropland-weighted precipitation and temperature at the
country level, differentiated by crop type and irrigation type.

## Usage

``` r
weighted_climate(
  pr_ncdf = NULL,
  tas_ncdf = NULL,
  timestep = "monthly",
  climate_model = "gcm",
  climate_scenario = "rcp",
  time_periods = NULL,
  crop_names = NULL,
  output_dir = file.path(getwd(), "output"),
  name_append = NULL
)
```

## Arguments

- pr_ncdf:

  Default = NULL. List of paths for precipitation NetCDF files from
  ISIMIP

- tas_ncdf:

  Default = NULL. List of paths for temperature NetCDF files from ISIMIP

- timestep:

  Default = 'monthly'. String for input climate data time step (e.g.,
  'monthly', 'daily')

- climate_model:

  Default = NULL. String for climate model (e.g., 'CanESM5')

- climate_scenario:

  Default = NULL. String for climate scenario (e.g., 'ssp245')

- time_periods:

  Default = NULL. Vector for years to subset from the climate data. If
  NULL, use the default climate data period

- crop_names:

  Default = NULL. String vector for selected crops id names from
  MIRCA2000. If NULL, use all MIRCA 26 crops. Crop names should be
  strings like 'irc_crop01', 'rfc_crop01', ..., 'irc_crop26',
  'rfc_crop26'

- output_dir:

  Default = file.path(getwd(), 'output'). String for output directory

- name_append:

  Default = NULL. String for name append to the output folder

## Value

No return value, called for the side effects of processing and writing
output files. The output files include columns \`\[year, month, 1, 2, 3,
..., 265\]\`, where the numbers correspond to country IDs. To view the
country names associated with these IDs, simply type gaia::country_id in
the R console after loading the gaia package.
