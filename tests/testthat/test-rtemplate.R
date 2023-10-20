library(rtemplate); library(testthat);

# Run tests for each function
test_that("example_function_sum runs correctly", {

  testthat::expect_equal(rtemplate::example_function_sum(1,3),4)

  })

