USE people_analytics_portfolio;

WITH CleanEmployees AS (
    -- De-duplicate to keep only the latest record per employee
    SELECT * 
    FROM (
        SELECT *,
              ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY hire_date DESC) as row_num
        FROM employees
    ) t
    WHERE row_num = 1
),
StandardizedEmployees AS (
    -- Standardize text formats, cast types, and filter out bad data/nulls
    SELECT 
        employee_id,
        department_id,
        TRIM(management_tier) AS management_tier,
        CAST(base_salary AS DECIMAL(10,2)) AS base_salary,
        CAST(performance_rating AS UNSIGNED) AS performance_rating,
        CAST(age AS UNSIGNED) AS age,
        hire_date,
        termination_date,
        TRIM(employment_status) AS employment_status,
        DATEDIFF(IFNULL(termination_date, CURRENT_DATE()), hire_date) / 365 AS tenure_years
    FROM CleanEmployees
    WHERE employee_id IS NOT NULL
      AND base_salary >= 0 
      AND age BETWEEN 16 AND 100
      AND performance_rating >= 0
      AND (termination_date IS NULL OR termination_date >= hire_date)
),
CleanSurveys AS (
    -- De-duplicate surveys to get the latest unique response per employee
    SELECT * 
    FROM (
        SELECT *,
              ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY survey_date DESC) as row_num
        FROM engagement_surveys
    ) t
    WHERE row_num = 1
),
StandardizedSurveys AS (
    -- Clean survey metrics and handle boundaries
    SELECT 
        employee_id,
        CAST(engagement_score AS DECIMAL(3,2)) AS engagement_score,
        CAST(manager_satisfaction AS DECIMAL(3,2)) AS manager_satisfaction,
        CAST(work_life_balance_score AS DECIMAL(3,2)) AS work_life_balance_score
    FROM CleanSurveys
    WHERE employee_id IS NOT NULL
      AND (engagement_score IS NULL OR engagement_score BETWEEN 0 AND 10)
      AND (manager_satisfaction IS NULL OR manager_satisfaction BETWEEN 0 AND 10)
      AND (work_life_balance_score IS NULL OR work_life_balance_score BETWEEN 0 AND 10)
),
EnrichedEmployees AS (
    SELECT 
        e.employee_id,
        e.base_salary,
        e.performance_rating,
        e.tenure_years,
        e.age,
        s.engagement_score,
        s.manager_satisfaction,
        s.work_life_balance_score,
        CASE 
            WHEN e.employment_status IN ('Terminated', 'Resigned') THEN 1 
            ELSE 0 
        END AS is_attrition,
        -- Calculate Comp-Ratio relative to Department & Management Tier median/average benchmark
        e.base_salary / NULLIF(AVG(e.base_salary) OVER (PARTITION BY e.department_id, e.management_tier), 0) AS comp_ratio,
        -- Estimate Replacement Cost (heuristic: 40% of base salary)
        e.base_salary * 0.40 AS estimated_replacement_cost,
        -- Classify Tenure Cohorts for retention stage analysis
        CASE 
            WHEN e.tenure_years < 1 THEN '0-1 Year (Onboarding)'
            WHEN e.tenure_years BETWEEN 1 AND 3 THEN '1-3 Years (Mid-Tenure)'
            ELSE '3+ Years (Tenured)'
        END AS tenure_cohort,
        -- Flag high flight risk (High performer + Low engagement)
        CASE 
            WHEN e.performance_rating >= 4 AND s.engagement_score < 5 THEN 1 
            ELSE 0 
        END AS flight_risk_flag
    FROM StandardizedEmployees e
    LEFT JOIN StandardizedSurveys s ON e.employee_id = s.employee_id
)

SELECT 
    base_salary,
    performance_rating,
    ROUND(tenure_years, 2) AS tenure_years,
    age,
    engagement_score,
    manager_satisfaction,
    work_life_balance_score,
    is_attrition,
    ROUND(comp_ratio, 3) AS comp_ratio,
    estimated_replacement_cost,
    tenure_cohort,
    flight_risk_flag
FROM EnrichedEmployees;