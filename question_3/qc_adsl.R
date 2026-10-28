library(pharmaversesdtm)
library(dplyr)
library(lubridate)
library(stringr)

# ---------------------------------------------------------------------------
# 1. Load data and coerce blank strings to NA
# ---------------------------------------------------------------------------

blank_to_na <- function(df) {
  df |> mutate(across(where(is.character), ~ na_if(.x, "")))
}

dm <- blank_to_na(pharmaversesdtm::dm)
ex <- blank_to_na(pharmaversesdtm::ex)
vs <- blank_to_na(pharmaversesdtm::vs)
ae <- blank_to_na(pharmaversesdtm::ae)
ds <- blank_to_na(pharmaversesdtm::ds)

# ---------------------------------------------------------------------------
# 2. Helper functions
# ---------------------------------------------------------------------------

# Returns Date if datepart is complete YYYY-MM-DD, else NA_Date_
dtc_to_dt <- function(dtc) {
  date_str <- substr(dtc, 1, 10)
  dplyr::if_else(
    grepl("^\\d{4}-\\d{2}-\\d{2}", date_str),
    as.Date(date_str),
    as.Date(NA_character_)
  )
}

# Returns POSIXct UTC: requires complete datepart; imputes missing time
# components to "00" (first) or "23"/"59"/"59" (last); NA if datepart incomplete
dtc_to_dtm <- function(dtc, time_imputation = "first") {
  imp_hh <- if (time_imputation == "last") "23" else "00"
  imp_mm <- if (time_imputation == "last") "59" else "00"
  imp_ss <- if (time_imputation == "last") "59" else "00"

  date_str  <- substr(dtc, 1, 10)
  has_date  <- grepl("^\\d{4}-\\d{2}-\\d{2}", date_str)

  time_part <- substr(dtc, 12, nchar(dtc))

  hh <- dplyr::if_else(
    nchar(time_part) >= 2 & grepl("^\\d{2}", time_part),
    substr(time_part, 1, 2), imp_hh
  )
  mm <- dplyr::if_else(
    nchar(time_part) >= 5 & grepl("^\\d{2}:\\d{2}", time_part),
    substr(time_part, 4, 5), imp_mm
  )
  ss <- dplyr::if_else(
    nchar(time_part) >= 8 & grepl("^\\d{2}:\\d{2}:\\d{2}", time_part),
    substr(time_part, 7, 8), imp_ss
  )

  dt_str <- paste0(date_str, " ", hh, ":", mm, ":", ss)
  result <- as.POSIXct(dt_str, tz = "UTC", format = "%Y-%m-%d %H:%M:%S")
  result[!has_date] <- as.POSIXct(NA_character_, tz = "UTC")
  result
}

# Returns imputation flag for time component:
#   "H"  — no time present at all
#   "M"  — only HH present (minutes missing)
#   NA   — HH:MM or HH:MM:SS present (seconds-only missing -> no flag)
get_tmf <- function(dtc) {
  has_date <- grepl("^\\d{4}-\\d{2}-\\d{2}", substr(dtc, 1, 10))
  time_part <- substr(dtc, 12, nchar(dtc))
  has_hhmm  <- grepl("^\\d{2}:\\d{2}", time_part)
  has_hh    <- grepl("^\\d{2}", time_part) & nchar(time_part) >= 2

  dplyr::case_when(
    !has_date          ~ NA_character_,
    has_hhmm           ~ NA_character_,   # HH:MM (or HH:MM:SS) — no flag needed
    has_hh             ~ "M",
    TRUE               ~ "H"
  )
}

# ---------------------------------------------------------------------------
# 3. Derive QC variables
# ---------------------------------------------------------------------------

## AGEGR9 / AGEGR9N ----------------------------------------------------------
qc_age <- dm |>
  select(STUDYID, USUBJID, AGE) |>
  mutate(
    AGEGR9 = case_when(
      is.na(AGE)              ~ "Missing",
      AGE < 18               ~ "<18",
      AGE >= 18 & AGE <= 50  ~ "18 - 50",
      AGE > 50               ~ ">50"
    ),
    AGEGR9N = case_when(
      is.na(AGE)              ~ 4L,
      AGE < 18               ~ 1L,
      AGE >= 18 & AGE <= 50  ~ 2L,
      AGE > 50               ~ 3L
    )
  ) |>
  select(STUDYID, USUBJID, AGEGR9, AGEGR9N)

