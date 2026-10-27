library(sdtm.oak)
library(pharmaverseraw)
library(pharmaversesdtm)
library(dplyr)


# LOAD RAW DATA -----------------------------------------------------------
# Read in ds data
ds_raw <- pharmaverseraw::ds_raw

# Read in dm domain
dm <- pharmaversesdtm::dm

# LOAD CONTROL TERMINOLOGY ------------------------------------------------
study_ct <- read.csv("./question_2/sdtm_ct.csv")

# CREATE DS DOMAIN --------------------------------------------------------
# Create oak_id_vars
ds_raw <- ds_raw %>%
  generate_oak_id_vars(
    pat_var = "PATNUM",
    raw_src = "ds_raw"
  )

## VARIABLE MAPPING

# Map topic variable
ds <-
  # Derive topic variable
  # Map DSTERM using assign_no_ct, raw_var=IT.DSTERM, tgt_var=DSTERM
  assign_no_ct(
    raw_dat = ds_raw,
    raw_var = "IT.DSTERM",
    tgt_var = "DSTERM",
    id_vars = oak_id_vars()
  )

ds <- ds %>%
  # Map DSDECOD:
  # If OTHERSP is null then map the value in IT.DSDECOD to DSDECOD
  assign_ct(
    raw_dat = condition_add(ds_raw, is.na(OTHERSP)),
    raw_var = "IT.DSDECOD",
    tgt_var = "DSDECOD",
    ct_spec = study_ct,
    ct_clst = "C66727",
    id_vars = oak_id_vars()
  ) %>%
  # If OTHERSP is not null then map the value in OTHERSP to DSDECOD and also to DSTERM
  assign_no_ct(
    raw_dat = condition_add(ds_raw, !is.na(OTHERSP)),
    raw_var = "OTHERSP",
    tgt_var = "DSDECOD",
    id_vars = oak_id_vars()
  ) %>%
  assign_no_ct(
    raw_dat = condition_add(ds_raw, !is.na(OTHERSP)),
    raw_var = "OTHERSP",
    tgt_var = "DSTERM",
    id_vars = oak_id_vars()
  ) %>%
  # Map the value in IT.DSSDAT to DSSTDTC in ISO8601 format
  assign_datetime(
    raw_dat = ds_raw,
    raw_var = "IT.DSSTDAT",
    tgt_var = "DSSTDTC",
    raw_fmt = c("m-d-y"),
    id_vars = oak_id_vars() 
  ) %>%
  # Map the value in DSDTCOL &   DSTMCOL to DSDTC in ISO8601 format
  assign_datetime(
    raw_dat = ds_raw,
    raw_var = c("DSDTCOL", "DSTMCOL"),
    tgt_var = "DSDTC",
    raw_fmt = c("m-d-y", "H:M"),
    id_vars = oak_id_vars(),
    raw_unk = c("UN", "UNK")
  ) |> 
  # Map VISIT from INSTANCE using assign_ct
  assign_ct(
    raw_dat = ds_raw,
    raw_var = "INSTANCE",
    tgt_var = "VISIT",
    ct_spec = study_ct,
    ct_clst = "VISIT",
    id_vars = oak_id_vars()
  ) %>%
  # Map VISITNUM from INSTANCE using assign_ct
  assign_ct(
    raw_dat = ds_raw,
    raw_var = "INSTANCE",
    tgt_var = "VISITNUM",
    ct_spec = study_ct,
    ct_clst = "VISITNUM",
    id_vars = oak_id_vars()
  ) 


# CREATE SDTM derived variables
ds <- ds |> 
  dplyr::mutate(
    STUDYID = ds_raw$STUDY,
    DOMAIN = "DS",
    USUBJID = paste0("01-", ds_raw$PATNUM),
    DSTERM = toupper(DSTERM),
    DSDECOD = toupper(DSDECOD)
  ) %>%
  derive_seq(
    tgt_var = "DSSEQ",
    rec_vars = c("USUBJID", "DSSTDTC","DSTERM")
  ) %>%
  derive_study_day(
    sdtm_in = .,
    dm_domain = dm,
    tgdt = "DSSTDTC",
    refdt = "RFXSTDTC",
    study_day_var = "DSSTDY"
  ) |>
  # Derive DSCAT
  hardcode_ct(tgt_val = "PROTOCOL MILESTONE",
              raw_dat = condition_add(ds_raw, IT.DSDECOD == "Randomized"),
              raw_var = "IT.DSDECOD",
              tgt_var = "DSCAT",
              ct_spec = study_ct,
              ct_clst = "C74558",
              id_vars = oak_id_vars() 
              ) |> 
  hardcode_ct(tgt_val = "OTHER EVENT",
              raw_dat = condition_add(ds_raw, !is.na(OTHERSP)),
              raw_var = "OTHERSP",
              tgt_var = "DSCAT",
              ct_spec = study_ct,
              ct_clst = "C74558",
              id_vars = oak_id_vars() 
              ) |> 
  # Set to Diposition Event all other observations for DSCAT
  mutate(DSCAT = if_else(is.na(DSCAT), "DISPOSITION EVENT", DSCAT)) |> 
  arrange(USUBJID, DSSEQ) |> 
  select(
    "STUDYID", "DOMAIN", "USUBJID", "DSSEQ", "DSTERM", "DSDECOD", "DSCAT", "VISITNUM", "VISIT","DSDTC", "DSSTDTC", "DSSTDY"
  )

print(ds)
