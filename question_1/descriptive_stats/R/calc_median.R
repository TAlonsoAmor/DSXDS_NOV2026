#' Calculate Median
#'
#' Returns the median of a numeric vector.
#'
#' @param x A numeric vector.
#' @param na.rm Logical. Should `NA` values be removed before calculation?
#'   Defaults to `FALSE`.
#'
#' @return A single numeric value, or `NA` if `x` is empty or contains `NA`
#'   and `na.rm = FALSE`.
#'
#' @examples
#' calc_median(c(1, 2, 3, 4, 5))          # 3
#' calc_median(c(1, 2, 4, 5))             # 3
#' calc_median(c(1, NA, 3))               # NA
#' calc_median(c(1, NA, 3), na.rm = TRUE) # 2
#'
#' @export
calc_median <- function(x, na.rm = FALSE) {
  if (!validate_numeric(x)) return(NA_real_)
  stats::median(x, na.rm = na.rm)
}
