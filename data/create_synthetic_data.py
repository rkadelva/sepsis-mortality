"""Create synthetic patient-level sepsis model data for development and testing.

This data is entirely fictional and must not be used for clinical or operational
analysis. The generated columns mirror the predictors and response used by the
project SAS model, with 1,000 patient encounters by default.
"""

import argparse
import csv
import math
import random
from datetime import date, timedelta
from pathlib import Path


SEED = 20260818
DEFAULT_RECORDS = 1000
DEFAULT_OUTPUT = Path(__file__).with_name("sepsis_synthetic_data.csv")


def choose(rng, values, weights=None):
    return rng.choices(values, weights=weights, k=1)[0]


def clamp(value, low, high):
    return max(low, min(high, value))


def category(value, breaks, labels):
    for limit, label in zip(breaks, labels):
        if value < limit:
            return label
    return labels[-1]


def sigmoid(value):
    return 1.0 / (1.0 + math.exp(-clamp(value, -20, 20)))


def create_row(rng, record_number, encounter_date):
    age = int(clamp(round(rng.gauss(67, 17)), 18, 100))
    sex = choose(rng, ["F", "M"], [0.52, 0.48])
    race = choose(rng, ["White", "Black", "Hispanic", "Asian", "Other"], [0.55, 0.18, 0.12, 0.06, 0.09])

    albumin = round(clamp(rng.gauss(2.9, 0.65), 1.0, 5.0), 2)
    bilirubin = round(clamp(rng.lognormvariate(math.log(1.2), 0.65), 0.1, 20.0), 2)
    bun = round(clamp(rng.gauss(28, 20), 4, 150), 1)
    creatinine = round(clamp(rng.lognormvariate(math.log(1.3), 0.6), 0.2, 12.0), 2)
    glucose = round(clamp(rng.gauss(145, 65), 40, 600), 1)
    hct = round(clamp(rng.gauss(34, 7), 12, 55), 1)
    sodium = round(clamp(rng.gauss(138, 7), 115, 170), 1)
    wbc = round(clamp(rng.lognormvariate(math.log(10), 0.55), 1, 60), 1)
    lactate = round(clamp(rng.lognormvariate(math.log(2.2), 0.55), 0.4, 18), 2)
    platelets = round(clamp(rng.gauss(205, 90), 10, 700), 1)
    pao2 = round(clamp(rng.gauss(78, 22), 35, 180), 1)
    pco2 = round(clamp(rng.gauss(42, 10), 20, 80), 1)
    ph = round(clamp(rng.gauss(7.37, 0.08), 6.9, 7.6), 3)
    pulse = int(clamp(round(rng.gauss(96, 22)), 35, 180))
    pulseox = int(clamp(round(rng.gauss(94, 5)), 65, 100))
    resp = int(clamp(round(rng.gauss(21, 7)), 8, 60))
    temp = round(clamp(rng.gauss(37.2, 1.0), 33, 41), 1)
    systolic_bp = int(clamp(round(rng.gauss(112, 24)), 55, 220))

    any_icu = int(rng.random() < 0.28)
    vasopressor = int(rng.random() < (0.08 + 0.15 * (lactate > 4) + 0.10 * (systolic_bp < 90)))
    mechanical_ventilation = int(rng.random() < (0.08 + 0.16 * (pulseox < 88) + 0.08 * (resp > 30)))
    platelets_flag = int(platelets < 50)
    lactic_acid_flag = int(lactate >= 2)
    creatinine_flag = int(creatinine >= 2)
    bilirubin_flag = int(bilirubin >= 2)
    infection_flag = int(rng.random() < 0.82)
    covid = int(rng.random() < 0.08)

    chronic_flags = {
        "cancer_mets": int(rng.random() < 0.08),
        "drug_abuse": int(rng.random() < 0.05),
        "wghtloss": int(rng.random() < 0.04),
        "cancer_leuk": int(rng.random() < 0.03),
        "psychoses": int(rng.random() < 0.07),
        "liver_sev": int(rng.random() < 0.04),
        "neuro_oth": int(rng.random() < 0.06),
        "pulmcirc": int(rng.random() < 0.03),
        "coag": int(rng.random() < 0.04),
        "cbvd": int(rng.random() < 0.05),
        "cancer_solid": int(rng.random() < 0.12),
        "renlfl_sev": int(rng.random() < 0.08),
        "depress": int(rng.random() < 0.12),
        "chf": int(rng.random() < 0.14),
        "anemdef": int(rng.random() < 0.11),
        "obese": int(rng.random() < 0.24),
        "diab_cx": int(rng.random() < 0.20),
        "lung_chronic": int(rng.random() < 0.15),
    }

    organ_dysfunction_count = sum(
        [vasopressor, mechanical_ventilation, platelets_flag, lactic_acid_flag, creatinine_flag, bilirubin_flag]
    )
    model_dx = choose(rng, ["CV9", "GI7", "HM1", "NP3", "NU9", "RS11", "SP5", "OM1", "RN1"], [24, 15, 8, 12, 10, 12, 8, 6, 5])
    model_proc = int(rng.random() < 0.22)
    lward = choose(rng, ["Clinic/ED", "Medical", "Surgical", "ICU"], [0.48, 0.25, 0.15, 0.12])
    admission_source = choose(rng, ["Emergency", "Transfer", "Clinic", "Other"], [0.62, 0.18, 0.12, 0.08])

    logit = (
        -3.35
        + 0.025 * (age - 60)
        + 0.55 * (albumin < 2.5)
        + 0.45 * (bilirubin >= 2)
        + 0.35 * (bun >= 40)
        + 0.55 * (creatinine >= 2)
        + 0.55 * (lactate >= 4)
        + 0.55 * (pulseox < 90)
        + 0.45 * (resp > 30)
        + 0.55 * (systolic_bp < 90)
        + 0.70 * any_icu
        + 0.75 * vasopressor
        + 0.70 * mechanical_ventilation
        + 0.45 * platelets_flag
        + 0.35 * covid
        + 0.16 * organ_dysfunction_count
        + 0.12 * sum(chronic_flags.values())
        + 0.20 * (admission_source == "Transfer")
    )
    predicted_mortality = round(sigmoid(logit), 5)
    deaddis = int(rng.random() < predicted_mortality)

    if predicted_mortality < 0.025:
        predicted_group = "<2.5%"
        p0_group = 1
    elif predicted_mortality < 0.05:
        predicted_group = "2.5-<5%"
        p0_group = 2
    elif predicted_mortality < 0.10:
        predicted_group = "5-<10%"
        p0_group = 3
    elif predicted_mortality < 0.30:
        predicted_group = "10-<30%"
        p0_group = 4
    else:
        predicted_group = "30%+"
        p0_group = 5

    discharge_year = encounter_date.year
    discharge_quarter = ((encounter_date.month - 1) // 3) + 1
    row = {
        "id": f"SYN{record_number:06d}",
        "id2": f"ENC{record_number:06d}",
        "patid": f"PAT{record_number:06d}",
        "visn": choose(rng, [1, 2, 3, 4, 5], [0.20, 0.20, 0.22, 0.18, 0.20]),
        "site": f"FAC{rng.randint(1, 30):03d}",
        "site_orig": f"FAC{rng.randint(1, 30):03d}",
        "reporting_period": f"{discharge_year}Q{discharge_quarter}",
        "discharge_yr": discharge_year,
        "discharge_qtr": discharge_quarter,
        "discharge_date": encounter_date.isoformat(),
        "admission_source": admission_source,
        "unit_type": choose(rng, ["Medical", "Surgical", "ICU", "Stepdown"], [0.42, 0.22, 0.24, 0.12]),
        "treating_specialty": choose(rng, ["Medicine", "Surgery", "Cardiology", "Neurology", "Other"], [0.48, 0.20, 0.12, 0.08, 0.12]),
        "organ_system": model_dx,
        "occurrence_inp": 1,
        "discharge_status": "DEATH" if deaddis else "ALIVE",
        "deaddis": deaddis,
        "predicted_mortality": predicted_mortality,
        "predicted_mortality_group": predicted_group,
        "p0": predicted_mortality,
        "p0_group": p0_group,
        "decile": min(9, int(predicted_mortality * 10)),
        "age": age,
        "age_cat": category(age, [45, 55, 65, 75, 85], ["[LOW,45)", "[45,55)", "[55,65)", "[65,75)", "[75,85)", "[85,HIGH]"]),
        "gender": sex,
        "race": race,
        "married": int(rng.random() < 0.42),
        "insurance": int(rng.random() < 0.96),
        "los_prior": round(clamp(rng.expovariate(1 / 3), 0, 60), 1),
        "los_prior_cat": choose(rng, ["0 days", "1-2 days", "3-4 days", "5+ days"], [0.45, 0.30, 0.15, 0.10]),
        "medsurg": choose(rng, ["Medical", "Surgical"], [0.75, 0.25]),
        "immuno": int(rng.random() < 0.12),
        "lward": lward,
        "model_dx": model_dx,
        "model_proc": model_proc,
        "infection_flag": infection_flag,
        "anyicustay24": "Yes" if any_icu else "No",
        "vasopressor_flag": vasopressor,
        "mvent_flag": mechanical_ventilation,
        "platelets_flag": platelets_flag,
        "lactic_acid_flag": lactic_acid_flag,
        "cr_flag": creatinine_flag,
        "bili_flag": bilirubin_flag,
        "num_acuteorgdysf_cat": "4+" if organ_dysfunction_count >= 4 else str(organ_dysfunction_count),
        "organ_dysfunction_count": organ_dysfunction_count,
        "hepatic_dysfunction": bilirubin_flag,
        "respiratory_dysfunction": int(mechanical_ventilation or pulseox < 90 or resp > 30),
        "renal_dysfunction": creatinine_flag,
        "box0sp6": int(rng.random() < 0.08),
        "box0sp9": int(rng.random() < 0.06),
        "platelets": platelets,
        "platelets_cat": category(platelets, [50, 250, 260, 400], ["0-50", "50-250", "250-260", "260-400", "400+"]),
        "albumin": albumin,
        "albval_cat": category(albumin, [2.5, 3.5], ["[LOW,2.4]", "(2.4,3.4]", "(3.4,HIGH]" ]),
        "bilirubin": bilirubin,
        "bili_cat": category(bilirubin, [2, 5], ["[LOW,1.9]", "(1.9,4.9]", "(4.9,HIGH]" ]),
        "bun": bun,
        "bun_cat": category(bun, [17, 40], ["[LOW,16.9]", "(16.9,39.9]", "(39.9,HIGH]" ]),
        "creatinine": creatinine,
        "cr_cat": category(creatinine, [1.5, 3], ["(0.4,1.4]", "(1.4,2.9]", "(2.9,HIGH]" ]),
        "glucose": glucose,
        "glucose_cat": category(glucose, [60, 200], ["[LOW,59]", "(59,199]", "(199,HIGH]" ]),
        "hct": hct,
        "hct_cat": category(hct, [30, 41], ["[LOW,29.9]", "(29.9,40.9]", "(40.9,HIGH]" ]),
        "sodium": sodium,
        "na_cat": category(sodium, [135, 155], ["[LOW,134]", "(134,154]", "(154,HIGH]" ]),
        "wbc": wbc,
        "wbc_cat": category(wbc, [3, 20], ["[LOW,2.9]", "(2.9,19.9]", "(19.9,HIGH]" ]),
        "lactate": lactate,
        "lac_cat": category(lactate, [2, 4], ["[LOW,2)", "[2,4)", "[4,HIGH]" ]),
        "pulse": pulse,
        "pulse_cat": category(pulse, [50, 100], ["[LOW,50)", "[50,99]", "[100,HIGH]" ]),
        "pulseox": pulseox,
        "pulseox_cat": category(pulseox, [90, 95], ["[LOW,90)", "[90,94]", "[95,HIGH]" ]),
        "resp": resp,
        "resp_cat": category(resp, [14, 25], ["[LOW,14)", "[14,24]", "[25,HIGH]" ]),
        "temp": temp,
        "temp_cat": category(temp, [36, 38.5], ["[LOW,36)", "[36,38.4]", "[38.4,HIGH]" ]),
        "systolic_bp": systolic_bp,
        "bp_cat": category(systolic_bp, [80, 100], ["[LOW,80)", "[80,99]", "[100,HIGH]" ]),
        "covid": covid,
        "n_hosp90d_sepsisadm": rng.randint(0, 4),
        "n_obs90d_sepsisadm": rng.randint(0, 3),
        "dev_flag": int(not (discharge_year == 2026 and discharge_quarter == 1)),
        "hospice_pre": int(rng.random() < 0.03),
        "hospice_post": int(rng.random() < 0.05),
    }
    row.update(chronic_flags)
    return row


def create_dataset(records=DEFAULT_RECORDS, seed=SEED):
    rng = random.Random(seed)
    start_date = date(2024, 1, 1)
    return [
        create_row(rng, index + 1, start_date + timedelta(days=rng.randint(0, 365 * 2 + 89)))
        for index in range(records)
    ]


def main():
    parser = argparse.ArgumentParser(description="Create fictional sepsis patient-level model data.")
    parser.add_argument("--records", type=int, default=DEFAULT_RECORDS)
    parser.add_argument("--seed", type=int, default=SEED)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()

    if args.records < 1:
        parser.error("--records must be at least 1")

    rows = create_dataset(args.records, args.seed)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", newline="", encoding="utf-8") as output_file:
        writer = csv.DictWriter(output_file, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    print(f"Created {len(rows):,} synthetic records in {args.output}")


if __name__ == "__main__":
    main()
