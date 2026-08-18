"""Create patient-level fact data and rolling-period flags."""

from .io import to_int
from .periods import period_label, reporting_windows


def create_patient_fact(rows, out_year, quarter):
    windows, current_label = reporting_windows(out_year, quarter)
    fact = []
    for row in rows:
        year = to_int(row.get("discharge_yr"))
        qtr = to_int(row.get("discharge_qtr"))
        period = (year, qtr)
        copy = dict(row)
        copy["ReportingPeriod"] = current_label
        copy["quarter"] = int(period in windows["Current Quarter"])
        copy["rolling6"] = int(period in windows["Rolling 6 Months"])
        copy["rolling12"] = int(period in windows["Rolling 12 Months"])
        copy["rolling24"] = int(period in windows["Rolling 24 Months"])
        copy["num_acuteorg_dysf"] = organ_dysfunction_label(copy)
        copy["severity"] = copy.get("predicted_mortality_group", "")
        fact.append(copy)
    return fact


def organ_dysfunction_label(row):
    count = sum(to_int(row.get(field)) for field in ("vasopressor_flag", "mvent_flag", "platelets_flag", "lactic_acid_flag", "cr_flag", "bili_flag"))
    return "Zero" if count == 0 else ("One" if count == 1 else ("Two" if count == 2 else ("Three" if count == 3 else str(count))))
