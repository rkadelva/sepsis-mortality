# Step-by-Step Guide: Create Sepsis Staging Tables with Python

This guide explains how to run the Python implementation of the sepsis mortality workflow and create the patient-level fact table, summary table, inverse-gamma lookup table, SQL staging CSVs, and quality-check report.

The Python workflow mirrors the major stages in the SAS programs, but writes local CSV files instead of connecting directly to SQL Server.

> The included data is synthetic and fictional. It is intended for learning, development, and testing only.

## 1. Understand the Project Folders

From the repository root, the important folders are:

```text
sepsis-mortality/
├── code/                         SAS programs
├── data/                         Input data and synthetic-data generator
│   ├── raw/
│   ├── clean/
│   ├── derived/
│   ├── create_synthetic_data.py
│   └── sepsis_synthetic_data.csv
├── python_scripts/               Python package
│   ├── run_pipeline.py
│   ├── README.md
│   └── sepsis_pipeline/
├── results/                      SAS and Python outputs
│   └── python/
├── README.md
└── STEP_BY_STEP_GUIDE.md         This guide
```

The Python package is under `python_scripts/sepsis_pipeline/`. The package contains small modules, with each module responsible for one part of the workflow.

## 2. Check That Python Is Installed

Open the VS Code terminal and run:

```bash
python3 --version
```

Python 3.9 or newer is recommended.

Change to the repository root:

```bash
cd /workspaces/sepsis-mortality
```

The commands in this guide assume you are running them from this directory.

## 3. Understand the Input Data

The default input file is:

```text
data/sepsis_synthetic_data.csv
```

It contains fictional patient encounters with:

- patient and encounter identifiers
- discharge year and quarter
- VISN and facility
- demographics
- laboratory values
- vital signs
- sepsis and organ-dysfunction flags
- model predictor variables
- `deaddis`, the hospital-death response variable

The Python pipeline expects a CSV with a header row. The `id` column is used as the encounter merge key.

## 4. Optional: Create or Re-create Synthetic Input Data

The synthetic-data generator is:

```text
data/create_synthetic_data.py
```

Run it with the default settings:

```bash
python3 data/create_synthetic_data.py
```

This creates:

```text
data/sepsis_synthetic_data.csv
```

The default file contains 1,000 records.

Create a different number of records:

```bash
python3 data/create_synthetic_data.py --records 2000
```

Use a specific random seed so the result can be reproduced:

```bash
python3 data/create_synthetic_data.py --seed 123
```

Write to a different file:

```bash
python3 data/create_synthetic_data.py \
    --records 1000 \
    --output data/test_sepsis_data.csv
```

Check the generator before running it:

```bash
python3 -m py_compile data/create_synthetic_data.py
```

## 5. Understand How the Python Package Was Created

The package was created by separating the SAS workflow into Python modules:

| Python module | Workflow responsibility | SAS equivalent |
|---|---|---|
| `periods.py` | Quarter labels and rolling 6/12/24-month windows | `01_define_periods.sas` |
| `cohort.py` | Cohort filters and model-data merge | `02_create_sepsis_cohort.sas`, `03_merge_model_data.sas` |
| `model_data.py` | Select prior eight quarters and current quarter | `02_create_model_data.sas` |
| `logistic_model.py` | Fit logistic regression and create predictions | `04_build_logistic_model.sas`, `05_run_model_and_predict.sas` |
| `patient_fact.py` | Create patient-level fact records and time flags | `06_create_patient_fact.sas` |
| `summary.py` | Create N, ND, expected deaths, mortality, SMR, and CIs | `07_create_summary_tables.sas` |
| `lookup.py` | Create inverse-gamma lookup values | `08a_create_inverse_gamma_lookup.sas` |
| `export.py` | Write local SQL staging CSVs | `08_export_sql_server.sas` |
| `quality.py` | Validate outputs | `09_quality_checks.sas` |
| `pipeline.py` | Run the modules in the correct order | `00_run_all.sas` |
| `__main__.py` | Provide the command-line interface | Master runner |

The package uses Python standard-library modules only. The current implementation does not require pandas, NumPy, SciPy, or scikit-learn.

## 6. Check the Package Before Running It

Compile all Python package files:

```bash
python3 -m compileall -q python_scripts/sepsis_pipeline python_scripts/run_pipeline.py
```

