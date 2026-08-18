"""Cohort creation and predictor-data merge stages."""

from .io import to_int


def create_cohort(rows):
    """Apply the synthetic equivalent of the SAS inpatient cohort filters."""
    cohort = []
    for row in rows:
        if to_int(row.get("occurrence_inp")) != 1:
            continue
        if to_int(row.get("hospice_pre")) == 1:
            continue
        cohort.append(dict(row))
    return cohort


def merge_model_data(cohort_rows, model_rows):
    """Merge cohort records to model data by encounter ID."""
    model_by_id = {row.get("id"): row for row in model_rows}
    merged = []
    for cohort_row in cohort_rows:
        model_row = model_by_id.get(cohort_row.get("id"))
        if model_row is not None:
            combined = dict(cohort_row)
            combined.update(model_row)
            merged.append(combined)
    return merged
