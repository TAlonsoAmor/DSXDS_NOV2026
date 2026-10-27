test_that("calc_mean returns correct mean for normal vectors", {
  expect_equal(calc_mean(c(1, 2, 3, 4, 5)), 3)
  expect_equal(calc_mean(c(1, 2, 2, 3, 4, 5, 5, 5, 6, 10)), 4.3)
})

test_that("calc_mean handles single value", {
  expect_equal(calc_mean(42), 42)
})

test_that("calc_mean returns NA when NAs present and na.rm = FALSE", {
  expect_true(is.na(calc_mean(c(1, NA, 3))))
})

test_that("calc_mean removes NAs when na.rm = TRUE", {
  expect_equal(calc_mean(c(1, NA, 3), na.rm = TRUE), 2)
})

test_that("calc_mean returns NA with warning for empty vector", {
  expect_warning(result <- calc_mean(numeric(0)))
  expect_true(is.na(result))
})

test_that("calc_mean errors on non-numeric input", {
  expect_error(calc_mean(c("a", "b")))
})
