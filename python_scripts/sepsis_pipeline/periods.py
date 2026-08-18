"""Reporting-period and rolling-window utilities."""


def period_label(year, quarter):
    return f"{int(year)}Q{int(quarter)}"


def quarter_index(year, quarter):
    return int(year) * 4 + int(quarter) - 1


def index_to_period(index):
    year, quarter_index_value = divmod(index, 4)
    return year, quarter_index_value + 1


def previous_periods(year, quarter, count=8):
    current = quarter_index(year, quarter)
    return [index_to_period(current - offset) for offset in range(count)]


def period_set(year, quarter, months):
    """Return periods in the current quarter or trailing 6/12/24 months."""
    current = quarter_index(year, quarter)
    quarters = max(1, months // 3)
    return {index_to_period(current - offset) for offset in range(quarters)}


def reporting_windows(year, quarter):
    current = period_label(year, quarter)
    return {
        "Current Quarter": {(year, quarter)},
        "Rolling 6 Months": period_set(year, quarter, 6),
        "Rolling 12 Months": period_set(year, quarter, 12),
        "Rolling 24 Months": period_set(year, quarter, 24),
    }, current
