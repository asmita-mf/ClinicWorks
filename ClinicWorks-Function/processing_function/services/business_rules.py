from datetime import datetime
import re


IGNORED_CONTEXTS = {
    "goal",
    "target",
    "previous",
    "past",
    "historical",
    "reference",
}


def is_ignored_context(context: str | None) -> bool:
    if not context:
        return False

    context = context.strip().lower()

    return context in IGNORED_CONTEXTS


def parse_blood_pressure(
    value: str,
) -> tuple[int, int] | None:

    if not value:
        return None

    match = re.search(
        r"(\d{2,3})\s*/\s*(\d{2,3})",
        value,
    )

    if not match:
        return None

    systolic = int(match.group(1))
    diastolic = int(match.group(2))

    return systolic, diastolic


def select_blood_pressure(
    candidates: list,
    patient_age: int | None,
) -> str | None:

    # No BP result for patients under 18
    if patient_age is not None and patient_age < 18:
        return None

    valid_candidates = []

    for candidate in candidates:

        context = candidate.get("context")

        if is_ignored_context(context):
            continue

        value = candidate.get("value")

        parsed = parse_blood_pressure(value)

        if not parsed:
            continue

        systolic, diastolic = parsed

        valid_candidates.append(
            {
                "value": value,
                "date": candidate.get("date"),
                "systolic": systolic,
                "diastolic": diastolic,
            }
        )

    if not valid_candidates:
        return None

    # If valid dates are available, choose the most recent.
    dated_candidates = []

    for candidate in valid_candidates:

        date_value = candidate.get("date")

        if not date_value:
            continue

        try:
            parsed_date = datetime.fromisoformat(
                date_value
            )

            candidate["parsed_date"] = parsed_date
            dated_candidates.append(candidate)

        except (ValueError, TypeError):
            continue

    if dated_candidates:

        dated_candidates.sort(
            key=lambda candidate: candidate["parsed_date"],
            reverse=True,
        )

        return dated_candidates[0]["value"]

    # If date cannot be determined,
    # choose the lowest BP.
    valid_candidates.sort(
        key=lambda candidate: (
            candidate["systolic"],
            candidate["diastolic"],
        )
    )

    return valid_candidates[0]["value"]


def select_hba1c(candidates: list) -> str | None:

    valid_values = []

    for candidate in candidates:

        context = candidate.get("context")

        if is_ignored_context(context):
            continue

        value = candidate.get("value")

        if value is None:
            continue

        try:
            numeric_value = float(value)

        except (ValueError, TypeError):
            continue

        valid_values.append(numeric_value)

    if not valid_values:
        return None

    # Assignment rule:
    # Multiple valid HbA1c values → choose lowest.
    lowest_value = min(valid_values)

    if lowest_value > 5.9:
        classification = "Diabetes"

    elif lowest_value > 5.7:
        classification = "Prediabetes"

    else:
        classification = "Normal"

    return f"{lowest_value}% ({classification})"


def get_measure_date(
    blood_pressure_candidates: list,
    hba1c_candidates: list,
    selected_blood_pressure: str | None,
    selected_hba1c: str | None,
):
    """
    Return the date associated with the selected measurement.
    """

    candidates = []

    if selected_blood_pressure:

        for candidate in blood_pressure_candidates:

            if (
                candidate.get("value")
                == selected_blood_pressure
            ):
                if candidate.get("date"):
                    candidates.append(
                        candidate["date"]
                    )

    if selected_hba1c:

        # Remove classification from stored value.
        selected_value = selected_hba1c.split("%")[0].strip()

        for candidate in hba1c_candidates:

            if str(candidate.get("value")) == selected_value:

                if candidate.get("date"):
                    candidates.append(
                        candidate["date"]
                    )

    if not candidates:
        return None

    valid_dates = []

    for date_value in candidates:

        try:
            parsed_date = datetime.fromisoformat(
                date_value
            )

            valid_dates.append(parsed_date)

        except (ValueError, TypeError):
            continue

    if not valid_dates:
        return None

    return max(valid_dates)


def calculate_confidence_score(
    measurements: dict,
    blood_pressure: str | None,
    hba1c: str | None,
    measure_date,
) -> float:

    score = 0

    patient_age = measurements.get("patient_age")

    bp_candidates = measurements.get(
        "blood_pressure",
        [],
    )

    hba1c_candidates = measurements.get(
        "hba1c",
        [],
    )

    # Valid BP extracted
    if blood_pressure:
        score += 30

        parsed_bp = parse_blood_pressure(
            blood_pressure
        )

        # Both systolic and diastolic exist
        if parsed_bp:
            score += 15

    # Valid HbA1c extracted
    if hba1c:
        score += 30

    # Patient age explicitly available
    if patient_age is not None:
        score += 10

    # Measurement date available
    if measure_date:
        score += 10

    # Ensure score remains between 0 and 100
    return min(score, 100.0)