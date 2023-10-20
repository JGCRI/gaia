#' example_function_sum
#'
#' Function that sums two numbers
#'
#' @param a Default = NULL
#' @param b Default = NULL
#' @keywords sum
#' @return number
#' @export
#' @examples
#' \dontrun{
#' library(rtemplate)
#' rtemplate(1,1)
#' }

example_function_sum <- function(a= NULL,
                                 b= NULL) {



  #.........................
  # Initialize
  #.........................

  rlang::inform("Starting example_function_sum...")

  #.........................
  # Run Function
  #.........................

  output = a + b;

  #.........................
  # Close out
  #.........................

  rlang::inform("example_function_sum complete.")

  return(output)

}
