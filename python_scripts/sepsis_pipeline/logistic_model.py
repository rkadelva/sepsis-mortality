"""Small dependency-free binary logistic regression implementation."""

import math

from .io import to_float, to_int


NUMERIC_PREDICTORS = [
    "age", "albumin", "bilirubin", "bun", "creatinine", "glucose", "hct", "sodium",
    "wbc", "lactate", "platelets", "pulse", "pulseox", "resp", "temp", "systolic_bp",
    "anyicustay24", "model_proc", "immuno", "vasopressor_flag", "mvent_flag", "covid",
    "platelets_flag", "lactic_acid_flag", "cr_flag", "bili_flag", "box0sp6", "box0sp9",
    "insurance", "cancer_mets", "drug_abuse", "wghtloss", "cancer_leuk", "psychoses",
    "liver_sev", "neuro_oth", "pulmcirc", "coag", "cbvd", "cancer_solid", "renlfl_sev",
    "depress", "chf", "anemdef", "obese", "diab_cx", "lung_chronic",
]

CATEGORICAL_PREDICTORS = ["age_cat", "albval_cat", "bili_cat", "bun_cat", "cr_cat", "glucose_cat", "hct_cat", "na_cat", "wbc_cat", "lac_cat", "pulse_cat", "pulseox_cat", "resp_cat", "temp_cat", "bp_cat", "model_dx", "lward", "platelets_cat"]


class LogisticModel:
    def __init__(self, feature_names, coefficients, numeric_stats=None):
        self.feature_names = feature_names
        self.coefficients = coefficients
        self.numeric_stats = numeric_stats or {}

    def predict_probability(self, row):
        values = [1.0] + [feature_value(row, name, self.numeric_stats) for name in self.feature_names]
        score = sum(coefficient * value for coefficient, value in zip(self.coefficients, values))
        score = max(-30.0, min(30.0, score))
        return 1.0 / (1.0 + math.exp(-score))


def feature_value(row, feature_name, numeric_stats=None):
    if feature_name.endswith("="):
        column, value = feature_name[:-1].split("==", 1)
        return float(str(row.get(column, "")) == value)
    if feature_name == "anyicustay24":
        return float(str(row.get(feature_name, "No")) == "Yes")
    value = to_float(row.get(feature_name), 0.0)
    if numeric_stats and feature_name in numeric_stats:
        mean, scale = numeric_stats[feature_name]
        return (value - mean) / scale
    return value


def design_features(rows):
    names = list(NUMERIC_PREDICTORS)
    categories = {}
    for column in CATEGORICAL_PREDICTORS:
        values = sorted({row.get(column, "") for row in rows if row.get(column, "") != ""})
        categories[column] = values[1:]
        names.extend(f"{column}=={value}=" for value in values[1:])
    return names


def fit_logistic(rows, outcome="deaddis", iterations=700, learning_rate=0.035):
    feature_names = design_features(rows)
    numeric_stats = {}
    for feature_name in NUMERIC_PREDICTORS:
        values = [to_float(row.get(feature_name), 0.0) for row in rows]
        mean = sum(values) / len(values) if values else 0.0
        variance = sum((value - mean) ** 2 for value in values) / len(values) if values else 0.0
        numeric_stats[feature_name] = (mean, max(math.sqrt(variance), 1.0))
    coefficients = [0.0] * (len(feature_names) + 1)
    if not rows:
        return LogisticModel(feature_names, coefficients, numeric_stats)
    for _ in range(iterations):
        gradients = [0.0] * len(coefficients)
        for row in rows:
            values = [1.0] + [feature_value(row, name, numeric_stats) for name in feature_names]
            score = sum(coefficient * value for coefficient, value in zip(coefficients, values))
            prediction = 1.0 / (1.0 + math.exp(-max(-30.0, min(30.0, score))))
            error = prediction - to_int(row.get(outcome))
            for index, value in enumerate(values):
                gradients[index] += error * value
        scale = learning_rate / len(rows)
        for index in range(len(coefficients)):
            coefficients[index] -= scale * gradients[index]
    return LogisticModel(feature_names, coefficients, numeric_stats)


def score_rows(rows, model):
    scored = []
    for row in rows:
        copy = dict(row)
        probability = round(model.predict_probability(copy), 6)
        copy["predicted_mortality"] = probability
        copy["p0"] = probability
        if probability < 0.025:
            group, group_number = "<2.5%", 1
        elif probability < 0.05:
            group, group_number = "2.5-<5%", 2
        elif probability < 0.10:
            group, group_number = "5-<10%", 3
        elif probability < 0.30:
            group, group_number = "10-<30%", 4
        else:
            group, group_number = "30%+", 5
        copy["predicted_mortality_group"] = group
        copy["p0_group"] = group_number
        copy["decile"] = min(9, int(probability * 10))
        scored.append(copy)
    return scored
