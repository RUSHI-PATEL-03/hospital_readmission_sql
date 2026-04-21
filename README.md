#🏥 Hospital Readmission Risk Analysis — SQL Project

> **"47% of 25,000 patients were readmitted. This project finds out why and who's next."**

[![SQL](https://img.shields.io/badge/Language-SQL-blue?style=flat-square&logo=postgresql)](https://www.postgresql.org/)
[![Database](https://img.shields.io/badge/Database-PostgreSQL-336791?style=flat-square&logo=postgresql)](https://www.postgresql.org/)
[![Tool](https://img.shields.io/badge/Tool-pgAdmin%204-darkblue?style=flat-square)](https://www.pgadmin.org/)
[![Status](https://img.shields.io/badge/Status-Complete-brightgreen?style=flat-square)]()


## 📌 Project Overview

Hospital readmissions within 30 days are a critical metric in healthcare both for patient outcomes and hospital costs. This project dives deep into **25,000 patient records** using PostgreSQL to uncover which patients are at highest risk of being readmitted, and why.

Rather than just counting readmissions, this analysis builds a **multi-lens view** from age and medication patterns to diabetes treatment gaps and medical specialty profiles the kind of insight that drives real clinical decisions.

## 🎯 Business Problem

> Preventable hospital readmissions cost the U.S. healthcare system **billions annually** and signal gaps in care quality.

**The core questions this project answers:**
- Which patient segments carry the highest readmission risk?
- Does more treatment (medications, lab procedures, longer stays) actually reduce readmissions?
- Are diabetes patients being managed effectively before discharge?
- Which diagnoses and specialties are the biggest contributors?

---

## 📊 Key Findings at a Glance

| # | Finding | Insight |
|---|---------|---------|
| 1 | **47% overall readmission rate** (11,754 / 25,000) | Nearly 1 in 2 patients returns a systemic problem |
| 2 | **Age 80–90 has the highest readmission rate (49%)** | Elderly patients are being discharged too early or without adequate follow up |
| 3 | **Patients with 21–30 medications: 52.39% readmission rate** | Polypharmacy signals severity not better management |
| 4 | **Inpatient-dominant visit history → 59.94% readmission** | Repeat inpatient visitors are the highest risk group |
| 5 | **Respiratory diagnoses top the readmission chart (49.2%)** | Respiratory conditions need stronger post discharge monitoring |
| 6 | **"No Change + High Glucose Ignored" → 57.39% readmit** | Untreated warning signs in diabetic patients directly drive readmission |
| 7 | **Longer hospital stays ≠ lower readmission** | 9–10 day stays show ~50–51% readmission duration alone isn't the solution |

---

## 🛠️ SQL Skills Demonstrated

This project deliberately showcases a range of **intermediate to advanced SQL techniques**:

```
✅ Common Table Expressions (CTEs)        ✅ Window Functions — RANK() OVER()
✅ Conditional Aggregation (FILTER)       ✅ CASE WHEN Bucketing / Segmentation
✅ UNION ALL for data unpivoting          ✅ Multi-CTE chained pipelines
✅ Type casting & ROUND() for precision   ✅ GROUP BY with computed columns
```

---

## 🔍 Query Highlights

### Q1 — Overall Readmission Rate
```sql
SELECT 
    COUNT(*) FILTER (WHERE readmitted = 'yes') AS readmitted,
    COUNT(*) FILTER (WHERE readmitted = 'no')  AS not_readmitted,
    COUNT(*) AS total_patients,
    (COUNT(*) FILTER (WHERE readmitted = 'yes') * 100 / COUNT(*)) AS readmitted_rate_percent
FROM readmissions;
-- Result: 11,754 readmitted | 13,246 not readmitted | 47% rate
```

---

### Q6 — Repeat Patient Behavior (Visit History Segmentation)
```sql
SELECT 
    CASE 
        WHEN n_inpatient = 0 AND n_outpatient = 0 AND n_emergency = 0 THEN 'no_prior_visits'
        WHEN n_inpatient >= n_outpatient AND n_inpatient >= n_emergency THEN 'inpatient_dominant'
        WHEN n_emergency >= n_outpatient THEN 'emergency_dominant'
        ELSE 'outpatient_dominant'
    END AS dominant_visit_type,
    COUNT(*) AS total_patients,
    COUNT(*) FILTER (WHERE readmitted = 'yes') AS readmitted_count,
    ROUND((COUNT(*) FILTER (WHERE readmitted = 'yes') * 100)::NUMERIC / COUNT(*)::NUMERIC, 2) AS readmitted_rate
FROM readmissions
GROUP BY 1
ORDER BY readmitted_rate;
-- inpatient_dominant: 59.94% | emergency_dominant: 58.25%
```

---

### Q8 — Diabetes Treatment Gap Analysis (Multi-CTE + Window Function)
```sql
WITH diabetes_patient AS (
    SELECT * FROM readmissions WHERE diabetes_med = 'yes'
),
treatment_profile AS (
    SELECT *, 
        CASE 
            WHEN change = 'yes' AND A1Ctest = 'high'   THEN 'Med changed and high A1C caught'
            WHEN change = 'no'  AND glucose_test = 'high' THEN 'No Change + High Glucose Ignored'
            ELSE 'No Change + No Flags'
        END AS treatment_grp
    FROM diabetes_patient
),
readmission_by_treatment AS (
    SELECT treatment_grp,
           COUNT(*) AS total_patients,
           COUNT(*) FILTER (WHERE readmitted = 'yes') AS readmitted_count,
           ROUND(COUNT(*) FILTER (WHERE readmitted = 'yes') * 100.0 / COUNT(*), 2) AS readmit_pct
    FROM treatment_profile GROUP BY treatment_grp
)
SELECT *, RANK() OVER (ORDER BY readmit_pct DESC) AS risk_rank
FROM readmission_by_treatment ORDER BY risk_rank;
-- "No Change + High Glucose Ignored" → 57.39% readmit (Rank #1 risk)
```

---

## 📂 Project Structure

```
hospital-readmission-sql/
│
├── README.md                    ← You are here
├── schema.sql                   ← Table creation & data types
├── Hospital_readmission.sql     ← All 9 analytical queries
├── data/
│   └── sample_data.csv          ← Sample anonymized dataset
└── visuals/
    └── Query_outputs.pdf        ← pgAdmin query screenshots with results
```

---

## 📈 Results Summary Table

| Query | Topic | Key Result |
|-------|-------|------------|
| Q1 | Overall Readmission Rate | **47%** (11,754 / 25,000) |
| Q2 | Age Group Risk | **80–90 yr → 49%** readmission |
| Q3 | Hospital Stay Duration | Peaks at **9–10 days → ~51%** |
| Q4 | Medication Volume | **21–30 meds → 52.39%** (highest) |
| Q5 | Lab Procedures | Higher volume → marginally higher risk |
| Q6 | Visit History Type | **Inpatient-dominant → 59.94%** |
| Q7 | Diagnosis Category | **Respiratory → 49.2%** (top risk) |
| Q8 | Diabetes Treatment Gaps | **High glucose ignored → 57.39%** |
| Q9 | Medical Specialty | **Family/General Practice → 49%** |

---

## 💡 Real-World Recommendations

Based on the analysis, here are actionable takeaways:

1. **Target inpatient dominant patients** for mandatory post discharge follow up programs
2. **Flag diabetic patients** where glucose/A1C results are elevated but medications were not adjusted, they have the highest preventable readmission risk
3. **Strengthen respiratory care protocols** — this diagnosis group consistently tops readmission charts
4. **Review elderly discharge processes** (80–90 age group) — nearly 1 in 2 is returning within 30 days
5. **Don't assume longer stays = better outcomes** — the data shows no protective effect of extended hospitalization alone

---

## 🚀 How to Run This Project

**Prerequisites:** PostgreSQL + pgAdmin 4 (or any SQL client)

```bash
# Step 1: Create the database
CREATE DATABASE hospital_readmission;

# Step 2: Run schema creation
-- Execute schema.sql to create the readmissions table

# Step 3: Load data
-- Import sample_data.csv via pgAdmin Import/Export tool
-- OR use: COPY readmissions FROM '/path/to/sample_data.csv' CSV HEADER;

# Step 4: Run queries
-- Execute Hospital_readmission.sql query by query
```

---

## 📚 Dataset

- **Size:** 25,000 patient records
- **Note:** Data has been preprocessed and anonymized. No real patient identifiers are included.

---

## 👤 About Me

I'm a data analyst passionate about using SQL to turn raw data into decisions. This project reflects my ability to work with real-world messy datasets, ask the right business questions, and translate query results into actionable insights.

📫 Connect with me on https://www.linkedin.com/in/rushi-patel-a3a787304/

---

> ⭐ *If you found this project useful or interesting, feel free to star the repo!*
