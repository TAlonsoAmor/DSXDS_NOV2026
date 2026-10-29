#!/bin/bash

echo "=== Test 1: Root endpoint ==="
curl http://127.0.0.1:8000/
echo -e "\n"

echo "=== Test 2: All AE records ==="
curl -X POST "http://127.0.0.1:8000/ae-query" \
  -H "Content-Type: application/json" \
  -d '{}'
echo -e "\n"

echo "=== Test 3: Filter by severity ==="
echo "Example severity: MILD"
curl -X POST "http://127.0.0.1:8000/ae-query" \
  -H "Content-Type: application/json" \
  -d '{"severity": ["MILD"]}'
echo -e "\n"

echo "=== Test 4: Filter by severity and treatment arm ==="
echo "Example severity: MILD, MODERATE; Treatment Arm: Placebo"
curl -X POST "http://127.0.0.1:8000/ae-query" \
  -H "Content-Type: application/json" \
  -d '{"severity": ["MILD", "MODERATE"], "treatment_arm": "Placebo"}'
echo -e "\n"

echo "=== Test 5: Subject risk  ==="
echo "Example Patient 01-701-1015."
echo "Patient has 3 events all of MILD severity."
echo "Should return a risk score of 3 and a risk category: Low"
curl http://127.0.0.1:8000/subject-risk/01-701-1015
echo -e "\n"

echo "=== Test 6: Subject risk for incorrect USUBJID  ==="
echo "Testing participant with  USUBJID = 1234"
curl -i http://127.0.0.1:8000/subject-risk/1234
echo -e "\n"