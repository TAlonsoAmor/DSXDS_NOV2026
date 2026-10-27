# Validates that x is a non-empty numeric vector.
# Returns TRUE invisibly if valid; stops or warns otherwise.
validate_numeric <- function(x, arg_name = "x") {
  if (!is.numeric(x)) {
    stop(sprintf("`%s` must be a numeric vector, not %s.", arg_name, class(x)[[1]]))
  }
  if (length(x) == 0) {
    warning(sprintf("`%s` is an empty vector; returning NA.", arg_name))
    return(FALSE)
  }
  TRUE
}
