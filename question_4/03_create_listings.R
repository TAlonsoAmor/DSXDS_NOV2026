library(pharmaverseadam)
library(dplyr)
library(gt)


# LOAD DATA ---------------------------------------------------------------
adae <- pharmaverseadam::adae


# CREATE LISTING ----------------------------------------------------------
#Detailed listing of all AEs with: - Subject ID, Treatment, AE Term, Severity, Relationship to drug, Start/End dates - Filtered for treatment-emergent events - Sorted by subject and event date

# Create listing dataset
adae_ls <- adae |> 
  filter(TRTEMFL == "Y") |> 
  select(USUBJID, ACTARM, AETERM, AESEV, AEREL, AESTDTC, AEENDTC) |>
  # sort by USUBJID and AESTDTC
  arrange(USUBJID, ACTARM, AESTDTC) |>
  mutate(
    new_subj = USUBJID != lag(USUBJID, default = ""),   # first row of a new subject
    new_arm  = new_subj | ACTARM != lag(ACTARM, default = ""),  # new subject OR new arm
    new_aeterm = new_arm | AETERM != lag(AETERM, default = ""),
    USUBJID  = if_else(new_subj, USUBJID, ""),
    ACTARM   = if_else(new_arm,  ACTARM,  ""),
    AETERM   = if_else(new_aeterm,  AETERM,  "")
  ) |>
  select(-new_subj, -new_arm, -new_aeterm)
  

# Create and save listing
adae_ls |> 
  gt() |>
  tab_header(title = "Listing of Treatment-Emergent Adverse Events by Subject") |>
  tab_style(
    style     = cell_text(align = "left"),
    locations = cells_title(groups = c("title"))
  ) |>
  tab_options(table_body.hlines.style = "none",
              table.border.top.style = "none") |> 
  cols_align(align = "left", columns = everything()) |>
  gtsave("./question_4/ae_listings.html")

