# descriptiveStats

An R package providing descriptive statistics functions with explicit NA handling and edge case coverage.

## Installation

```r
devtools::install("question_1/descriptive_stats")
```

## Functions

| Function | Description |
|----------|-------------|
| `calc_mean(x, na.rm)` | Arithmetic mean |
| `calc_median(x, na.rm)` | Median |
| `calc_mode(x, na.rm)` | Mode — returns all tied values if tie exists |
| `calc_q1(x, na.rm)` | First quartile (Q1) |
| `calc_q3(x, na.rm)` | Third quartile (Q3) |
| `calc_iqr(x, na.rm)` | Interquartile range (Q3 − Q1) |

All functions accept a numeric vector `x` and an optional `na.rm` argument (default `FALSE`).

## Usage

```r
library(descriptiveStats)

data <- c(1, 2, 2, 3, 4, 5, 5, 5, 6, 10)

calc_mean(data)    # 3.3
calc_median(data)  # 4.5
calc_mode(data)    # 5
calc_q1(data)      # 2.5
calc_q3(data)      # 5.5
calc_iqr(data)     # 3

# NA handling
calc_mean(c(1, NA, 3))              # NA
calc_mean(c(1, NA, 3), na.rm = TRUE) # 2

# Tied mode
calc_mode(c(1, 1, 2, 2, 3))  # c(1, 2)
```

## Running Tests

```r
devtools::test("question_1/descriptive_stats")
```

## Package Check

```r
devtools::check("question_1/descriptive_stats")
```