## TRTSDTM / TRTSTMF ---------------------------------------------------------
ex_valid <- ex |>
  filter(
    (EXDOSE > 0 | (EXDOSE == 0 & str_detect(EXTRT, "PLACEBO"))) &
      grepl("^\\d{4}-\\d{2}-\\d{2}", substr(EXSTDTC, 1, 10))
  ) |>
  mutate(
    EXSTDTM_qc = dtc_to_dtm(EXSTDTC),
    TRTSTMF_qc = get_tmf(EXSTDTC)
  ) |>
  arrange(STUDYID, USUBJID, EXSTDTM_qc, EXSEQ) |>
  group_by(STUDYID, USUBJID) |>
  slice(1) |>
  ungroup() |>
  select(STUDYID, USUBJID, TRTSDTM = EXSTDTM_qc, TRTSTMF = TRTSTMF_qc)

## TRTEDTM (needed for LSTALVDT) ---------------------------------------------
ex_end_valid <- ex |>
  filter(
    (EXDOSE > 0 | (EXDOSE == 0 & str_detect(EXTRT, "PLACEBO"))) &
      grepl("^\\d{4}-\\d{2}-\\d{2}", substr(EXENDTC, 1, 10))
  ) |>
  mutate(EXENDTM_qc = dtc_to_dtm(EXENDTC, time_imputation = "last")) |>
  filter(!is.na(EXENDTM_qc)) |>
  arrange(STUDYID, USUBJID, desc(EXENDTM_qc), desc(EXSEQ)) |>
  group_by(STUDYID, USUBJID) |>
  slice(1) |>
  ungroup() |>
  select(STUDYID, USUBJID, TRTEDTM = EXENDTM_qc)

## ITTFL ---------------------------------------------------------------------
qc_ittfl <- dm |>
  select(STUDYID, USUBJID, ARM, ARMCD) |>
  mutate(ITTFL = if_else(!is.na(ARM) & ARMCD != "Scrnfail", "Y", "N")) |>
  select(STUDYID, USUBJID, ITTFL)

## ABNSBPFL ------------------------------------------------------------------
abnsbp_flag <- vs |>
  filter(
    VSTESTCD == "SYSBP" &
      VSSTRESU == "mmHg" &
      (VSSTRESN >= 140 | VSSTRESN < 100)
  ) |>
  distinct(STUDYID, USUBJID) |>
  mutate(ABNSBPFL = "Y")

qc_abnsbpfl <- dm |>
  select(STUDYID, USUBJID) |>
  left_join(abnsbp_flag, by = c("STUDYID", "USUBJID")) |>
  mutate(ABNSBPFL = if_else(is.na(ABNSBPFL), "N", ABNSBPFL)) |>
  select(STUDYID, USUBJID, ABNSBPFL)

## CARPOPFL ------------------------------------------------------------------
carpop_flag <- ae |>
  filter(toupper(AESOC) == "CARDIAC DISORDERS") |>
  distinct(STUDYID, USUBJID) |>
  mutate(CARPOPFL = "Y")

qc_carpopfl <- dm |>
  select(STUDYID, USUBJID) |>
  left_join(carpop_flag, by = c("STUDYID", "USUBJID")) |>
  # NA when patient has no cardiac AE (spec says NA, not "N")
  select(STUDYID, USUBJID, CARPOPFL)

## LSTALVDT ------------------------------------------------------------------

# VS dates: complete datepart AND at least one of VSSTRESN / VSSTRESC not NA
vs_dates <- vs |>
  mutate(dt = dtc_to_dt(VSDTC)) |>
  filter(!is.na(dt) & !(is.na(VSSTRESN) & is.na(VSSTRESC))) |>
  group_by(STUDYID, USUBJID) |>
  summarise(vs_lstdt = max(dt, na.rm = TRUE), .groups = "drop")

# AE dates: complete datepart of AESTDTC
ae_dates <- ae |>
  mutate(dt = dtc_to_dt(AESTDTC)) |>
  filter(!is.na(dt)) |>
  group_by(STUDYID, USUBJID) |>
  summarise(ae_lstdt = max(dt, na.rm = TRUE), .groups = "drop")

# DS dates: complete datepart of DSSTDTC
ds_dates <- ds |>
  mutate(dt = dtc_to_dt(DSSTDTC)) |>
  filter(!is.na(dt)) |>
  group_by(STUDYID, USUBJID) |>
  summarise(ds_lstdt = max(dt, na.rm = TRUE), .groups = "drop")

