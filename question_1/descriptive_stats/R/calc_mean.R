#' Calculate Arithmetic Mean
#'
#' Returns the arithmetic mean of a numeric vector.
#'
#' @param x A numeric vector.
#' @param na.rm Logical. Should `NA` values be removed before calculation?
#'   Defaults to `FALSE`, in which case any `NA` in `x` causes the result to
#'   be `NA`.
#'
#' @return A single numeric value, or `NA` if `x` is empty or contains `NA`
#'   and `na.rm = FALSE`.
#'
#' @examples
#' calc_mean(c(1, 2, 3, 4, 5))        # 3
#' calc_mean(c(1, NA, 3))             # NA
#' calc_mean(c(1, NA, 3), na.rm = TRUE) # 2
#'
#' @export
calc_mean <- function(x, na.rm = FALSE) {
  if (!validate_numeric(x)) return(NA_real_)
  mean(x, na.rm = na.rm)
}
