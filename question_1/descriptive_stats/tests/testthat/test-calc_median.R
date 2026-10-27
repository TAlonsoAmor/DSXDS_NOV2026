test_that("calc_median returns correct median for odd-length vector", {
  expect_equal(calc_median(c(1, 2, 3, 4, 5)), 3)
})

test_that("calc_median returns mean of two middle values for even-length vector", {
  expect_equal(calc_median(c(1, 2, 4, 5)), 3)
  expect_equal(calc_median(c(1, 2, 2, 3, 4, 5, 5, 5, 6, 10)), 4.5)
})

test_that("calc_median handles single value", {
  expect_equal(calc_median(42), 42)
})

test_that("calc_median returns NA when NAs present and na.rm = FALSE", {
  expect_true(is.na(calc_median(c(1, NA, 3))))
})

test_that("calc_median removes NAs when na.rm = TRUE", {
  expect_equal(calc_median(c(1, NA, 3), na.rm = TRUE), 2)
})

test_that("calc_median returns NA with warning for empty vector", {
  expect_warning(result <- calc_median(numeric(0)))
  expect_true(is.na(result))
})

test_that("calc_median errors on non-numeric input", {
  expect_error(calc_median(c("a", "b")))
})