If the command completes without an error, the Python files have valid syntax.

## 7. Run the Complete Workflow

Run the default 2026 quarter 1 workflow:

```bash
PYTHONPATH=python_scripts python3 -m sepsis_pipeline \
    --input data/sepsis_synthetic_data.csv \
    --output-dir results/python \
    --out-year 2026 \
    --quarter 1
```

What each option means:

- `PYTHONPATH=python_scripts`: tells Python where to find the package.
- `python3 -m sepsis_pipeline`: runs the package command-line entry point.
- `--input`: identifies the patient-level input CSV.
- `--output-dir`: identifies the folder where outputs will be written.
- `--out-year`: identifies the reporting year.
- `--quarter`: identifies the reporting quarter; valid values are 1, 2, 3, or 4.

You can also run the convenience script:

```bash
python3 python_scripts/run_pipeline.py \
    --input data/sepsis_synthetic_data.csv \
    --output-dir results/python \
    --out-year 2026 \
    --quarter 1
```

The `PYTHONPATH` form is preferred because it runs the package in the same way it would be run after installation.

## 8. What Happens During the Run

The package runs these steps in order:

### Step 8.1: Read the input CSV

`io.py` reads the CSV into Python dictionaries. Each dictionary represents one patient encounter.

### Step 8.2: Create the sepsis cohort

`cohort.py` applies basic cohort filters. The current synthetic implementation keeps inpatient records and excludes records flagged with `hospice_pre = 1`.

### Step 8.3: Merge model data

The cohort is merged back to the model data using the `id` field. In a production implementation, this is where source cohort data and model predictor data would be joined.

### Step 8.4: Select model periods

`model_data.py` selects the previous eight quarters for model development and the current quarter for scoring.

For example, with `--out-year 2026 --quarter 1`:

- prior eight-quarter data is used for training when available
- `2026Q1` is treated as the current quarter
- `dev_flag = 1` identifies development records
- `dev_flag = 0` identifies current-quarter records

### Step 8.5: Fit the logistic model

`logistic_model.py` fits a binary logistic regression model using:

```text
deaddis = hospital death response
```

The model uses numeric predictors, categorical predictors, vital signs, laboratory values, demographics, hospital variables, and organ-dysfunction flags.

The fitted model produces:

- `predicted_mortality`
- `p0`
- `predicted_mortality_group`
- `p0_group`
- `decile`

### Step 8.6: Create the patient fact table

`patient_fact.py` creates a patient-level record and adds:

- `ReportingPeriod`
- `quarter`
- `rolling6`
- `rolling12`
- `rolling24`
- `num_acuteorg_dysf`
- `severity`

This is the Python equivalent of the patient-level fact-table step.

### Step 8.7: Create the summary table

`summary.py` creates summary rows for:

- current quarter
- rolling 6 months
- rolling 12 months
- rolling 24 months

The summary includes:

- `N`: number of records/discharges
- `ND`: number of deaths
- `EXP`: sum of predicted mortality, or expected deaths
- `unadjusted_mortality`: `ND / N`
- `SMR`: `ND / EXP`
- `SMR_CI_lower`
- `SMR_CI_upper`

The summary is grouped by reporting dimensions and reporting groups such as facility, VISN, admission source, unit type, organ system, severity, and organ dysfunction.

### Step 8.8: Create the inverse-gamma lookup

`lookup.py` creates the lookup table used by the SMR confidence-interval calculation. The result contains:

- `obs`: observed death count
- `gaminvLL`: lower lookup value
- `gaminvUL`: upper lookup value

### Step 8.9: Write local staging files

`export.py` writes CSV files that represent the SQL Server staging outputs. No SQL Server connection is required for the local test workflow.

### Step 8.10: Run quality checks

`quality.py` validates:

- patient fact is not empty
- summary table is not empty
- predicted probabilities are between 0 and 1
- patient IDs are unique
- reporting-period counts are available
- death counts are available

## 9. Find the Generated CSV Files

After a successful run, list all CSV files:

```bash
find results/python -type f -name '*.csv' -print
```

The main output files are:

```text
results/python/patient_fact_2026Q1.csv
results/python/summary_2026Q1.csv
results/python/inverse_gamma_lookup.csv
```

