library(gtsummary)
library(gt)
library(dplyr)
library(pharmaverseadam)

# LOAD DATA ---------------------------------------------------------------
adsl <- pharmaverseadam::adsl
adae <- pharmaverseadam::adae

# CREATE TABLE ------------------------------------------------------------
#Create a summary table of treatment-emergent adverse events (TEAEs). - Treatment-emergent AE records will have TRTEMFL == "Y" in pharmaverseadam::adae - Rows: AETERM or AESOC - Columns: Treatment groups (ACTARM) - Cell values: Count (n) and percentage (%) - Include total row with all subjects - Sort by descending frequency

# Create table dataset
adae_tb <- adae |> 
  filter(TRTEMFL == "Y",
         SAFFL == "Y")

# Crate and save table with gtsummary
tbl <- adae_tb |>
  tbl_hierarchical(
    variables = c(AESOC, AETERM),
    by = ACTARM,
    id = USUBJID,
    denominator = adsl,
    overall_row = TRUE,
    label = "..ard_hierarchical_overall.." ~ "Treatment Emergent AEs"
  ) |> 
  sort_hierarchical(sort = everything() ~ "descending") |> 
  as_gt() |>
  gtsave("./question_4/ae_summary_table.html")



  
