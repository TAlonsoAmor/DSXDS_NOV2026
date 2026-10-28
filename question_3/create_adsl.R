library(metatools)
library(pharmaversesdtm)
library(admiral)
library(xportr)
library(dplyr)
library(tidyr)
library(lubridate)
library(stringr)

# Read in input SDTM data
dm <- pharmaversesdtm::dm
ds <- pharmaversesdtm::ds
ex <- pharmaversesdtm::ex
ae <- pharmaversesdtm::ae
vs <- pharmaversesdtm::vs

# When SAS datasets are imported into R using haven::read_sas(), missing
# character values from SAS appear as "" characters in R, instead of appearing
# as NA values. Further details can be obtained via the following link:
# https://pharmaverse.github.io/admiral/articles/admiral.html#handling-of-missing-values
dm <- convert_blanks_to_na(dm)
ds <- convert_blanks_to_na(ds)
ex <- convert_blanks_to_na(ex)
ae <- convert_blanks_to_na(ae)
vs <- convert_blanks_to_na(vs)

# CREATE ADSL -------------------------------------------------------------
adsl_preds <- dm |> 
  select(-DOMAIN)

# Age grouping variables
agegr9_lookup <- exprs(
  ~condition,            ~AGEGR9, ~AGEGR9N,
  is.na(AGE),          "Missing",        4,
  AGE < 18,                "<18",        1,
  between(AGE, 18, 50),  "18 - 50",        2,
  !is.na(AGE),             ">50",        3
)

adsl_cat <- derive_vars_cat(
  dataset = adsl_preds,
  definition = agegr9_lookup
)

# Exposure derivation
ex_ext <- ex %>%
  derive_vars_dtm(
    dtc = EXSTDTC,
    new_vars_prefix = "EXST"
  ) %>%
  derive_vars_dtm(
    dtc = EXENDTC,
    new_vars_prefix = "EXEN",
    time_imputation = "last"
  )

adsl_raw <- adsl_cat %>%
  # Treatment Start Datetime
  derive_vars_merged(
    dataset_add = ex_ext,
    filter_add = (EXDOSE > 0 |
                    (EXDOSE == 0 &
                       str_detect(EXTRT, "PLACEBO"))) & !is.na(EXSTDTM),
    new_vars = exprs(TRTSDTM = EXSTDTM, TRTSTMF = EXSTTMF),
    order = exprs(EXSTDTM, EXSEQ),
    mode = "first",
    by_vars = exprs(STUDYID, USUBJID)
  ) %>%
  # Treatment End Datetime
  derive_vars_merged(
    dataset_add = ex_ext,
    filter_add = (EXDOSE > 0 |
                    (EXDOSE == 0 &
                       str_detect(EXTRT, "PLACEBO"))) & !is.na(EXENDTM),
    new_vars = exprs(TRTEDTM = EXENDTM, TRTETMF = EXENTMF),
    order = exprs(EXENDTM, EXSEQ),
    mode = "last",
    by_vars = exprs(STUDYID, USUBJID)
  ) %>%
  # Treatment Start and End Date
  derive_vars_dtm_to_dt(source_vars = exprs(TRTSDTM, TRTEDTM)) %>% # Convert Datetime variables to date
  # Treatment Start Time
  derive_vars_dtm_to_tm(source_vars = exprs(TRTSDTM)) %>%
  # Treatment Duration
  derive_var_trtdurd() %>%
  # Safety Population Flag
  derive_var_merged_exist_flag(
    dataset_add = ex,
    by_vars = exprs(STUDYID, USUBJID),
    new_var = SAFFL,
    false_value = "N",
    missing_value = "N",
    condition = (EXDOSE > 0 | (EXDOSE == 0 & str_detect(EXTRT, "PLACEBO")))
  )

