# DSXDS_NOV2026

R project with answers to four questions covering clinical data programming: package development, SDTM mapping, ADaM derivation, and TLG creation. Each question lives in its own subdirectory and branch.

## Repository structure

```
DSXDS_NOV2026/
├── run_all.R              # Sources all questions sequentially
├── question_1/
│   ├── descriptive_stats/ # R package source (DESCRIPTION, R/, tests/)
│   └── run_question_1.R   # Installs the package and runs example usage
├── question_2/
│   ├── 02_create_ds_domain.R  # Creates the DS SDTM domain using sdtm.oak
│   └── sdtm_ct.csv            # Study control terminology
├── question_3/
│   ├── create_adsl.R    # Derives the ADSL ADaM dataset using admiral
│   └── qc_adsl.R        # QC script for ADSL
└── question_4/
    ├── 01_create_ae_summary_table.R  # AE summary table (gtsummary / gt) → ae_summary_table.html
    ├── 02_create_visualizations.R    # AE plots (ggplot2) → plot_1.png, plot_2.png
    ├── 03_create_listings.R          # AE listings (gt) → ae_listings.html
    ├── ae_summary_table.html
    ├── ae_listings.html
    ├── plot_1.png
    └── plot_2.png
```

## Questions

| # | Topic | Key output |
|---|-------|------------|
| 1 | R package — `descriptiveStats` | Mean, median, mode, Q1, Q3, IQR with NA handling |
| 2 | SDTM mapping — DS domain | DS dataset printed to console |
| 3 | ADaM derivation — ADSL | ADSL dataset; QC script for validation |
| 4 | TLGs — AE summary table, visualisations, listings | HTML tables + PNG plots |

## How to run

All scripts must be sourced from the **project root** so that relative paths resolve correctly.

### Run everything

```r
source("run_all.R")
```

### Run individual questions

```r
# Question 1 — build and demo the descriptiveStats package
suppressMessages(source("question_1/run_question_1.R"))

# Question 2 — create the DS SDTM domain
suppressMessages(source("question_2/02_create_ds_domain.R"))

# Question 3 — derive ADSL
source("question_3/create_adsl.R")

# Question 3 — QC ADSL
source("question_3/qc_adsl.R")

# Question 4 — AE summary table, plots, and listings
source("question_4/01_create_ae_summary_table.R")
source("question_4/02_create_visualizations.R")
source("question_4/03_create_listings.R")
```

### Question 1 — package development extras

```r
# Run tests
devtools::test("question_1/descriptive_stats")

# Full package check
devtools::check("question_1/descriptive_stats")
```

