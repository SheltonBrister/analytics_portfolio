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
)

SELECT 
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
    END AS is_attrition
FROM StandardizedEmployees e
LEFT JOIN StandardizedSurveys s ON e.employee_id = s.employee_id;