qc_lstalvdt <- dm |>
  select(STUDYID, USUBJID) |>
  left_join(ex_end_valid, by = c("STUDYID", "USUBJID")) |>
  left_join(vs_dates,  by = c("STUDYID", "USUBJID")) |>
  left_join(ae_dates,  by = c("STUDYID", "USUBJID")) |>
  left_join(ds_dates,  by = c("STUDYID", "USUBJID")) |>
  rowwise() |>
  mutate(
    LSTALVDT = {
      dtms <- c(
        as.POSIXct(vs_lstdt, tz = "UTC"),
        as.POSIXct(ae_lstdt, tz = "UTC"),
        as.POSIXct(ds_lstdt, tz = "UTC"),
        TRTEDTM
      )
      dtms <- dtms[!is.na(dtms)]
      if (length(dtms) == 0) as.POSIXct(NA_character_, tz = "UTC") else max(dtms)
    }
  ) |>
  ungroup() |>
  select(STUDYID, USUBJID, LSTALVDT)

# ---------------------------------------------------------------------------
# 4. Assemble qc_adsl
# ---------------------------------------------------------------------------

qc_adsl <- dm |>
  select(STUDYID, USUBJID) |>
  left_join(qc_age,       by = c("STUDYID", "USUBJID")) |>
  left_join(ex_valid,     by = c("STUDYID", "USUBJID")) |>
  left_join(qc_ittfl,     by = c("STUDYID", "USUBJID")) |>
  left_join(qc_abnsbpfl,  by = c("STUDYID", "USUBJID")) |>
  left_join(qc_lstalvdt,  by = c("STUDYID", "USUBJID")) |>
  left_join(qc_carpopfl,  by = c("STUDYID", "USUBJID"))

# ---------------------------------------------------------------------------
# 5. Compare function
# ---------------------------------------------------------------------------

compare_adsl <- function(adsl, qc_adsl) {
  vars_to_check <- c("AGEGR9", "AGEGR9N", "TRTSDTM", "TRTSTMF",
                     "ITTFL", "ABNSBPFL", "LSTALVDT", "CARPOPFL")

  # Keep only vars that exist in both datasets
  vars_to_check <- intersect(
    vars_to_check,
    intersect(names(adsl), names(qc_adsl))
  )

  joined <- adsl |>
    select(STUDYID, USUBJID, all_of(vars_to_check)) |>
    left_join(
      qc_adsl |> select(STUDYID, USUBJID, all_of(vars_to_check)),
      by = c("STUDYID", "USUBJID"),
      suffix = c("_adsl", "_qc")
    )

  summary_rows <- lapply(vars_to_check, function(v) {
    col_adsl <- paste0(v, "_adsl")
    col_qc   <- paste0(v, "_qc")

    a <- joined[[col_adsl]]
    q <- joined[[col_qc]]

    # Normalise to numeric for POSIXct comparison
    if (inherits(a, "POSIXct") || inherits(q, "POSIXct")) {
      a <- as.numeric(a)
      q <- as.numeric(q)
    }

    # NA == NA counts as match
    mismatch   <- !(is.na(a) & is.na(q)) & (is.na(a) | is.na(q) | a != q)
    val_mis    <- sum(mismatch & !is.na(a) & !is.na(q), na.rm = TRUE)
    adsl_na_qc <- sum(is.na(a) & !is.na(q), na.rm = TRUE)
    qc_na_adsl <- sum(!is.na(a) & is.na(q), na.rm = TRUE)
    n_mis      <- sum(mismatch, na.rm = TRUE)

    if (n_mis > 0) {
      cat("\n--- Mismatches for:", v, "---\n")
      mis_rows <- joined[mismatch, c("STUDYID", "USUBJID", col_adsl, col_qc)]
      print(as.data.frame(mis_rows))
    }

    data.frame(
      variable          = v,
      status            = if (n_mis == 0) "PASS" else "FAIL",
      n_value_mismatch  = val_mis,
      n_adsl_na_qc_not  = adsl_na_qc,
      n_qc_na_adsl_not  = qc_na_adsl,
      stringsAsFactors  = FALSE
    )
  })

  summary_tbl <- do.call(rbind, summary_rows)
  cat("\n========== QC SUMMARY ==========\n")
  print(summary_tbl, row.names = FALSE)
  cat("=================================\n")

  invisible(summary_tbl)
}

# ---------------------------------------------------------------------------
# 6. Run — source create_adsl.R then compare
# ---------------------------------------------------------------------------

source("question_3/create_adsl.R")

compare_adsl(adsl, qc_adsl)
