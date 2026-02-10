# input_data

read in data and output number of rows and columns and variable names

## Usage

``` r
input_data(
  folder_path = NULL,
  input_file = NULL,
  skip_number = 0,
  quietly = FALSE
)
```

## Arguments

- folder_path:

  Default = NULL. String for the folder path

- input_file:

  Default = NULL. String for the name of the csv file to be read in

- skip_number:

  Default = 0. Integer for the number of rows to skip

- quietly:

  Default= FALSE. Logical. TRUE to output input data information; FALSE
  to silent.

## Value

A data table of input CSV file
