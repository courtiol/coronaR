#' Welcome to coronaR
#'
#' The goal of this package is to make it easy to explore and plot mortality caused by COVID19.
#'
#' @name coronaR-package
#' @aliases coronaR-package coronaR
#' @docType package
#'
#' @keywords package
#' @examples
#' ## See the online README file for examples.
NULL

## enables to use .data$ in dplyr calls and thus not having to
## do var <- NULL ## to please R CMD check
## it also has the benefits of not working if a variable outside the
## data is being used.
#' @importFrom rlang .data
rlang::.data ## to avoid  "Namespace in Imports field not imported from: 'rlang'" during check

