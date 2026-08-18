"""Local equivalent of the SAS SQL Server staging export."""

from pathlib import Path

from .io import write_csv


def export_staging(patient_fact, summary_data, lookup_data, output_dir):
    output_dir = Path(output_dir)
    return {
        "patient_fact": write_csv(output_dir / "SepsisSMR_PatientFact_STG.csv", patient_fact),
        "summary": write_csv(output_dir / "SepsisSMR_Summary_STG.csv", summary_data),
        "lookup": write_csv(output_dir / "SepsisDimInverseGammaLookup_STG.csv", lookup_data),
    }