The local SQL staging copies are:

```text
results/python/sql_server_staging/SepsisSMR_PatientFact_STG.csv
results/python/sql_server_staging/SepsisSMR_Summary_STG.csv
results/python/sql_server_staging/SepsisDimInverseGammaLookup_STG.csv
```

Other generated files include:

```text
results/python/logistic_model.json
results/python/quality_checks.json
```

## 10. Check the Number of Rows

Count data rows without counting the header:

```bash
for file in \
    results/python/patient_fact_2026Q1.csv \
    results/python/summary_2026Q1.csv \
    results/python/inverse_gamma_lookup.csv
 do
    echo "$file"
    tail -n +2 "$file" | wc -l
done
```

The synthetic example currently produces approximately:

- patient fact: 864 rows
- summary: 11,921 rows
- inverse-gamma lookup: 5,187 rows

The exact counts can change if the input data, reporting quarter, or synthetic-data seed changes.

## 11. Inspect the CSV Files

Show the header and first data row of the patient fact table:

```bash
head -n 2 results/python/patient_fact_2026Q1.csv
```

Show the header and first data row of the summary table:

```bash
head -n 2 results/python/summary_2026Q1.csv
```

Show the header and first data row of the inverse-gamma lookup:

```bash
head -n 2 results/python/inverse_gamma_lookup.csv
```

Read the quality report:

```bash
cat results/python/quality_checks.json
```

## 12. Run a Different Reporting Quarter

For 2026 quarter 2, write to a separate results folder:

```bash
PYTHONPATH=python_scripts python3 -m sepsis_pipeline \
    --input data/sepsis_synthetic_data.csv \
    --output-dir results/python_2026Q2 \
    --out-year 2026 \
    --quarter 2
```

The resulting patient fact file will be:

```text
results/python_2026Q2/patient_fact_2026Q2.csv
```

The resulting summary file will be:

```text
results/python_2026Q2/summary_2026Q2.csv
```

Using a separate output folder prevents one reporting-period run from overwriting another.

## 13. Run With Another Input File

If you have another CSV with the required columns, run:

```bash
PYTHONPATH=python_scripts python3 -m sepsis_pipeline \
    --input data/derived/my_model_data.csv \
    --output-dir results/python_custom \
    --out-year 2026 \
    --quarter 1
```

Before using another input file, check that it contains at least:

- `id`
- `discharge_yr`
- `discharge_qtr`
- `reporting_period`
- `deaddis`
- `occurrence_inp`
- `hospice_pre`
- model predictors used by `logistic_model.py`

## 14. Troubleshooting

### Error: `No module named sepsis_pipeline`

Run the command from the repository root and include `PYTHONPATH=python_scripts`:

```bash
cd /workspaces/sepsis-mortality
PYTHONPATH=python_scripts python3 -m sepsis_pipeline
```

### Error: input file not found

Check that the input file exists:

```bash
ls -l data/sepsis_synthetic_data.csv
```

If necessary, create it again:

```bash
python3 data/create_synthetic_data.py
```

### Error: CSV column or key errors

Inspect the input header:

```bash
head -n 1 data/sepsis_synthetic_data.csv
```

The Python input schema must match the expected model-predictor names.

### Output folder contains old files

The package overwrites files with the same names but does not remove unrelated files. To start fresh:

```bash
rm -rf results/python
PYTHONPATH=python_scripts python3 -m sepsis_pipeline
```

Use this only for generated output folders, not for source-code folders.

### Summary table is empty

Confirm that the input contains records for the selected reporting period and historical periods. Also confirm that `occurrence_inp` is 1 and `hospice_pre` is not 1 for eligible records.

## 15. Important Production Notes

This package is a development and testing implementation. Before production use:

1. Replace the synthetic CSV reader with approved production data access.
2. Confirm all SAS-to-Python variable mappings.
3. Compare logistic-model coefficients and predictions with SAS.
4. Validate SMR confidence intervals against the approved SAS method.
5. Add the production SQL Server connector and table mappings.
6. Validate duplicate handling and patient-level grain.
7. Run both SAS and Python outputs on the same controlled test data.
8. Obtain the required data, security, privacy, and clinical approvals.

The local SQL staging CSV files are not a direct SQL Server export. They are development outputs with the same general purpose as the SAS staging tables.
