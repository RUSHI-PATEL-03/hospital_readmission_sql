create table readmissions 
(
age varchar(50),
time_in_hospital int,
n_lab_procedures int,
n_procedures int,
n_medications int,
n_outpatient int,
n_inpatient int,
n_emergency int, 
medical_specialty varchar(60),
diag_1 varchar(50),
diag_2 varchar(50),
diag_3 varchar(50),
glucose_test varchar(10),
A1Ctest varchar(50), 
change varchar(50),
diabetes_med varchar(50),
readmitted varchar(30)
);

drop table if exists readmissions;

--data cleaning:- check for nulls

select * from readmissions as r
where r is null;

SELECT * FROM readmissions as r WHERE r is not null;


--1) What is the overall readmission rate?

select 
       count(*) filter (where readmitted = 'yes') as readmitted,
	   count(*) filter (where readmitted = 'no') as not_readmitted,
	   count(*) as total_patients,
	   (count(*) filter (where readmitted = 'yes') *100 /count(*)) as readmitted_rate_percent
from readmissions

--2) Which age group has the highest readmission rate?
--Insight angle: Risk segmentation

select age, 
       count(*) filter (where readmitted = 'yes') as total_readmission_patient,
       (count(*) filter (where readmitted = 'yes') *100 /count(*)) as readmitted_rate_percent
from readmissions
group by 1 
order by readmitted_rate_percent desc 


--3) Does hospital stay duration impact readmission?
-- Insight: Longer stay ≠ better recovery?

select time_in_hospital, 
       count(*) as total_pateint, 
	   count(*) filter (where readmitted = 'yes') as readmissions, 
	   round(((count(*) filter (where readmitted = 'yes') *100)::numeric / (count(*)::numeric)), 2) as readmitted_rate_percent
from readmissions
group by time_in_hospital
order by 1 desc


--4) Do more medications increase readmission risk?
-- Insight: Over-medication vs severity (harsh, seriousness)

select
       case when n_medications between 0 and 10 then '0-10'
	        when n_medications between 11 and 20 then '11-20'
	        when n_medications between 21 and 30 then '21-30'
	        when n_medications between 31 and 40 then '31-40'
	        when n_medications between 41 and 50 then '41-50'
	   else '50+'
       end as Medications_grp,
	   count(*) as total_patients,
       count(*) filter (where readmitted = 'yes') as readmitted_patients,
	   round(((count(*) filter (where readmitted = 'yes') *100)::numeric / (count(*)::numeric)), 2) as readmitted_rate_percentage
from readmissions

group by Medications_grp
order by Medications_grp 


--5) Are lab procedures linked to readmission
-- Insight: Intensive treatment correlation

select case 
            when n_lab_procedures between 0 and 10 then '0-10'
			when n_lab_procedures between 11 and 20 then '11-20'
			when n_lab_procedures between 21 and 30 then '21-30'
			when n_lab_procedures between 31 and 40 then '31-40'
			when n_lab_procedures between 41 and 50 then '41-50'
			when n_lab_procedures between 51 and 60 then '51-60'
			when n_lab_procedures between 61 and 70 then '61-70'
			when n_lab_procedures between 71 and 80 then '71-80'
			when n_lab_procedures between 81 and 90 then '81-90'
			else '90+'
	   end as lab_procedures_grps, 
	   count(*) as total_patients,
	   count(*) filter (where readmitted = 'yes') as readmitted_patients,
	   round(((count(*) filter (where readmitted = 'yes') *100)::numeric / (count(*)::numeric)), 2) as readmitted_rate_percentage
from readmissions
group by lab_procedures_grps
order by lab_procedures_grps


--6) Which patients (based on past visits) are most likely to return?
--Insight: Repeat patient behavior

