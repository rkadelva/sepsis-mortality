# Sepsis Mortality Project

## Project Overview
This project is designed to maintain and organize SAS code for building a sepsis mortality analytics workflow. The goal is to create a reproducible process that identifies sepsis cohorts, links that cohort to model-derived predictor data, develops a mortality model using historical data, predicts current-period outcomes, creates patient-level fact tables for each reporting period, and generates summary performance tables for mortality monitoring and benchmarking.

The workflow supports operational and analytic use cases such as:
- creating a valid sepsis cohort
- merging cohort records with predictive model variables
- developing a logistic regression model using the previous 2 years of data (8 quarters) with in-hospital death as the response variable
- applying the model to predict outcomes for the current reporting quarter using predictors such as lab values, vital signs, demographics, and hospital characteristics
- creating patient-level datasets for each reporting period that include predicted values
- summarizing mortality outcomes by facility, VISN, and other clinical slices
- exporting cleaned analytic tables to SQL Server for downstream use in Power BI and statistical analysis

---

## Project Purpose
The project supports the production of a structured sepsis mortality reporting framework that can answer questions such as:
- How many discharges occurred within a reporting period?
- How many died within the sepsis cohort?
- What is the observed mortality rate?
- What is the standardized mortality ratio (SMR) and its confidence interval?
- How do outcomes vary by facility, region, admission source, predicted mortality group, specialty, organ system, or dysfunction criteria?

This is intended to support quality improvement, benchmarking, and clinical performance monitoring using standardized definitions and repeatable SAS-based processing.

---

## Core Objectives
1. Build a sepsis cohort using approved inclusion and exclusion criteria.
2. Merge the cohort with model data to bring in all required predictor information.
3. Develop the mortality prediction model using the previous 2 years (8 quarters) of data with in-hospital death as the response variable.
4. Apply the logistic regression model to predict mortality for the current quarter using predictors such as lab values, vital signs, demographics, and hospital characteristics.
5. Create patient-level analytic files for each reporting period that include predicted values.
6. Generate aggregated summary tables for mortality metrics.
7. Export both patient-level and summary-level datasets to SQL Server.
8. Enable downstream reporting in Power BI dashboards and additional analytic exploration.

---

## Data Inputs
The project typically uses multiple data sources, including:
- hospital discharge or encounter data
- sepsis case identification logic and cohort flags
- clinical variables needed for risk adjustment and model prediction
- mortality outcome data
- facility and regional identifiers such as VISN and facility code
- slice variables such as admission source, treating specialty, organ system, organ dysfunction criteria, and predicted mortality group

Each input should be validated for:
- completeness
- coding consistency
- date alignment
- merging keys
- appropriate patient-level unit of analysis

---

## Expected Outputs
The project produces two main categories of analytic output:

### 1. Patient-Level Fact Table
A row-level file containing a single record per patient discharge (or selected analytic unit) with:
- reporting period
- time period indicator
- facility and VISN identifiers
- sepsis cohort flags
- demographic and clinical variables
- model predictors
- predicted mortality value
- mortality outcome
- risk-adjustment or prediction-related fields
- flags for subgroup slices

This fact table is used for further analysis, validation, and dashboard-level drilldown.

### 2. Summary Statistics Table
An aggregate table summarizing outcomes by selected stratification dimensions. For each reporting period, time period window, and subgroup, the table should include:
- Number of discharges (N)
- Number of deaths (ND)
- Unadjusted mortality rate
- Standardized mortality ratio (SMR)
- Confidence intervals for SMR

The summary table should be built for multiple reporting windows, including:
- current quarter (for example, 2025Q4)
- rolling 6 months
- rolling 12 months
- rolling 24 months

Typical subgroup dimensions include:
- reporting period
- time period
- VISN
- facility
- admission source
- predicted mortality group
- treating specialty
- organ system
- unit type
- organ dysfunction categories such as hepatic dysfunction, respiratory dysfunction, and other organ-specific dysfunction criteria
- other clinically relevant slices requested by leadership or quality teams

