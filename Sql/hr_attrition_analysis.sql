-- Creating Database structure with Constraints.

CREATE DATABASE attrition_db;

USE attrition_db;

-- Creating Dimension Tables

CREATE TABLE dim_employee (
    employee_id INT PRIMARY KEY,
    age INT,
    gender VARCHAR(10),
    marital_status VARCHAR(15),
    education INT,
    education_field VARCHAR(50)
);

CREATE TABLE dim_job (
    job_id INT PRIMARY KEY,
    employee_id INT,
    department VARCHAR(50),
    job_role VARCHAR(50),
    job_level INT,
    job_satisfaction INT
);

CREATE TABLE dim_work_conditions (
    condition_id INT PRIMARY KEY,
    employee_id INT,
    overtime VARCHAR(5),
    business_travel VARCHAR(20),
    distance_from_home INT,
    environment_satisfaction INT,
    work_life_balance INT
);


CREATE TABLE dim_performance (
    performance_id INT PRIMARY KEY,
    employee_id INT,
    performance_rating INT,
    total_working_years INT,
    training_times_last_year INT,
    years_in_current_role INT,
    years_with_curr_manager INT
);

CREATE TABLE fact_attrition (
    employee_id INT PRIMARY KEY,
    job_id INT,
    condition_id INT,
    performance_id INT,
    attrition VARCHAR(5),
    monthly_income INT,
    daily_rate INT,
    percent_salary_hike INT,
    years_at_company INT,
    years_since_last_promotion INT,
    FOREIGN KEY (employee_id) REFERENCES dim_employee(employee_id),
    FOREIGN KEY (job_id) REFERENCES dim_job(job_id),
    FOREIGN KEY (condition_id) REFERENCES dim_work_conditions(condition_id),
    FOREIGN KEY (performance_id) REFERENCES dim_performance(performance_id)
);

-- Deep Analysis

SELECT
	*
FROM
	fact_attrition;

SELECT
	employee_id,
	COUNT(*) AS all_transactions 
FROM
	fact_attrition
GROUP BY employee_id
HAVING COUNT(*) > 2;
    
SELECT
	*
FROM
	fact_attrition
WHERE employee_id IS NULL;
    
SELECT
	*
FROM
	dim_employee;
    
SELECT
	*
FROM
	dim_performance;
    
SELECT
	*
FROM
	dim_work_conditions;
    
SELECT
	*
FROM
	dim_job;
    
-- Overall attrition rate

