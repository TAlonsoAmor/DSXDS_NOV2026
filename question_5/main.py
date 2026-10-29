from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional, List
import pandas as pd
import os

# Initialize FastAPI app
app = FastAPI(title="Clinical Trial Data API")

# Load the data (assuming adae.csv is in the same directory)
DATA_FILE = "./adae.csv"

# Global variable to store the dataframe
df = None

# Load data on startup
@app.on_event("startup")
async def load_data():
    global df
    if not os.path.exists(DATA_FILE):
        raise FileNotFoundError(f"{DATA_FILE} not found. Please ensure it exists.")
    df = pd.read_csv(DATA_FILE)
    print(f"Loaded {len(df)} records from {DATA_FILE}")


# ============================================================================
# REQUEST/RESPONSE MODELS
# ============================================================================

class AEQueryRequest(BaseModel):
    """Request model for POST /ae-query"""
    severity: Optional[List[str]] = None
    treatment_arm: Optional[str] = None

    class Config:
        schema_extra = {
            "example": {
                "severity": ["MILD", "MODERATE"],
                "treatment_arm": "Placebo"
            }
        }


class AEQueryResponse(BaseModel):
    """Response model for POST /ae-query"""
    count: int
    unique_subjects: List[str]


class SubjectRiskResponse(BaseModel):
    """Response model for GET /subject-risk/{subject_id}"""
    subject_id: str
    risk_score: int
    risk_category: str


# ============================================================================
# ENDPOINTS
# ============================================================================

@app.get("/")
async def root():
    """Health check endpoint"""
    return {"message": "Clinical Trial Data API is running"}


@app.post("/ae-query", response_model=AEQueryResponse)
async def ae_query(request: AEQueryRequest):
    """
    Dynamic filtering of adverse events.
    
    - Filter by severity (AESEV) and/or treatment arm (ACTARM)
    - Null/missing filters are ignored
    - Returns count and unique subject IDs
    """
    # Start with full dataset
    filtered_df = df.copy()
    
    # Apply severity filter if provided
    if request.severity is not None and len(request.severity) > 0:
        filtered_df = filtered_df[filtered_df['AESEV'].isin(request.severity)]
    
    # Apply treatment arm filter if provided
    if request.treatment_arm is not None:
        filtered_df = filtered_df[filtered_df['ACTARM'] == request.treatment_arm]
    
    # Get unique subject IDs
    unique_subjects = filtered_df['USUBJID'].unique().tolist()
    
    return AEQueryResponse(
        count=len(filtered_df),
        unique_subjects=unique_subjects
    )


@app.get("/subject-risk/{subject_id}", response_model=SubjectRiskResponse)
async def subject_risk(subject_id: str):
    """
    Calculate risk score for a specific subject.
    
    Risk scoring:
    - MILD = 1 point
    - MODERATE = 3 points
    - SEVERE = 5 points
    
    Risk categories:
    - Low: score < 5
    - Medium: 5 <= score <= 14
    - High: score >= 15
    """
    # Filter data for this subject
    subject_df = df[df['USUBJID'] == subject_id]
    
    # Check if subject exists
    if len(subject_df) == 0:
        raise HTTPException(status_code=404, detail=f"Subject {subject_id} not found")
    
    # Define severity weights
    severity_weights = {
        'MILD': 1,
        'MODERATE': 3,
        'SEVERE': 5
    }
    
    # Calculate risk score
    risk_score = 0
    for _, row in subject_df.iterrows():
        severity = row['AESEV']
        risk_score += severity_weights.get(severity, 0)
    
    # Determine risk category
    if risk_score < 5:
        risk_category = "Low"
    elif risk_score <= 14:
        risk_category = "Medium"
    else:
        risk_category = "High"
    
    return SubjectRiskResponse(
        subject_id=subject_id,
        risk_score=risk_score,
        risk_category=risk_category
    )