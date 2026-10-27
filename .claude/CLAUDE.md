# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

R project (`DSXDS_NOV2026.Rproj`) organised around discrete questions, each in its own subdirectory (e.g. `question_1/`). Work is tracked on per-question branches (e.g. `1-question_1`).

## R conventions

- 2-space indentation, UTF-8 encoding (set in `.Rproj`).
- Workspace save/restore is set to Default — do not rely on `.RData` being present.

## Common R commands

```r
# Source a script
source("question_1/script.R")

# Run tests (if testthat is used)
testthat::test_dir("question_1/tests")

# Install missing packages
install.packages("package_name")
```

## Branch workflow

Each question lives on its own branch named `<issue-number>-<question_name>`. Open a PR back to `main` when the question is complete.