SELECT
	COUNT(*) AS total_employees,
    ROUND(SUM(CASE WHEN attrition = "Yes" THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS att_rate
FROM
	fact_attrition;
    
-- the overall attrition rate is at 16.12%.
    
-- Attrition Rate by Dept

SELECT
	j.department,
    SUM(CASE WHEN f.attrition = 'Yes' THEN 1 ELSE 0 END) AS attrited,
    ROUND(SUM(CASE WHEN f.attrition = "Yes" THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS att_rate
FROM
	dim_job j
    JOIN
    fact_attrition f ON j.job_id = f.job_id
GROUP BY j.department
ORDER BY att_rate DESC;

-- the sales dept has the highest att rate with 20.63% whereas the r&d has the lowest.


-- Attrition rate by job role

SELECT
	j.job_role,
    SUM(CASE WHEN f.attrition = 'Yes' THEN 1 ELSE 0 END) AS attrited,
    ROUND(SUM(CASE WHEN f.attrition = "Yes" THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS att_rate
FROM
	dim_job j 
    JOIN
    fact_attrition f ON j.job_id = f.job_id
GROUP BY j.job_role
ORDER BY att_rate DESC;

-- low level jobs like sales rep and lab tech has the lowest att_rate.

SELECT
	CASE WHEN attrition = "Yes" THEN "Attrited" ELSE "Stayed" END AS employee_status,
    AVG(monthly_income) AS avg_monthly_income
FROM
	fact_attrition
GROUP BY employee_status
ORDER BY avg_monthly_income DESC;

-- data clearly shows the employees who got attrited have a lower average monthly income than employee who stayed which may be one of the driving forces for attrition.alter


-- attrition by overtime

SELECT 
    w.overtime,
    COUNT(*) AS total_employees,
    SUM(CASE WHEN f.attrition = 'Yes' THEN 1 ELSE 0 END) AS attrited,
    ROUND(SUM(CASE WHEN f.attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS attrition_rate
FROM fact_attrition f
JOIN dim_work_conditions w ON f.condition_id = w.condition_id
GROUP BY w.overtime;

-- Data shows people working overtime have a higher attrition rate than people who dont work overtime


-- attrition by gender

SELECT
	e.gender,
	SUM(CASE WHEN f.attrition = 'Yes' THEN 1 ELSE 0 END) AS attrited,
	ROUND(SUM(CASE WHEN f.attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS attrition_rate
FROM
	dim_employee e
    JOIN
    fact_attrition f ON e.employee_id = f.employee_id
GROUP BY e.gender
ORDER BY attrition_rate DESC;

-- the difference is minimal but data shows male employees tend to be attrited more than female employees. 

-- Attrition by Business Travel

SELECT 
    w.business_travel,
    COUNT(*) AS total_employees,
    SUM(CASE WHEN f.attrition = 'Yes' THEN 1 ELSE 0 END) AS attrited,
    ROUND(SUM(CASE WHEN f.attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS attrition_rate
FROM fact_attrition f
JOIN dim_work_conditions w ON f.condition_id = w.condition_id
GROUP BY w.business_travel
ORDER BY attrition_rate DESC;

-- Employees traveling frequently tend to be attrited more than employee who dont travel.


-- High Risk employees

SELECT 
    f.employee_id,
    e.age,
    e.gender,
    j.job_role,
    j.department,
    f.monthly_income,
    w.overtime,
    p.years_in_current_role,
    f.years_since_last_promotion
FROM fact_attrition f
JOIN dim_employee e ON f.employee_id = e.employee_id
JOIN dim_job j ON f.job_id = j.job_id
JOIN dim_work_conditions w ON f.condition_id = w.condition_id
JOIN dim_performance p ON f.performance_id = p.performance_id
WHERE f.attrition = 'Yes'
    AND w.overtime = 'Yes'
    AND f.monthly_income < 3000
    AND f.years_since_last_promotion > 3
ORDER BY f.years_since_last_promotion DESC;


-- Attrition by marital status

SELECT
	e.marital_status,
    SUM(CASE WHEN f.attrition = "Yes" THEN 1 ELSE 0 END) AS total_attrited,
	ROUND(SUM(CASE WHEN f.attrition = "Yes" THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS att_rate
FROM
	dim_employee e 
    JOIN
    fact_attrition f ON e.employee_id = f.employee_id
GROUP BY e.marital_status
ORDER BY att_rate DESC;

-- Unmarried employees tend to have a higher attrition rate compared to the others, as no responsibilty factor is considered
-- whereas the married and divorced employees have a higher attrition rate may because of the responsibility factor.

-- Attrition rate by work life balance

SELECT 
    w.work_life_balance,
    COUNT(*) AS total_employees,
    SUM(CASE WHEN f.attrition = 'Yes' THEN 1 ELSE 0 END) AS attrited,
    ROUND(SUM(CASE WHEN f.attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS attrition_rate
FROM fact_attrition f
JOIN dim_work_conditions w ON f.condition_id = w.condition_id
GROUP BY w.work_life_balance
ORDER BY w.work_life_balance;

-- Data clearly shows employees with worse work life balance tend to have a high attrition rate.
-- Surprisingly employees with the best work life balance also have a minimal surge in attrition rate than 2 and 3 which indicate sophistication and desire to look elsewhere for more lucrative jobs.

-- attrition  by job satisfaction


SELECT 
    j.job_satisfaction,
    COUNT(*) AS total_employees,
    SUM(CASE WHEN f.attrition = 'Yes' THEN 1 ELSE 0 END) AS attrited,
    ROUND(SUM(CASE WHEN f.attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS attrition_rate
FROM fact_attrition f
JOIN dim_job j ON f.job_id = j.job_id
GROUP BY j.job_satisfaction
ORDER BY j.job_satisfaction;

-- Data clearly shows that employees with a lower job satisfaction have had a higher attrition rate and vice versa.alter

-- Avg years at company

SELECT 
    attrition,
    ROUND(AVG(years_at_company), 2) AS avg_tenure,
    ROUND(AVG(years_since_last_promotion), 2) AS avg_years_since_promotion,
    ROUND(AVG(monthly_income), 2) AS avg_income
FROM fact_attrition
GROUP BY attrition;