# Question 1: Descriptive Statistics Package Demo
# Installs and loads the descriptiveStats package, then runs example usage.

devtools::install("question_1/descriptive_stats", quiet = TRUE)
library(descriptiveStats)

data <- c(1, 2, 2, 3, 4, 5, 5, 5, 6, 10)

cat("Input data:", paste(data, collapse = ", "), "\n\n")

cat("Mean:   ", calc_mean(data),   "\n")
cat("Median: ", calc_median(data), "\n")
cat("Mode:   ", calc_mode(data),   "\n")
cat("Q1:     ", calc_q1(data),     "\n")
cat("Q3:     ", calc_q3(data),     "\n")
cat("IQR:    ", calc_iqr(data),    "\n")

cat("\n--- NA handling (na.rm = FALSE by default) ---\n")
data_with_na <- c(1, NA, 3, 4, 5)
cat("Data with NA:", paste(data_with_na, collapse = ", "), "\n")
cat("Mean (na.rm = FALSE):", calc_mean(data_with_na),               "\n")
cat("Mean (na.rm = TRUE): ", calc_mean(data_with_na, na.rm = TRUE), "\n")

cat("\n--- Mode edge cases ---\n")
cat("Tied mode c(1,1,2,2,3):", calc_mode(c(1, 1, 2, 2, 3)), "\n")
