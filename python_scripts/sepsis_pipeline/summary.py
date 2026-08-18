"""Create current-quarter and rolling-window summary statistics."""

import math

from .io import to_float, to_int


GROUP_COLUMNS = ["losingspec", "lward", "organ_system", "age_cat", "severity", "unit_type", "admission_source", "predicted_mortality_group"]
ORGAN_FLAGS = {
    "vasopressor_flag": "Vasopressor",
    "mvent_flag": "Mechanical Ventilator",
    "platelets_flag": "Platelets",
    "lactic_acid_flag": "Lactic Acid",
    "cr_flag": "Creatinine",
    "bili_flag": "Bilirubin",
}


def gamma_quantile_approx(probability, shape):
    """Approximate Gamma(shape, 1) quantile using Wilson-Hilferty."""
    if shape <= 0:
        return 0.0
    z = normal_quantile(probability)
    return max(0.0, shape * (1 - 1 / (9 * shape) + z / math.sqrt(9 * shape)) ** 3)


def normal_quantile(probability):
    # Acklam-style rational approximation, sufficient for SMR display CIs.
    if probability <= 0:
        return -8.0
    if probability >= 1:
        return 8.0
    if probability < 0.5:
        return -normal_quantile(1 - probability)
    t = math.sqrt(-2 * math.log(1 - probability))
    return t - (2.515517 + 0.802853 * t + 0.010328 * t * t) / (1 + 1.432788 * t + 0.189269 * t * t + 0.001308 * t * t * t)


def smr_interval(deaths, expected):
    if expected <= 0:
        return "", ""
    lower = gamma_quantile_approx(0.025, deaths) / expected if deaths else 0.0
    upper = gamma_quantile_approx(0.975, deaths + 1) / expected
    return round(lower, 6), round(upper, 6)


def summarize(rows):
    result = []
    time_fields = [("Rolling 6 Months", "rolling6"), ("Rolling 12 Months", "rolling12"), ("Rolling 24 Months", "rolling24"), ("Current Quarter", "quarter")]
    for time_label, flag in time_fields:
        selected = [row for row in rows if to_int(row.get(flag)) == 1]
        result.extend(summarize_groups(selected, time_label, GROUP_COLUMNS))
        organ_rows = []
        for row in selected:
            for field, label in ORGAN_FLAGS.items():
                if to_int(row.get(field)) == 1:
                    organ = dict(row)
                    organ["groupvar"] = "Organ_Dysfunc"
                    organ["groupvar_value"] = label
                    organ_rows.append(organ)
        result.extend(summarize_groups(organ_rows, time_label, []))
    return result


def summarize_groups(rows, time_label, group_columns):
    groups = {}
    for row in rows:
        if group_columns:
            for column in group_columns:
                key = (column, str(row.get(column, "")), str(row.get("ReportingPeriod", "")), str(row.get("visn", "")), str(row.get("site", "")), str(row.get("unit_type", "")))
                groups.setdefault(key, []).append(row)
        else:
            key = (row.get("groupvar", "Organ_Dysfunc"), row.get("groupvar_value", ""), str(row.get("ReportingPeriod", "")), str(row.get("visn", "")), str(row.get("site", "")), str(row.get("unit_type", "")))
            groups.setdefault(key, []).append(row)
    output = []
    for key, members in groups.items():
        groupvar, group_value, reporting_period, visn, site, unit_type = key
        n = len(members)
        deaths = sum(to_int(row.get("deaddis")) for row in members)
        expected = sum(to_float(row.get("predicted_mortality", row.get("p0"))) for row in members)
        smr = round(deaths / expected, 6) if expected else ""
        lower, upper = smr_interval(deaths, expected)
        output.append({
            "time": time_label,
            "time_order": {"Current Quarter": 1, "Rolling 6 Months": 2, "Rolling 12 Months": 3, "Rolling 24 Months": 4}[time_label],
            "ReportingPeriod": reporting_period,
            "visn": visn,
            "site": site,
            "unit_type": unit_type,
            "groupvar": groupvar,
            "groupvar_value": group_value,
            "N": n,
            "ND": deaths,
            "EXP": round(expected, 6),
            "unadjusted_mortality": round(deaths / n, 6) if n else "",
            "SMR": smr,
            "SMR_CI_lower": lower,
            "SMR_CI_upper": upper,
        })
    return output
