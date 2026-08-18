"""Command-line entry point for ``python -m sepsis_pipeline``."""

import argparse
from pathlib import Path

from .pipeline import run_pipeline


def main():
    parser = argparse.ArgumentParser(description="Run the Python sepsis mortality workflow.")
    parser.add_argument("--input", type=Path, default=Path("data/sepsis_synthetic_data.csv"))
    parser.add_argument("--output-dir", type=Path, default=Path("results/python"))
    parser.add_argument("--out-year", type=int, default=2026)
    parser.add_argument("--quarter", type=int, choices=(1, 2, 3, 4), default=1)
    args = parser.parse_args()
    result = run_pipeline(args.input, args.output_dir, args.out_year, args.quarter)
    print(f"Completed Python sepsis workflow: {result['patient_fact_rows']} patient-fact rows, {result['summary_rows']} summary rows")
    print(f"Outputs: {args.output_dir}")


if __name__ == "__main__":
    main()
