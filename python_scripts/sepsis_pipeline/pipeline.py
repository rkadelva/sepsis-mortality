"""End-to-end orchestration for the Python sepsis mortality workflow."""

import json
from pathlib import Path

from .cohort import create_cohort, merge_model_data
from .export import export_staging
from .io import read_csv, write_csv
from .logistic_model import fit_logistic, score_rows
from .lookup import create_inverse_gamma_lookup
from .model_data import create_model_data
from .patient_fact import create_patient_fact
from .quality import run_quality_checks
from .summary import summarize


def run_pipeline(input_path, output_dir, out_year=2026, quarter=1):
    input_path = Path(input_path)
    output_dir = Path(output_dir)
    raw_rows = read_csv(input_path)
    cohort_rows = create_cohort(raw_rows)
    merged_rows = merge_model_data(cohort_rows, raw_rows)
    model_rows = create_model_data(merged_rows, out_year, quarter)
    training_rows = [row for row in model_rows if row.get("dev_flag") == 1]
    current_rows = [row for row in model_rows if row.get("dev_flag") == 0]
    model = fit_logistic(training_rows)
    scored_rows = score_rows(training_rows + current_rows, model)
    patient_fact = create_patient_fact(scored_rows, out_year, quarter)
    summary_rows = summarize(patient_fact)
    lookup_rows = create_inverse_gamma_lookup(patient_fact)

    output_dir.mkdir(parents=True, exist_ok=True)
    patient_path = write_csv(output_dir / f"patient_fact_{out_year}Q{quarter}.csv", patient_fact)
    summary_path = write_csv(output_dir / f"summary_{out_year}Q{quarter}.csv", summary_rows)
    lookup_path = write_csv(output_dir / "inverse_gamma_lookup.csv", lookup_rows)
    model_path = output_dir / "logistic_model.json"
    model_path.write_text(json.dumps({"feature_names": model.feature_names, "coefficients": model.coefficients}, indent=2) + "\n", encoding="utf-8")
    quality_path = output_dir / "quality_checks.json"
    quality_report = run_quality_checks(patient_fact, summary_rows, quality_path)
    staging_paths = export_staging(patient_fact, summary_rows, lookup_rows, output_dir / "sql_server_staging")
    return {
        "raw_rows": len(raw_rows),
        "cohort_rows": len(cohort_rows),
        "model_rows": len(model_rows),
        "training_rows": len(training_rows),
        "current_rows": len(current_rows),
        "patient_fact_rows": len(patient_fact),
        "summary_rows": len(summary_rows),
        "patient_fact": patient_path,
        "summary": summary_path,
        "lookup": lookup_path,
        "model": model_path,
        "quality": quality_path,
        "quality_report": quality_report,
        "staging": staging_paths,
    }
