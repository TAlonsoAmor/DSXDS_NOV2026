test_that("calc_mode returns single mode", {
  expect_equal(calc_mode(c(1, 2, 2, 3, 4, 5, 5, 5, 6, 10)), 5)
  expect_equal(calc_mode(c(1, 2, 2, 3)), 2)
})

test_that("calc_mode returns all tied values when tie", {
  result <- calc_mode(c(1, 1, 2, 2, 3))
  expect_equal(sort(result), c(1, 2))
})

test_that("calc_mode returns all values with warning when no repeated value", {
  expect_warning(result <- calc_mode(c(1, 2, 3)))
  expect_equal(sort(result), c(1, 2, 3))
})

test_that("calc_mode handles single value", {
  expect_equal(calc_mode(42), 42)
})

test_that("calc_mode returns NA with warning for empty vector", {
  expect_warning(result <- calc_mode(numeric(0)))
  expect_true(is.na(result))
})

test_that("calc_mode with na.rm = TRUE ignores NAs", {
  expect_equal(calc_mode(c(1, NA, 1, 2), na.rm = TRUE), 1)
})

test_that("calc_mode with na.rm = TRUE and all-NA returns NA with warning", {
  expect_warning(result <- calc_mode(c(NA_real_, NA_real_), na.rm = TRUE))
  expect_true(is.na(result))
})

test_that("calc_mode errors on non-numeric input", {
  expect_error(calc_mode(c("a", "b")))
})
