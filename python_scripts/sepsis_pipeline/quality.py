"""Quality checks corresponding to the SAS quality-check macro."""

import json
from collections import Counter
from pathlib import Path

from .io import to_float, to_int


def run_quality_checks(patient_fact, summary_data, output_path=None):
    if not patient_fact:
        raise ValueError("patient_fact is empty")
    if not summary_data:
        raise ValueError("summary_data is empty")
    raw_probabilities = [row.get("predicted_mortality", "") for row in patient_fact]
    probabilities = [to_float(value) for value in raw_probabilities if value != ""]
    report = {
        "patient_fact_rows": len(patient_fact),
        "summary_rows": len(summary_data),
        "reporting_period_counts": dict(Counter(row.get("ReportingPeriod", "") for row in patient_fact)),
        "deaddis_counts": dict(Counter(str(to_int(row.get("deaddis"))) for row in patient_fact)),
        "predicted_mortality_nonmissing": len(probabilities),
        "predicted_mortality_min": min(probabilities) if probabilities else None,
        "predicted_mortality_max": max(probabilities) if probabilities else None,
        "duplicate_ids": len(patient_fact) - len({row.get("id") for row in patient_fact}),
    }
    if report["duplicate_ids"]:
        raise ValueError(f"patient_fact contains {report['duplicate_ids']} duplicate IDs")
    if not all(0 <= value <= 1 for value in probabilities):
        raise ValueError("predicted_mortality must be between 0 and 1")
    if output_path:
        output_path = Path(output_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    return report
