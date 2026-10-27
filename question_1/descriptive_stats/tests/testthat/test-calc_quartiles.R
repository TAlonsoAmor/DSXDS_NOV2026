# R's default quantile (type 7) values for this dataset:
# Q1 = 2.25, Q3 = 5.00, IQR = 2.75
data <- c(1, 2, 2, 3, 4, 5, 5, 5, 6, 10)

test_that("calc_q1 returns correct Q1 (type 7)", {
  expect_equal(calc_q1(data), 2.25)
  expect_equal(calc_q1(c(1, 2, 3, 4, 5)), 2)
})

test_that("calc_q3 returns correct Q3 (type 7)", {
  expect_equal(calc_q3(data), 5.0)
  expect_equal(calc_q3(c(1, 2, 3, 4, 5)), 4)
})

test_that("calc_iqr returns correct IQR", {
  expect_equal(calc_iqr(data), 2.75)
  expect_equal(calc_iqr(c(1, 2, 3, 4, 5)), 2)
})

test_that("quartile functions handle single value", {
  expect_equal(calc_q1(42), 42)
  expect_equal(calc_q3(42), 42)
  expect_equal(calc_iqr(42), 0)
})

test_that("quartile functions return NA when NAs present and na.rm = FALSE", {
  expect_true(is.na(calc_q1(c(1, NA, 3))))
  expect_true(is.na(calc_q3(c(1, NA, 3))))
  expect_true(is.na(calc_iqr(c(1, NA, 3))))
})

test_that("quartile functions remove NAs when na.rm = TRUE", {
  # after removing NA: c(1, 3, 5); Q1=2, Q3=4, IQR=2
  expect_equal(calc_q1(c(1, NA, 3, 5), na.rm = TRUE), 2)
  expect_equal(calc_q3(c(1, NA, 3, 5), na.rm = TRUE), 4)
  expect_equal(calc_iqr(c(1, NA, 3, 5), na.rm = TRUE), 2)
})

test_that("quartile functions return NA with warning for empty vector", {
  expect_warning(result <- calc_q1(numeric(0)))
  expect_true(is.na(result))
  expect_warning(result <- calc_q3(numeric(0)))
  expect_true(is.na(result))
})

test_that("quartile functions error on non-numeric input", {
  expect_error(calc_q1(c("a", "b")))
  expect_error(calc_q3(c("a", "b")))
  expect_error(calc_iqr(c("a", "b")))
})
