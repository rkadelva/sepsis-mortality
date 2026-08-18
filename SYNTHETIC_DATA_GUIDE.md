# Synthetic Data Guide

This guide explains how to create fictional patient-level sepsis data for testing the SAS workflow. The generated data is for software development and learning only. It does not represent real patients and must not be used for clinical, operational, or research decisions.

## Files

- [data/create_synthetic_data.py](data/create_synthetic_data.py): Python program that generates the data.
- [data/sepsis_synthetic_data.csv](data/sepsis_synthetic_data.csv): Generated CSV file with 1,000 synthetic encounters.

The Python filename is `create_synthetic_data.py`.

## What the Script Creates

The generator creates one row per fictional patient encounter. It includes:

- patient and encounter identifiers
- reporting period, discharge year, and discharge quarter
- VISN, facility, admission source, unit type, and treating specialty
- demographics such as age, gender, race, marital status, and insurance
- laboratory values and categorical laboratory variables
- vital signs and categorical vital-sign variables
- sepsis and organ-dysfunction flags
- hospital utilization and prior-history variables
- chronic-condition predictors used by the mortality model
- predicted mortality and predicted mortality group
- `deaddis`, the simulated hospital-death response variable

The data includes the predictor names used in the project SAS logistic model, such as `age_cat`, `albval_cat`, `bili_cat`, `bun_cat`, `cr_cat`, `glucose_cat`, `wbc_cat`, `lac_cat`, `pulseox_cat`, `resp_cat`, `temp_cat`, `bp_cat`, `model_dx`, `model_proc`, `anyicustay24`, `vasopressor_flag`, `mvent_flag`, `covid`, and chronic-condition indicators.

## Requirements

Python 3 is required. The script uses only Python standard-library modules, so no package installation is needed.

Check that Python is installed:

```bash
python3 --version
```

## Run From VS Code

Open the VS Code terminal and change to the project folder:

```bash
cd /workspaces/sepsis-mortality
```

Run the generator:

```bash
python3 data/create_synthetic_data.py
```

The default command creates or replaces:

```text
data/sepsis_synthetic_data.csv
```

The default output contains 1,000 records.

## Check the Python File Before Running

Compile the file to check for Python syntax errors without generating data:

```bash
python3 -m py_compile data/create_synthetic_data.py
```

No output means the syntax check passed.

## Useful Options

Create a different number of records:

```bash
python3 data/create_synthetic_data.py --records 500
```

Use a specific random seed:

```bash
python3 data/create_synthetic_data.py --seed 123
```

Write to a different CSV file:

```bash
python3 data/create_synthetic_data.py --output data/test_sepsis_data.csv
```

Combine options:

```bash
python3 data/create_synthetic_data.py \
    --records 2000 \
    --seed 123 \
    --output data/sepsis_test_2000.csv
```

## Reproducibility

The default seed is defined in the Python file:

```python
SEED = 20260818
```

Using the same seed and record count produces the same data. This is useful when testing SAS code because changes in results can be attributed to code changes rather than new random data.

For a new synthetic sample, provide a different seed:

```bash
python3 data/create_synthetic_data.py --seed 2027
```

## Inspect the Output

Display the first two lines of the CSV:

```bash
head -n 2 data/sepsis_synthetic_data.csv
```

Count the data rows, excluding the header:

```bash
 tail -n +2 data/sepsis_synthetic_data.csv | wc -l
```

Check the number of columns in the header:

```bash
python3 -c "import csv; print(len(next(csv.reader(open('data/sepsis_synthetic_data.csv', newline='', encoding='utf-8')))))"
```

## Important Limitations

- All records are fictional.
- The response variable `deaddis` is simulated from the generated risk factors.
- `predicted_mortality` is a simulated probability for testing and is not produced by fitting the SAS logistic model.
- The synthetic data is designed to exercise data-processing code, joins, summaries, and exports. It is not calibrated to represent the actual sepsis population.
- Before using the SAS workflow with real data, confirm variable names, formats, coding values, date logic, and source-table mappings in the production environment.
