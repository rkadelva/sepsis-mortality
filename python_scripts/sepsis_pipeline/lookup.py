"""Create the inverse-gamma lookup used by SMR confidence intervals."""

from .summary import gamma_quantile_approx
from .io import to_int


def create_inverse_gamma_lookup(rows, max_additional=5000):
    maximum_deaths = sum(to_int(row.get("deaddis")) for row in rows)
    lookup = []
    for observed_deaths in range(maximum_deaths + max_additional + 1):
        if observed_deaths == 0:
            lower, upper = 0.0, -__import__("math").log(0.05)
        else:
            lower = gamma_quantile_approx(0.025, observed_deaths)
            upper = gamma_quantile_approx(0.975, observed_deaths + 1)
        lookup.append({"obs": observed_deaths, "gaminvLL": round(lower, 6), "gaminvUL": round(upper, 6)})
    return lookup