# ABNSBPFL
# Set to "Y" if patient has an observation where [VS.VSTESTCD] = "SYSBP" and [VS.VSSTRESU] is "mmHg" and [VS.VSSTRESN] is greater than or equal to 140 or less than 100. Else set to "N".
adsl_vs <- adsl_raw |> 
  derive_var_merged_exist_flag(
    dataset_add = vs,
    by_vars = exprs(STUDYID, USUBJID),
    new_var = ABNSBPFL,
    false_value = "N",
    missing_value = "N",
    condition = (VSTESTCD == "SYSBP" &  VSSTRESU == "mmHg" & (VSSTRESN >= 140| VSSTRESN < 100))
  )

# CARPOPFL
# Set to "Y" if patient has an observation where uppercase of [AE.AESOC] = "CARDIAC DISORDERS". Else set to missing
adsl_ae <- adsl_vs |> 
  derive_var_merged_exist_flag(
    dataset_add = ae |> mutate(AESOC = toupper(AESOC)),
    by_vars = exprs(STUDYID, USUBJID),
    new_var = CARPOPFL,
    condition = (AESOC == "CARDIAC DISORDERS")
  )

#LSTALVDT
adsl_lst <- adsl_ae |> 
  # Set to the last date patient has documented clinical data to show him/her alive, converted to numeric date, using the following dates:
  derive_vars_extreme_event(
    by_vars = exprs(STUDYID, USUBJID),
    events = list(
      # last complete onset date of AEs (datepart of Start Date/Time of Adverse Event [AE.AESTDTC])
      event(
        dataset_name = "ae",
        order = exprs(AESTDTC, AESEQ),
        condition = !is.na(AESTDTC),
        set_values_to = exprs(
          LSTALVDT = convert_dtc_to_dt(AESTDTC, highest_imputation = "M"),
          seq = AESEQ
        ),
      ),
      # last complete date of vital assessment with a valid test result ([VS.VSSTRESN] and [VS.VSSTRESC] not both missing) and datepart of [VS.VSDTC] not missing
      event(
        dataset_name = "vs",
        order = exprs(VSDTC, VSSEQ),
        condition = (!is.na(VSDTC) & !is.na(VSSTRESC)) | (!is.na(VSDTC) & !is.na(VSSTRESN)),
        set_values_to = exprs(
          LSTALVDT = convert_dtc_to_dt(VSDTC, highest_imputation = "M"),
          seq = VSSEQ
        ),
      ),
      # last complete disposition date (datepart of Start Date/Time of Disposition Event [DS.DSSTDTC])
      event(
        dataset_name = "ds",
        order = exprs(DSSTDTC, DSSEQ),
        condition = !is.na(DSSTDTC),
        set_values_to = exprs(
          LSTALVDT = convert_dtc_to_dt(DSSTDTC, highest_imputation = "M"),
          seq = DSSEQ
        ),
      ),
      # last date of treatment administration where patient received a valid dose (datepart of Datetime of Last Exposure to Treatment [ADSL.TRTEDTM])
      event(
        dataset_name = "adsl",
        condition = !is.na(TRTEDTM),
        set_values_to = exprs(LSTALVDT = TRTEDTM, seq = 0),
      )
    ),
    source_datasets = list(ae = ae, vs = vs, ds = ds, adsl = adsl_ae),
    tmp_event_nr_var = event_nr,
    order = exprs(LSTALVDT, seq, event_nr),
    mode = "last",
    new_vars = exprs(LSTALVDT)
  )
  
# ITTFL
# Exercise spec for ITTFL says: Set to "Y" if [DM.ARM] not equal to missing Else set to "N"
# However, in the DM version I have there are no NA values for DM.ARM. There are Screen Failure values, that should correspond to ITTFL NA or N. 
adsl_prefinal <- adsl_lst |> 
  derive_var_merged_exist_flag(
    dataset_add = dm,
    by_vars = exprs(STUDYID, USUBJID),
    new_var = ITTFL,
    false_value = "N",
    condition = (!is.na(ARM) & ARMCD != "Scrnfail")
  )

# Clean ADSL and keep only DM variables + explicitly derived variables
adsl <- adsl_prefinal |> 
  select(names(dm)[names(dm) != 'DOMAIN'], AGEGR9, AGEGR9N, TRTSDTM, TRTSTMF, ITTFL, ABNSBPFL, LSTALVDT, CARPOPFL)

print(adsl)


### MINIMAL QC