---

## Step-by-Step Guide

### Step 1: Define the Project Scope and Reporting Structure
Before writing SAS code, define:
- the analytic period (for example, monthly, quarterly, or annual)
- the patient population under study
- the sepsis definition to be used
- the reporting hierarchy (facility, VISN, national, etc.)
- the slice variables required for leadership and dashboard reporting

Document these decisions in the SAS program header and project metadata so the logic is repeatable.

### Step 2: Prepare the Base Data
Create the base extract from source datasets and prepare the required variables for analysis. This includes:
- patient identifiers
- encounter identifiers
- admission/discharge dates
- facility identifiers
- mortality status indicators
- date ranges for reporting periods

Perform basic data quality checks to confirm that key fields are populated and valid.

### Step 3: Build the Sepsis Cohort
Develop the SAS logic to identify eligible sepsis encounters. This typically includes:
- inclusion criteria for sepsis diagnosis or clinical criteria
- exclusions for non-eligible encounters
- cleaning of duplicate or overlapping records
- cohort flag assignment to each encounter

The cohort should be represented as a stable patient-level or encounter-level dataset that can be merged with model and outcome data.

### Step 4: Merge Cohort with Model Data
Merge the sepsis cohort with the model dataset to bring in all required predictors and risk variables. This step should:
- align identifiers and encounter dates
- retain only valid matches
- confirm completeness of predictors for model use
- flag unmatched or missing records

This merged dataset becomes the analytical core for model development and patient-level reporting.

### Step 5: Develop the Logistic Regression Model
Use the previous 2 years of data, typically 8 quarters, to develop a logistic regression model where the outcome is in-hospital death. The model should include predictors such as:
- laboratory values
- vital signs
- demographics
- hospital characteristics
- other clinically relevant sepsis variables identified during model specification

This training dataset should be used to estimate coefficients and validate model performance before deployment for prediction in the current quarter.

### Step 6: Predict Current Quarter Outcomes
Apply the finalized model to the current reporting quarter to generate predicted mortality probabilities for each eligible patient encounter. These predicted values should be stored as a model output variable and merged into the patient-level analytic dataset.

### Step 7: Create Patient-Level Reporting Dataset
Generate a patient-level fact table for each reporting period. This dataset should include:
- reporting period designation
- patient and encounter identifiers
- cohort characteristics
- model predictors
- predicted mortality value
- mortality outcome
- slice variables used for analysis and dashboard segmentation

This table should be standardized and ready for export to SQL Server.

### Step 6: Validate the Patient-Level Data
Before summary creation, run validation checks for:
- row counts by reporting period
- number of deaths and discharge counts
- missing predictor values
- patient duplicates
- mismatches between facility, VISN, and date fields
- sepsis cohort logic outputs

These checks are essential to maintaining analytic integrity.

### Step 7: Create Summary Statistics
Aggregate the patient-level data into summary tables by the required dimensions. At minimum, summary logic should calculate:
- N = number of discharges
- ND = number of deaths
- unadjusted mortality = ND / N
- SMR = observed deaths / expected deaths
- confidence intervals for SMR

Summary statistics should be generated for multiple temporal views, including:
- current quarter (for example, 2025Q4)
- rolling 6 months
- rolling 12 months
- rolling 24 months

The summary dataset should be generated by:
- reporting period
- time period type (current quarter or rolling window)
- VISN
- facility
- admission source
- predicted mortality group
- treating specialty
- organ system
- unit type
- organ dysfunction categories such as hepatic dysfunction, respiratory dysfunction, and other organ-specific dysfunction criteria
- any additional subgroup required by leadership or quality review

### Step 8: Compute SMR and Confidence Intervals
Standardized mortality ratio is calculated as:

SMR = observed deaths / expected deaths