select case 
 		   when n_inpatient = 0 and n_outpatient = 0 and n_emergency = 0 then 'no_prior_visits'
		   WHEN n_inpatient >= n_outpatient 
           AND n_inpatient >= n_emergency  THEN 'inpatient_dominant'
           WHEN n_emergency >= n_outpatient THEN 'emergency_dominant'
           ELSE 'outpatient_dominant'
       end as dominant_visit_type,
	   count(*) as total_patients,
	   count(*) filter (where readmitted = 'yes') as readmitted_count,
	   round((count(*) filter (where readmitted = 'yes') * 100) ::numeric / (count(*) ::numeric),2) as readmitted_rate  
from readmissions
group by 1
order by readmitted_rate



--Q7) Which diagnoses are most associated with readmission?
--👉 Insight: Medical root cause

with all_diagnosis as (
 		SELECT diag_1 AS diagnosis, readmitted FROM readmissions
		union all
		select diag_2, readmitted from readmissions
 		union all 
		select diag_3, readmitted from readmissions
)

select diagnosis,
       COUNT(*) AS total_patients,
       COUNT(*) FILTER (WHERE readmitted = 'yes') AS readmitted_patients,
       ROUND(COUNT(*) FILTER (WHERE readmitted = 'yes') * 100.0 / COUNT(*), 2) AS readmission_rate
from all_diagnosis
group by diagnosis
order by readmission_rate

--Q8) Are patients whose diabetes medication was changed less likely to return?

with diabetes_patient as (
                          select * from readmissions
                          where diabetes_med = 'yes'
),

treatment_profile as (
        SELECT
        diabetes_med,
        change,
        A1Ctest,
        glucose_test,
        readmitted,
		case 
		    when change = 'yes' and A1Ctest = 'high' then 'Med changed and high A1C caught'
			when change = 'yes' and A1Ctest = 'normal' then 'Med changed and normal A1C'
			when change = 'yes' and A1Ctest = 'no' then 'Med changed and AIC Not Tested' 
			when change = 'no' and A1Ctest = 'high' then 'No Med changed and high A1C ignored'
            when change = 'no' and glucose_test = 'high' THEN 'No Change + High Glucose Ignored'
            ELSE 'No Change + No Flags'
		end as treatment_grp
		from diabetes_patient
),
	
readmission_by_treatment AS (
                             SELECT
             				 treatment_grp,
       	 				 	 count(*) AS total_patients,
        					 count(*) FILTER (WHERE readmitted = 'yes') AS readmitted_count,
        					 round(count(*) FILTER (WHERE readmitted = 'yes')* 100.0 / count(*), 2) AS readmit_pct
    FROM treatment_profile
    GROUP BY treatment_grp
)
SELECT
    treatment_grp,
    total_patients,
    readmitted_count,
    readmit_pct,
    RANK() OVER (ORDER BY readmit_pct DESC) AS risk_rank
FROM readmission_by_treatment
ORDER BY risk_rank;

--9) Which medical specialty has the most severe patients and highest readmission?

select medical_specialty,n_medications, time_in_hospital, 

with specialty_metrics as (
		  select medical_specialty,
		  round(avg(time_in_hospital)) as avg_stay_in_hospital,
		  round(avg(n_lab_procedures)) as avg_lab_procedures,
		  round(avg(n_procedures)) as avg_procedures,
		  round(avg(n_medications)) as avg_medications,
		  count(*) filter (where readmitted = 'yes') as readmitted_patients,
		  round(count(*) filter (where readmitted = 'yes') * 100 / count(*),2) as readmitted_patients_rate
		  from readmissions
		group by 1
),

ranked_specialties as (
SELECT *,
rank () over (order by readmitted_patients_rate ) as readmit_rank,
rank () over (order by avg_stay_in_hospital ) as severity_rank
FROM specialty_metrics
)

select * 
from ranked_specialties
order by 1

--10) Multi-factor risk analysis (ADVANCED – THIS IS GOLD)
--👉 Insight: Combine features → real-world thinking