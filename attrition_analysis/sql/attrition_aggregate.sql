USE people_analytics_portfolio;

WITH CleanEmployees AS (
    SELECT *
    FROM (
        SELECT *,
              ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY hire_date DESC) as row_num
        FROM employees
    ) t
    WHERE row_num = 1
),
StandardizedEmployees AS (
    SELECT
        employee_id,
        TRIM(first_name) AS first_name,
        TRIM(last_name) AS last_name,
        department_id,
        TRIM(management_tier) AS management_tier,
        TRIM(job_title) AS job_title,
        CAST(base_salary AS DECIMAL(10,2)) AS base_salary,
        CAST(performance_rating AS UNSIGNED) AS performance_rating,
        TRIM(gender) AS gender,
        TRIM(ethnicity) AS ethnicity,
        CAST(age AS UNSIGNED) AS age,
        TRIM(employment_status) AS employment_status,
        hire_date,
        termination_date,
        DATEDIFF(IFNULL(termination_date, CURRENT_DATE()), hire_date) / 365 AS tenure_years
    FROM CleanEmployees
    WHERE employee_id IS NOT NULL
      -- Relaxed or handled via imputation/safe defaults if needed, 
      -- but keeping core integrity checks:
      AND base_salary >= 0
      AND (age BETWEEN 18 AND 100 OR age IS NULL)
      AND (termination_date IS NULL OR termination_date >= hire_date)
),
CleanDepartments AS (
    SELECT 
        department_id,
        TRIM(department_name) AS department_name
    FROM (
        SELECT *,
              ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY department_name) as row_num
        FROM departments
    ) t
    WHERE row_num = 1 
      AND department_id IS NOT NULL
      AND department_name IS NOT NULL
),
CleanSurveys AS (
    SELECT * 
    FROM (
        SELECT *,
              ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY survey_date DESC) as row_num
        FROM engagement_surveys
    ) t
    WHERE row_num = 1
),
StandardizedSurveys AS (
    SELECT 
        employee_id,
        CAST(engagement_score AS DECIMAL(3,2)) AS engagement_score,
        CAST(manager_satisfaction AS DECIMAL(3,2)) AS manager_satisfaction
    FROM CleanSurveys
    WHERE employee_id IS NOT NULL
),
EmployeeMetrics AS (
    SELECT
        e.employee_id,
        CONCAT(e.first_name, ' ', e.last_name) AS full_name,
        COALESCE(d.department_name, 'Unassigned') AS department_name, -- Prevents dropping rows if department is missing
        e.management_tier,
        e.job_title,
        e.base_salary,
        e.performance_rating,
        e.gender,
        e.ethnicity,
        e.age,
        e.employment_status,
        e.tenure_years,
        s.engagement_score,
        s.manager_satisfaction,
        CASE WHEN e.employment_status IN ('Terminated', 'Resigned') THEN 1 ELSE 0 END AS is_attrition,
        e.base_salary * 0.40 AS estimated_replacement_cost,
        CASE WHEN e.performance_rating >= 4 AND s.engagement_score < 5 THEN 1 ELSE 0 END AS flight_risk_flag
    FROM StandardizedEmployees e
    LEFT JOIN CleanDepartments d ON e.department_id = d.department_id -- Changed from INNER JOIN to LEFT JOIN
    LEFT JOIN StandardizedSurveys s ON e.employee_id = s.employee_id
),
DepartmentAggregates AS (
    SELECT
        department_name,
        management_tier,
        COUNT(DISTINCT employee_id) AS total_headcount,
        SUM(is_attrition) AS total_attrition_count,
        ROUND(AVG(is_attrition) * 100, 2) AS attrition_rate_pct,
        ROUND(AVG(base_salary), 2) AS avg_base_salary,
        SUM(estimated_replacement_cost) AS total_turnover_cost_exposure,
        ROUND(AVG(tenure_years), 2) AS avg_tenure_years,
        ROUND(AVG(performance_rating), 2) AS avg_performance_rating,
        ROUND(AVG(engagement_score), 2) AS avg_engagement_score,
        ROUND(AVG(manager_satisfaction), 2) AS avg_manager_satisfaction,
        SUM(flight_risk_flag) AS high_flight_risk_count
    FROM EmployeeMetrics
    GROUP BY department_name, management_tier
)
SELECT *
FROM DepartmentAggregates
ORDER BY attrition_rate_pct DESC, total_headcount DESC;