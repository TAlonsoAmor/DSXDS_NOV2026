# DSXDS_NOV2026

R and Python project with answers to six questions covering clinical data programming: package development, SDTM mapping, ADaM derivation, TLG creation, REST API development, and GenAI assistant building. Each question lives in its own subdirectory and branch.

## Repository structure

```
DSXDS_NOV2026/
├── run_all.R              # Sources all R questions sequentially
├── question_1/
│   ├── descriptive_stats/ # R package source (DESCRIPTION, R/, tests/)
│   └── run_question_1.R   # Installs the package and runs example usage
├── question_2/
│   ├── 02_create_ds_domain.R  # Creates the DS SDTM domain using sdtm.oak
│   └── sdtm_ct.csv            # Study control terminology
├── question_3/
│   ├── create_adsl.R    # Derives the ADSL ADaM dataset using admiral
│   └── qc_adsl.R        # QC script for ADSL
├── question_4/
│   ├── 01_create_ae_summary_table.R  # AE summary table (gtsummary / gt) → ae_summary_table.html
│   ├── 02_create_visualizations.R    # AE plots (ggplot2) → plot_1.png, plot_2.png
│   ├── 03_create_listings.R          # AE listings (gt) → ae_listings.html
│   ├── ae_summary_table.html
│   ├── ae_listings.html
│   ├── plot_1.png
│   └── plot_2.png
├── question_5/
│   ├── main.py       # FastAPI application
│   ├── adae.csv      # Input data 
│   └── test_api.sh   # Bash script to test all endpoints with curl
└── question_6/
    ├── agent.py      # ClinicalTrialDataAgent — GenAI assistant (mocked LLM)
    └── test_agent.py # Runs 3 example natural-language queries and prints results
```

## Questions

| # | Topic | Key output |
|---|-------|------------|
| 1 | R package — `descriptiveStats` | Mean, median, mode, Q1, Q3, IQR with NA handling |
| 2 | SDTM mapping — DS domain | DS dataset printed to console |
| 3 | ADaM derivation — ADSL | ADSL dataset; QC script for validation |
| 4 | TLGs — AE summary table, visualisations, listings | HTML tables + PNG plots |
| 5 | REST API — adverse event query and subject risk scoring | FastAPI app served on port 8000 |
| 6 | GenAI assistant — natural language to Pandas query | `ClinicalTrialDataAgent` with mocked LLM |

## How to run

### Questions 1–4 (R)

All R scripts must be sourced from the **project root** so that relative paths resolve correctly.

#### Run everything

```r
source("run_all.R")
```

#### Run individual questions

```r
# Question 1 — build and demo the descriptiveStats package
source("question_1/run_question_1.R")

# Question 2 — create the DS SDTM domain
source("question_2/02_create_ds_domain.R")

# Question 3 — derive ADSL
source("question_3/create_adsl.R")

# Question 3 — QC ADSL
source("question_3/qc_adsl.R")

# Question 4 — AE summary table, plots, and listings
source("question_4/01_create_ae_summary_table.R")
source("question_4/02_create_visualizations.R")
source("question_4/03_create_listings.R")
```

#### Question 1 — package development extras

```r
# Run tests
devtools::test("question_1/descriptive_stats")

# Full package check
devtools::check("question_1/descriptive_stats")
```

### Question 5 — FastAPI REST API

The API must be started before running the tests. Run both commands from the `question_5/` directory.

**Step 1 — start the server:**

```bash
cd question_5
python -m uvicorn main:app --reload
```

The server starts on `http://127.0.0.1:8000`. Keep this terminal open.

**Step 2 — run the tests in a second terminal:**

```bash
cd question_5
bash test_api.sh
```

The script exercises six scenarios:

| Test | What it checks |
|------|----------------|
| 1 | `GET /` — health check |
| 2 | `POST /ae-query` with no filters — returns all AE records |
| 3 | `POST /ae-query` filtered by severity `MILD` |
| 4 | `POST /ae-query` filtered by severity `MILD, MODERATE` and treatment arm `Placebo` |
| 5 | `GET /subject-risk/01-701-1015` — subject with 3 MILD events, expects risk score 3 (Low) |
| 6 | `GET /subject-risk/1234` — unknown subject, expects HTTP 404 |

### Question 6 — GenAI Clinical Data Assistant

Run from the `question_6/` directory:

```bash
cd question_6
python3 test_agent.py
```

This runs three example natural-language queries and prints the filter applied, subject count, and matching subject IDs for each.

The agent (`agent.py`) implements the full `Prompt → Parse → Execute` pipeline:

1. **Prompt** — `_build_prompt()` wraps the user question with a schema description that tells the model what columns (`AESEV`, `AETERM`, `AESOC`) and values are available.
2. **Parse** — `_call_llm()` returns a JSON object like `{"target_column": "AESEV", "filter_value": "MODERATE"}`. Currently this step is mocked with keyword-based logic; replacing the body of `_call_llm()` with a real OpenAI API call requires no other changes.
3. **Execute** — `_execute()` applies the parsed filter as a Pandas boolean mask to the `adae` dataframe and returns the unique subject count and list of `USUBJID`s.

