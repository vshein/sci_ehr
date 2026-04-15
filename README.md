# sci_ehr <img src="man/figures/logo.png" align="right" height="139" alt="sci_ehr logo"/>

> **Bridge ICU Electronic Health Records for Spinal Cord Injury Research**

[![R](https://img.shields.io/badge/R-%3E%3D%204.1.0-276DC3?logo=r&logoColor=white)](https://www.r-project.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-13%2B-336791?logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![University of Waterloo](https://img.shields.io/badge/UWaterloo-Research-gold)](https://uwaterloo.ca)

---

## Overview

**sci_ehr** is an end-to-end R pipeline that transforms raw ICU electronic health record (EHR) data from multiple sources into a unified, analysis-ready PostgreSQL database — purpose-built for **spinal cord injury (SCI) critical care research**.

It handles everything from downloading raw data off PhysioNet, building SCI-specific patient cohorts, harmonizing clinical concepts across databases, to assembling long-format time-series and wide-format flat tables ready for machine learning and statistical analysis.

```
PhysioNet ──► Download ──► Cohort Filter ──► PostgreSQL ──► Concepts ──► Analysis
  MIMIC-III  │                ICD Codes      Harmonized     TS Table
  MIMIC-IV   │                               Schemas        Flat Table
  eICU       └─────────────────────────────────────────────────────────►  sciehr.*
```

---

## Supported Databases

| Database | Version | ICU Stay Key | Notes |
|----------|---------|--------------|-------|
| [MIMIC-III](https://physionet.org/content/mimiciii/) | 1.4 | `icustay_id` | ICD-9 codes |
| [MIMIC-IV](https://physionet.org/content/mimiciv/) | 2.0+ | `stay_id` | ICD-10 codes |
| [eICU-CRD](https://physionet.org/content/eicu-crd/) | 2.0 | `patientunitstayid` | Multi-centre |

> Access to all three databases requires a credentialed PhysioNet account.

---

## Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        sci_ehr pipeline                       │
├──────────┬──────────┬──────────┬──────────┬────────────────────┤
│  Stage 1 │  Stage 2 │  Stage 3 │  Stage 4 │  Stage 5           │
│          │          │          │          │                    │
│ Download │  Import  │  Cohort  │ Load DB  │ Build Concepts     │
│  (curl)  │ CSV→FST  │ ICD filt │ FST→PSQL │ atomic + handcraft │
└──────────┴──────────┴──────────┴──────────┴────────────────────┘
                                                      │
                              ┌───────────────────────┤
                              ▼                       ▼
                        ┌──────────┐           ┌──────────┐
                        │  ts_tab  │           │ flat_tab │
                        │  (long)  │           │  (wide)  │
                        └──────────┘           └──────────┘
                              │                       │
                              └───────────┬───────────┘
                                          ▼
                                   ┌────────────┐
                                   │  sciehr.*  │
                                   │  (merged)  │
                                   └────────────┘
```

---

## Installation

```r
# Install from GitHub
devtools::install_github("vshein/sci_ehr")

# Or from local source (development)
devtools::load_all("/path/to/sci_ehr")

library(sci_ehr)
```

**Dependencies** are installed automatically: `DBI`, `RPostgres`, `dplyr`,
`purrr`, `readr`, `fst`, `data.table`, `jsonlite`, `glue`, `curl`.

---

## Quick Start

### 1. Credentials

Create `config/config_pass.json` in your project directory:

```json
{
  "physionet": {
    "username": "your_physionet_username",
    "password": "your_physionet_password"
  },
  "postgres": {
    "password": "your_postgres_password"
  }
}
```

### 2. Run the full pipeline

```r
library(sci_ehr)

# MIMIC-III — downloads, imports, builds cohort, loads PostgreSQL, extracts concepts
run_source_pipeline(
  src_name       = "miii_demo",
  db_name        = "sciehrdov",
  base_dir       = ".",
  icds_scid_path = "config/icds_ethi_new_07062025.csv",
  icds_inj_path  = "config/icds_injury_reason_initial_05032025.csv"
)

# MIMIC-IV
run_source_pipeline(
  src_name       = "miiv_demo",
  db_name        = "sciehrdov",
  base_dir       = ".",
  icds_scid_path = "config/icds_ethi_new_07062025.csv",
  icds_inj_path  = "config/icds_injury_reason_initial_05032025.csv"
)
```

### 3. Build harmonized tables

```r
run_harmonized_tables(
  src_name      = "miii_demo",
  db_name       = "sciehrdov",
  base_dir      = ".",
  flat_concepts = c("sex", "race", "insurance"),
  build_ts      = TRUE,
  build_flat    = TRUE
)

run_harmonized_tables(
  src_name      = "miiv_demo",
  db_name       = "sciehrdov",
  base_dir      = ".",
  flat_concepts = c("sex", "race", "insurance"),
  build_ts      = TRUE,
  build_flat    = TRUE
)
```

### 4. Merge sources

```r
con <- connect_postgres("sciehrdov", load_credentials("config/config_pass.json"))

DBI::dbExecute(con, "CREATE SCHEMA IF NOT EXISTS sciehr;")

merge_source_tables(
  con               = con,
  source_schemas    = c("miii_demo_coh_ts", "miiv_demo_coh_ts"),
  table_name        = "ts_tab",
  target_schema     = "sciehr",
  target_table_name = "ts"
)

DBI::dbDisconnect(con)
```

### 5. Explore results

```r
con <- connect_postgres("sciehrdov", load_credentials("config/config_pass.json"))

# Smart error messages with spelling suggestions
ts   <- get_dt_from_db(con, "miii_demo_coh_ts",   "ts_tab",   n = 500)
flat <- get_dt_from_db(con, "miii_demo_coh_flat",  "flat_tab", n = 500)
all  <- get_dt_from_db(con, "sciehr",              "ts")

DBI::dbDisconnect(con)
```

---

## Database Schema Layout

After a full pipeline run, your PostgreSQL database contains:

| Schema | Table | Description |
|--------|-------|-------------|
| `{src}_coh` | `visit_windows`, raw tables | Cohort-filtered raw data |
| `{src}_coh` | `d_scid_icd`, `d_inj_icd` | SCI & injury ICD dictionaries |
| `{src}_coh_concepts` | `hr`, `map`, `glu`, … | Per-concept extracted tables |
| `{src}_coh_ts` | `ts_tab` | Long-format time-series |
| `{src}_coh_flat` | `flat_tab` | Wide-format static features |
| `sciehr` | `ts`, `flat` | Merged across all sources |

> `{src}` = `miii_demo`, `miiv_demo`, or `eicu_demo`

---

## Extracted Concepts

sci_ehr extracts **80+ clinical concepts** out of the box:

| Category | Concepts |
|----------|----------|
| **Vitals** | Heart rate, SBP, DBP, MAP, SpO₂, Temperature, Respiratory rate |
| **Labs** | Sodium, Potassium, Creatinine, BUN, Glucose, Lactate, pH, pO₂, pCO₂ |
| **Haematology** | WBC, Haemoglobin, Haematocrit, Platelets, Neutrophils, Lymphocytes |
| **Coagulation** | PT, PTT, INR, Fibrinogen |
| **Liver** | ALT, AST, ALP, Bilirubin (total & direct), Albumin |
| **Cardiac** | Troponin, CK, CK-MB |
| **Vasopressors** | Norepinephrine, Epinephrine, Dopamine, Dobutamine (dose + duration) |
| **Ventilation** | FiO₂, EtCO₂, ventilation start/end |
| **Sedation** | RASS score |
| **Neurological** | GCS (total, motor, verbal, eye) |
| **Demographics** | Age, sex, race, weight, height |
| **Outcomes** | ICU/hospital mortality, LOS, time to death |

---

## Key Functions

| Function | Purpose |
|----------|---------|
| `run_source_pipeline()` | Full 11-stage ingestion for one source |
| `run_harmonized_tables()` | Build `ts_tab` and `flat_tab` |
| `merge_source_tables()` | UNION ALL across sources into `sciehr.*` |
| `connect_postgres()` | Open a DB connection |
| `get_dt_from_db()` | Query a table with smart error hints |
| `download_data()` | Download from PhysioNet |
| `import_data()` | Convert CSV → FST |
| `convert_fst_to_psql()` | Load FST → PostgreSQL |
| `gen_cohort_ids()` | Filter patients by ICD codes |
| `run_atomic_concepts()` | Build concepts from config CSV |
| `make_project_paths()` | Resolve all project paths |
| `load_credentials()` | Load PhysioNet / Postgres credentials |

---

## Project Structure

```
your-project/
├── config/
│   ├── config_pass.json          ← credentials (never commit this)
│   ├── icds_ethi_new_*.csv       ← SCI ICD code list
│   └── icds_injury_*.csv         ← injury ICD code list
├── data/
│   ├── physionet_data/           ← downloaded raw CSVs
│   └── cohorts_data/             ← cohort-filtered FST files
├── sql_output/                   ← generated concept SQL (for inspection)
└── scripts/
    └── run_pipeline.R            ← your analysis entry point
```

---

## Citation

If you use sci_ehr in your research, please cite:

```bibtex
@software{mussavirizi2025sci_ehr,
  author  = {Mussavi Rizi, Marzieh},
  title   = {sci_ehr: Bridge ICU Electronic Health Records for
             Spinal Cord Injury Research},
  year    = {2025},
  url     = {https://github.com/mmussavirizi/sci_ehr},
  version = {0.1.0}
}
```

---

## Authors

**Marzieh Mussavi Rizi** (lead)
School of Public Health Sciences, University of Waterloo
✉️ [mmussavirizi@uwaterloo.ca](mailto:mmussavirizi@uwaterloo.ca)

---

## License

MIT © 2025 Marzieh Mussavi Rizi
