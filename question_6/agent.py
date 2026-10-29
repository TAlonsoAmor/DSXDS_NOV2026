"""
ClinicalTrialDataAgent — GenAI assistant (mocked LLM).

The full Prompt → Parse → Execute flow is implemented.
The LLM step is mocked with keyword-based parsing so no API key is needed.
Swapping _mock_llm_call() for a real openai.chat.completions.create() call
would make this production-ready without changing anything else.
"""

import json
import re
import pandas as pd

# ---------------------------------------------------------------------------
# Schema exposed to the LLM (and used by the mock parser)
# ---------------------------------------------------------------------------
SCHEMA = {
    "AESEV": "Adverse event severity / intensity (values: MILD, MODERATE, SEVERE)",
    "AETERM": "Specific adverse event term / condition (e.g. HEADACHE, FATIGUE)",
    "AESOC": "Body system / System Organ Class (e.g. CARDIAC DISORDERS, SKIN AND SUBCUTANEOUS TISSUE DISORDERS)",
}

SYSTEM_PROMPT = f"""
You are a clinical-trial data assistant. Given a natural-language question about
adverse events, return ONLY a JSON object with two keys:
  "target_column" — one of {list(SCHEMA.keys())}
  "filter_value"  — the value to filter on (uppercase)

Schema:
{json.dumps(SCHEMA, indent=2)}

Example output:
{{"target_column": "AESEV", "filter_value": "MODERATE"}}
""".strip()


# ---------------------------------------------------------------------------
# Mock LLM — keyword rules that mirror what the real model would produce
# ---------------------------------------------------------------------------
def _mock_llm_call(user_question: str) -> str:
    """Return the JSON string a real LLM would produce for this question."""
    q = user_question.upper()

    # AESEV keywords
    for severity in ("MILD", "MODERATE", "SEVERE"):
        if severity in q:
            return json.dumps({"target_column": "AESEV", "filter_value": severity})
    if re.search(r"\bSEVERITY\b|\bINTENSITY\b", q):
        # default to MODERATE when no specific value mentioned
        return json.dumps({"target_column": "AESEV", "filter_value": "MODERATE"})

    # AESOC keywords
    soc_map = {
        "CARDIAC": "CARDIAC DISORDERS",
        "HEART": "CARDIAC DISORDERS",
        "SKIN": "SKIN AND SUBCUTANEOUS TISSUE DISORDERS",
        "GASTROINTESTINAL": "GASTROINTESTINAL DISORDERS",
        "GI": "GASTROINTESTINAL DISORDERS",
        "RESPIRATORY": "RESPIRATORY, THORACIC AND MEDIASTINAL DISORDERS",
        "MUSCULOSKELETAL": "MUSCULOSKELETAL AND CONNECTIVE TISSUE DISORDERS",
        "RENAL": "RENAL AND URINARY DISORDERS",
        "INFECTION": "INFECTIONS AND INFESTATIONS",
    }
    for keyword, soc_value in soc_map.items():
        if keyword in q:
            return json.dumps({"target_column": "AESOC", "filter_value": soc_value})

    # AETERM — fall back to treating free text as a specific term
    # extract capitalised noun after common trigger phrases
    match = re.search(
        r"(?:CONDITION|TERM|EVENT|CALLED|NAMED|DIAGNOSED WITH|SUFFERING FROM)\s+([A-Z ]+?)(?:\s+AND|\s+OR|$)",
        q,
    )
    if match:
        return json.dumps({"target_column": "AETERM", "filter_value": match.group(1).strip()})

    raise ValueError(f"Could not parse question: {user_question!r}")


# ---------------------------------------------------------------------------
# Agent
# ---------------------------------------------------------------------------
class ClinicalTrialDataAgent:
    def __init__(self, data_path: str):
        self.df = pd.read_csv(data_path, index_col=0)

    def _build_prompt(self, question: str) -> str:
        return f"{SYSTEM_PROMPT}\n\nUser question: {question}"

    def _call_llm(self, prompt: str) -> str:
        # Replace this body with a real API call when a key is available:
        #   import openai
        #   response = openai.chat.completions.create(
        #       model="gpt-4o-mini",
        #       messages=[{"role": "user", "content": prompt}],
        #   )
        #   return response.choices[0].message.content
        user_question = prompt.split("User question:")[-1].strip()
        return _mock_llm_call(user_question)

    def _parse_response(self, llm_output: str) -> dict:
        match = re.search(r"\{.*?\}", llm_output, re.DOTALL)
        if not match:
            raise ValueError(f"No JSON found in LLM output: {llm_output!r}")
        return json.loads(match.group())

    def _execute(self, parsed: dict) -> dict:
        col = parsed["target_column"]
        val = parsed["filter_value"]
        if col not in self.df.columns:
            raise ValueError(f"Column {col!r} not in dataset")
        mask = self.df[col].str.upper() == val.upper()
        subjects = self.df.loc[mask, "USUBJID"].unique().tolist()
        return {"filter": parsed, "subject_count": len(subjects), "subjects": subjects}

    def query(self, question: str) -> dict:
        prompt = self._build_prompt(question)
        llm_output = self._call_llm(prompt)
        parsed = self._parse_response(llm_output)
        return self._execute(parsed)
