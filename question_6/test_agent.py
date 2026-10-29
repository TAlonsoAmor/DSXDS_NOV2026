"""Three example queries against the ClinicalTrialDataAgent."""

import os
from agent import ClinicalTrialDataAgent

DATA_PATH = os.path.join(os.path.dirname(__file__), "../question_5/adae.csv")

agent = ClinicalTrialDataAgent(DATA_PATH)

QUERIES = [
    "Give me the subjects who had Adverse events of Moderate severity",
    "Which subjects experienced cardiac adverse events?",
    "How many subjects had a MILD adverse event?",
]

for question in QUERIES:
    print(f"\nQ: {question}")
    result = agent.query(question)
    print(f"   Filter applied : {result['filter']}")
    print(f"   Subject count  : {result['subject_count']}")
    print(f"   Subjects       : {result['subjects']}")
