# Run all R questions sequentially
cat("Running question 1: R package\n")
source("question_1/run_question_1.R")
cat("-------------------------------")

cat("\nRunning question 2: DS creation\n")
source("question_2/02_create_ds_domain.R")
cat("-------------------------------")

cat("\nRunning question 3: Create ADSL\n")
source("question_3/create_adsl.R")
cat("\nRunning ADSL QC\n")
source("question_3/qc_adsl.R")
cat("-------------------------------")

cat("\nRunning question 4: Create TLGs\n")
source("question_4/01_create_ae_summary_table.R")
source("question_4/02_create_visualizations.R")
source("question_4/03_create_listings.R")
cat("-------------------------------")