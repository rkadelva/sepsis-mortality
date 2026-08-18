# Python Sepsis Mortality Package

This folder contains a dependency-free Python implementation of the SAS sepsis mortality workflow. It is designed to run against the included synthetic CSV and provide a local development path before connecting to production data systems.

## Package Layout

| Python file | SAS equivalent | Purpose |
|---|---|---|
| `sepsis_pipeline/periods.py` | `01_define_periods.sas` | Reporting quarter and rolling-window logic |
| `sepsis_pipeline/cohort.py` | `02_create_sepsis_cohort.sas`, `03_merge_model_data.sas` | Cohort filtering and predictor-data merge |
| `sepsis_pipeline/model_data.py` | `02_create_model_data.sas` | Select the prior eight quarters plus current quarter |
| `sepsis_pipeline/logistic_model.py` | `04_build_logistic_model.sas`, `05_run_model_and_predict.sas` | Fit logistic regression and score encounters |
| `sepsis_pipeline/patient_fact.py` | `06_create_patient_fact.sas` | Build patient-level fact data and rolling flags |
| `sepsis_pipeline/summary.py` | `07_create_summary_tables.sas` | Create N, ND, expected deaths, mortality, SMR, and confidence intervals |
| `sepsis_pipeline/lookup.py` | `08a_create_inverse_gamma_lookup.sas` | Create inverse-gamma lookup values |
| `sepsis_pipeline/export.py` | `08_export_sql_server.sas` | Write local SQL Server staging CSVs |
| `sepsis_pipeline/quality.py` | `09_quality_checks.sas` | Validate counts, probabilities, and duplicate IDs |
| `sepsis_pipeline/pipeline.py` | `00_run_all.sas` | Orchestrate all stages |
| `sepsis_pipeline/__main__.py` | Master runner | Command-line interface |

## Why a Package?

A package separates the workflow into small, testable modules. Each module has one responsibility, and `pipeline.py` controls the order of execution. This makes it easier to replace the synthetic CSV reader with a database reader or replace local CSV staging with a SQL Server connector later.

The package uses only Python standard-library modules. No `pip install` step is required for the current version.

## Run the Full Workflow

From the repository root:

```bash
cd /workspaces/sepsis-mortality
PYTHONPATH=python_scripts python3 -m sepsis_pipeline
```

The default command reads:

```text
data/sepsis_synthetic_data.csv
```

and writes results to:

```text
results/python/
```

Run a different reporting quarter:

```bash
PYTHONPATH=python_scripts python3 -m sepsis_pipeline \
    --out-year 2026 \
    --quarter 2 \
    --output-dir results/python_2026Q2
```

Use a different input file:

```bash
PYTHONPATH=python_scripts python3 -m sepsis_pipeline \
    --input data/sepsis_synthetic_data.csv \
    --output-dir results/python
```

## Output Files

The pipeline creates:

- `patient_fact_YYYYQn.csv`: patient-level fact table with model results and rolling flags.
- `summary_YYYYQn.csv`: summary rows by time window, facility, VISN, and reporting group.
- `inverse_gamma_lookup.csv`: lookup values used for SMR confidence intervals.
- `logistic_model.json`: fitted feature names and coefficients.
- `quality_checks.json`: row counts, death counts, probability range, and duplicate-ID checks.
- `sql_server_staging/SepsisSMR_PatientFact_STG.csv`: local equivalent of SQL patient-fact staging.
- `sql_server_staging/SepsisSMR_Summary_STG.csv`: local equivalent of SQL summary staging.
- `sql_server_staging/SepsisDimInverseGammaLookup_STG.csv`: local lookup staging output.

## Pipeline Steps

1. Read the input patient-level CSV.
2. Apply inpatient and hospice cohort filters.
3. Merge cohort rows to model rows by `id`.
4. Keep the prior eight quarters for model development and the current quarter for validation/scoring.
5. Fit a binary logistic regression model using `deaddis` as the response.
6. Generate predicted mortality and predicted mortality groups.
7. Create the patient fact table with current-quarter, rolling 6-month, rolling 12-month, and rolling 24-month flags.
8. Create summary rows with `N`, `ND`, expected deaths, unadjusted mortality, SMR, and approximate 95% SMR confidence intervals.
9. Create the inverse-gamma lookup table.
10. Write local SQL Server staging files.
11. Run quality checks and write the JSON report.

## Validate the Package Before Running

Compile every package file:

```bash
python3 -m compileall python_scripts/sepsis_pipeline
```

Then run the workflow command shown above. The package is intended for development and testing. The logistic implementation and confidence-interval approximation should be validated against the production SAS results before being used for operational reporting.
