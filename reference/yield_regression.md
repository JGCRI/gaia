# yield_regression

Performs regression analysis fitted with historical annual crop yields,
growing season monthly temperature and precipitation, CO2
concentrations, and GDP per capita. The default econometric model
applied in gaia is from [Waldhoff et al.,
(2020)](https://www.doi.org/10.1088/1748-9326/abadcb). User can specify
alternative formulas that are consistent with the data processed in
\`data_aggregation\`.

## Usage

``` r
yield_regression(
  formula = NULL,
  diagnostics = TRUE,
  output_dir = file.path(getwd(), "output")
)
```

## Arguments

- formula:

  Default = NULL. String for regression formula

- diagnostics:

  Default = TRUE. Logical for performing diagnostic plot

- output_dir:

  Default = file.path(getwd(), 'output'). String for output directory

## Value

No return value, called for the side effects of processing and writing
output files