Expected deaths are typically based on a validated risk model or prediction framework. Confidence intervals for SMR should be generated using an appropriate method consistent with the analytic standard used by the program.

Required outputs for each summary group include:
- observed deaths
- expected deaths
- SMR estimate
- lower confidence limit
- upper confidence limit

### Step 9: Prepare Tables for SQL Server Export
Once the patient file and summary file pass validation, prepare them for structured export into SQL Server. Recommended fields include:
- reporting period
- data source version
- extraction date
- facility identifiers
- VISN
- cohort indicators
- outcome metrics
- stratification variables
- model variables
- summary metric values

This ensures a clean and reproducible database lineage for downstream consumers.

### Step 10: Export Data to SQL Server
Export the final analytic datasets to a SQL Server database using SAS SQL or ODBC connectivity. Typical outputs include:
- sepsis_patient_fact
- sepsis_summary_metrics
- optional staging tables for quality checks and validation

These tables can then be used by Power BI and other analytic tools without re-running the underlying SAS logic.

### Step 11: Build Reporting and Dashboard Consumption
After data is available in SQL Server, use Power BI or similar reporting tools to:
- visualize outcomes by reporting period, time period, facility, and VISN
- compare actual vs expected mortality
- drill into slice groups such as admission source, predicted mortality group, treating specialty, organ system, unit type, and organ dysfunction
- monitor changes over time across current-quarter and rolling-window views
- support performance review and quality monitoring

The Power BI dashboard should allow filtering by:
- reporting period
- time period
- VISN
- facility
- reporting group dimensions such as admission source, predicted mortality group, treating specialty, organ system, unit type, and organ dysfunction

These filters should allow users to present summary statistics by both time-period and clinical subgroup while maintaining consistent definitions across the dashboard.

---

## Suggested SAS Project Structure
A typical project folder can be organized as follows:

- data/
  - raw/
  - clean/
  - derived/
- programs/
  - 01_define_periods.sas
  - 02_create_sepsis_cohort.sas
  - 03_merge_model_data.sas
  - 04_create_patient_fact.sas
  - 05_create_summary_tables.sas
  - 06_export_sql_server.sas
  - 07_quality_checks.sas
- outputs/
  - patient_fact/
  - summary_metrics/
  - logs/
- documentation/
  - data_dictionary.md
  - definitions.md

---

## Quality and Governance Standards
To ensure the project remains trustworthy and reproducible, each SAS program should follow these standards:
- use consistent naming conventions
- document assumptions and definitions in a header block
- retain logs for traceability
- maintain a data dictionary for all variables
- preserve versioning when logic changes
- keep date stamps for each extract and output run
- validate final output against expected counts and mortality patterns

---

## Data Security and Access Considerations
Because this project may include patient-level clinical and facility-level data:
- restrict access to authorized users only
- store outputs in approved database locations
- use secure SQL Server connections
- limit export and dashboard access to approved reporting groups
- maintain audit trails for data refreshes and transformations

---

## Recommended Workflow Summary
The recommended end-to-end workflow is:

1. ingest raw source data
2. define reporting periods
3. build sepsis cohort
4. merge model predictors
5. create patient-level fact table
6. calculate mortality and SMR metrics
7. generate subgroup summary tables
8. validate outputs
9. export results to SQL Server
10. use Power BI for dashboarding and analysis

---

## Expected Project Value
This project provides a repeatable and scalable framework for sepsis mortality analytics. It supports:
- consistent measurement of clinical outcomes
- population-level mortality review
- risk-adjusted performance monitoring
- transparent reporting by facility and VISN
- dashboard-driven operational insights
- a centralized analytic store for future quality studies and benchmarking

---

## Final Notes
This repository is intended to house the SAS code and documentation needed to execute the workflow from cohort creation through SQL Server export. As the project evolves, additional programs, definitions, and validation logic should be added in a structured, version-controlled way to maintain consistency across reporting cycles.
