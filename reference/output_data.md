# output_data

write output

## Usage

``` r
output_data(
  data = NULL,
  save_path = file.path(getwd(), "output"),
  file_name = NULL,
  is_figure = FALSE,
  data_info = "Data"
)
```

## Arguments

- data:

  Default = NULL. Data frame

- save_path:

  Default = NULL. String for path to the output folder

- file_name:

  Default = NULL. String for file name

- is_figure:

  Default = FALSE. Binary for saving figure

- data_info:

  Default = 'Data'. String for describing the data information

## Value

No return value, called for the side effects of writing output files
