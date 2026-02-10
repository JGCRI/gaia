# Changelog

## gaia 2.0.1

`gaia` is a powerful and user-friendly tool designed to estimate crop
yield responses to climate impacts, enabling robust projections and
streamlined workflows. Explore its full capabilities in the [User
Guide](https://jgcri.github.io/gaia/articles/vignette.html).

### Key Features of `gaia`:

#### General Features:

- **Empirical Econometric Modeling:** Estimate annual crop yield
  responses to climate impacts using an empirically grounded approach.
- **Streamlined Workflow:** Simplify your analysis with a single wrapper
  function, `yield_impact`, for running models efficiently.
- **Integrated Climate Data Processing:** Process widely-used
  ISIMIP-style climate NetCDF files without the need for external tools.
- **Data-Driven Insights:** Leverage historical weather, CO2, and crop
  yield data for robust model fitting.
- **Future Projections:** Project annual yield shocks for 17 crops using
  CMIP/ISIMIP bias-adjusted precipitation and temperature datasets.
  `gaia` supports both daily and monthly climate data formats.
- **Flexible Crop Coverage:** Estimate yield shocks for 17 major crops,
  with the option to add more crops by providing appropriate input data.
- **Model Supports:** Designed to support [Global Change Analysis Model
  (GCAM)](https://github.com/JGCRI/gcam-core) as well as other non-GCAM
  modeling frameworks.

#### GCAM-Specific Features:

- **Ready-to-Use Outputs:** Generate XML files for agricultural
  productivity changes at region-basin intersections, compatible with
  GCAM.
- **Version Compatibility:** Supports GCAM v6.x and v7.x.
- **Flexible Time Steps:** Offer options for both 5-year and annual time
  steps for GCAM.
- **Scenario Flexibility:** Choose from various Shared Socioeconomic
  Pathways (SSPs) in combination with climate scenarios (e.g., RCPs).
