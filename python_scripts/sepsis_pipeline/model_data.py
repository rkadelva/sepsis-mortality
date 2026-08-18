"""Prepare development and current-quarter model data."""

from .io import to_int
from .periods import period_label, previous_periods


def create_model_data(rows, out_year, quarter):
    training_periods = set(previous_periods(out_year, quarter, 8))
    current_period = period_label(out_year, quarter)
    prepared = []
    for row in rows:
        period = (to_int(row.get("discharge_yr")), to_int(row.get("discharge_qtr")))
        if period not in training_periods and period != (out_year, quarter):
            continue
        copy = dict(row)
        copy["dev_flag"] = 0 if copy.get("reporting_period") == current_period else 1
        prepared.append(copy)
    return prepared
