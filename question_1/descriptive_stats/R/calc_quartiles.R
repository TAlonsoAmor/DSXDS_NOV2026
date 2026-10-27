#' Calculate First Quartile (Q1)
#'
#' Returns the 25th percentile of a numeric vector using the same method as
#' base R's `stats::quantile()` (type 7).
#'
#' @param x A numeric vector.
#' @param na.rm Logical. Should `NA` values be removed before calculation?
#'   Defaults to `FALSE`.
#'
#' @return A single numeric value, or `NA` if `x` is empty or contains `NA`
#'   and `na.rm = FALSE`.
#'
#' @examples
#' calc_q1(c(1, 2, 3, 4, 5))           # 2
#' calc_q1(c(1, NA, 3), na.rm = TRUE)  # 1.5
#'
#' @export
calc_q1 <- function(x, na.rm = FALSE) {
  if (!validate_numeric(x)) return(NA_real_)
  if (!na.rm && anyNA(x)) return(NA_real_)
  unname(stats::quantile(x, probs = 0.25, na.rm = na.rm))
}

#' Calculate Third Quartile (Q3)
#'
#' Returns the 75th percentile of a numeric vector using the same method as
#' base R's `stats::quantile()` (type 7).
#'
#' @param x A numeric vector.
#' @param na.rm Logical. Should `NA` values be removed before calculation?
#'   Defaults to `FALSE`.
#'
#' @return A single numeric value, or `NA` if `x` is empty or contains `NA`
#'   and `na.rm = FALSE`.
#'
#' @examples
#' calc_q3(c(1, 2, 3, 4, 5))           # 4
#' calc_q3(c(1, NA, 3), na.rm = TRUE)  # 2.5
#'
#' @export
calc_q3 <- function(x, na.rm = FALSE) {
  if (!validate_numeric(x)) return(NA_real_)
  if (!na.rm && anyNA(x)) return(NA_real_)
  unname(stats::quantile(x, probs = 0.75, na.rm = na.rm))
}

#' Calculate Interquartile Range (IQR)
#'
#' Returns the interquartile range, defined as Q3 - Q1.
#'
#' @param x A numeric vector.
#' @param na.rm Logical. Should `NA` values be removed before calculation?
#'   Defaults to `FALSE`.
#'
#' @return A single numeric value, or `NA` if `x` is empty or contains `NA`
#'   and `na.rm = FALSE`.
#'
#' @examples
#' calc_iqr(c(1, 2, 3, 4, 5))           # 2
#' calc_iqr(c(1, NA, 3), na.rm = TRUE)  # 1
#'
#' @export
calc_iqr <- function(x, na.rm = FALSE) {
  calc_q3(x, na.rm = na.rm) - calc_q1(x, na.rm = na.rm)
}
