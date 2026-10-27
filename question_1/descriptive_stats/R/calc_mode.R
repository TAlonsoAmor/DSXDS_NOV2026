#' Calculate Mode
#'
#' Returns the most frequently occurring value(s) in a numeric vector.
#' If multiple values share the highest frequency (ties), all are returned.
#' If all values are unique (no repeated value), all values are returned with
#' a warning indicating there is no unique mode.
#'
#' @param x A numeric vector.
#' @param na.rm Logical. Should `NA` values be removed before calculation?
#'   Defaults to `FALSE`, in which case `NA` is treated as a value and may
#'   itself be returned as the mode.
#'
#' @return A numeric vector of the modal value(s), or `NA` if `x` is empty.
#'
#' @examples
#' calc_mode(c(1, 2, 2, 3))              # 2
#' calc_mode(c(1, 2, 2, 3, 3))          # c(2, 3)  — tied
#' calc_mode(c(1, 2, 3))                # c(1, 2, 3) with a warning
#' calc_mode(c(1, NA, 1))               # 1  (NA ignored due to tabulation)
#' calc_mode(c(1, NA, 1), na.rm = TRUE) # 1
#'
#' @export
calc_mode <- function(x, na.rm = FALSE) {
  if (!validate_numeric(x)) return(NA_real_)

  if (na.rm) {
    x <- x[!is.na(x)]
    if (length(x) == 0) {
      warning("`x` contains only NA values after removal; returning NA.")
      return(NA_real_)
    }
  }

  if (length(x) == 1L) return(x)

  freq_table <- table(x)
  max_freq   <- max(freq_table)

  if (max_freq == 1) {
    warning("No repeated values in `x`; every value occurs once. Returning all values.")
    return(sort(unique(x)))
  }

  as.numeric(names(freq_table[freq_table == max_freq]))
}
