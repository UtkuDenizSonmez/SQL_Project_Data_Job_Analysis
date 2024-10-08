SELECT
    job_title_short AS title,
    job_location AS location,
    job_posted_date AT TIME ZONE 'UTC' AT TIME ZONE 'EST' AS date_time,
    EXTRACT(MONTH FROM job_posted_date) AS date_month
FROM job_postings_fact
LIMIT 5;


SELECT
    COUNT(job_id) AS job_posted_count,
    EXTRACT(MONTH FROM job_posted_date) AS date_month
FROM 
    job_postings_fact
WHERE
    job_title_short = 'Data Analyst'
GROUP BY 
    date_month
ORDER BY 
    job_posted_count DESC;


-- 1-) Write a query to find the average salary both yearly(salary_year_avg) and hourly (salary_hour_avg) for job postings that were posted after June 1, 2023. Group the results by job schedule type.
SELECT 
    job_title,
    job_schedule_type,
    AVG(salary_year_avg) AS year_avg_salary,
    AVG(salary_hour_avg) AS hour_avg_salary
FROM 
    job_postings_fact
WHERE
    job_posted_date > '2023-06-01'
GROUP BY 
    job_schedule_type,
    job_title;

-- 2-) Write a query to count the number of job postings for each month in 2023, adjusting the job_posted_date to be in 'America/New_York' time zone before extracting the month. Assume the job_posted_date is storen in UTC. Group by and order by the month.
SELECT 
    COUNT(job_id),
    EXTRACT(MONTH FROM job_posted_date AT TIME ZONE 'UTC' AT TIME ZONE 'America/New_York') as date_month
FROM 
    job_postings_fact
WHERE 
    EXTRACT(YEAR FROM job_posted_date AT TIME ZONE 'UTC' AT TIME ZONE 'America/New_York') = 2023
GROUP BY
    date_month
ORDER BY 
    date_month;

-- 3-) Write a query to find companies(include company name) that have posted jobs offering health insurance, where these postings were made in the second quarter of 2023. Use date extraction to filter by quarter.
SELECT 
    company.name,
    jobs.job_title
FROM company_dim AS company
INNER JOIN job_postings_fact AS jobs ON company.company_id = jobs.company_id
WHERE 
    jobs.job_health_insurance = true AND 
    EXTRACT(YEAR FROM jobs.job_posted_date) = 2023 AND
    EXTRACT(QUARTER FROM jobs.job_posted_date) = 2;

/*
- Create table From other tables
- Jan 2023 Jobs
- Feb 2023 Jobs
- Mar 2023 Jobs
*/ 

CREATE TABLE january_jobs AS 
    SELECT * 
    FROM 
        job_postings_fact
    WHERE 
        EXTRACT(MONTH FROM job_posted_date) = 1 AND 
        EXTRACT(YEAR FROM job_posted_date) = 2023;

CREATE TABLE february_jobs AS 
    SELECT * 
    FROM 
        job_postings_fact
    WHERE 
        EXTRACT(MONTH FROM job_posted_date) = 2 AND 
        EXTRACT(YEAR FROM job_posted_date) = 2023;

CREATE TABLE march_jobs AS 
    SELECT * 
    FROM 
        job_postings_fact
    WHERE 
        EXTRACT(MONTH FROM job_posted_date) = 3 AND 
        EXTRACT(YEAR FROM job_posted_date) = 2023;


SELECT * FROM march_jobs;

/*
Label new column as follows:
- 'Anywhere' jobs as 'Remote',
- 'New York, NY' as 'Local',
- Otherwise 'Onsite'
*/

SELECT
    COUNT(job_id) AS number_of_jobs,
    CASE 
        WHEN job_location = 'Anywhere' THEN 'Remote'
        WHEN job_location = 'New York, NY' THEN 'Local'
        ELSE 'Onsite'
    END AS location_category
FROM 
    job_postings_fact
WHERE
    job_title_short = 'Data Analyst'
GROUP BY
    location_category
ORDER BY 
    number_of_jobs DESC;

/* Want to categorize the salaries from each job posting. To see if it fits in my desired salary range.
- Put salary into different buckets
- Define what's a high, standart or low salary with our own conditions.
- Why? It is east to determine which job postings are worth looking at based on salary.
Bucketing is a common thing in data analysis when viewing categories.
- Look only for Data Analyst roles.
- Order from highest to lowest.
*/

SELECT
    job_title,
    CASE
        WHEN salary_year_avg BETWEEN 0 AND 65000 THEN 'Low'
        WHEN salary_year_avg BETWEEN 65000 AND 110000 THEN 'Standart'
        ELSE 'High'
    END
FROM 
    job_postings_fact
WHERE 
    job_title LIKE '%Analyst%'
ORDER BY 
    salary_year_avg DESC;

-- Subqueries and CTEs -- 
SELECT *
    FROM(
        SELECT * 
        FROM job_postings_fact
        WHERE EXTRACT(MONTH FROM job_posted_date) = 1
    ) AS january_jobs;


WITH january_jobs AS (
    SELECT * 
    FROM job_postings_fact
    WHERE EXTRACT(MONTH FROM job_posted_date) = 1
)

SELECT * 
FROM january_jobs;

-- Get the company names and ids that dont requires a degree for a job.
SELECT 
    company_id, 
    name AS company_name
FROM 
    company_dim
WHERE company_id IN(
    SELECT company_id
    FROM job_postings_fact
    WHERE job_no_degree_mention = true
)
ORDER BY company_id;


/* Find the companies that have the most job openings.
- Get the total number of job postings per company id.
- Return the total number of jobs with the company name.
*/ 

WITH company_job_count AS(
    SELECT
        company_id,
        COUNT(*) AS total_jobs
    FROM 
        job_postings_fact
    GROUP BY
        company_id
)

SELECT 
    company.name AS company_name,
    company_job_count.total_jobs
FROM company_dim AS company
LEFT JOIN company_job_count ON company.company_id = company_job_count.company_id
ORDER BY total_jobs DESC;


/* 
Idendify the top 5 skills that are most frequently mentioned in job postings. 
- Use a subquery to find the skill IDs with the highest counts in the skills_job_dim table and then join this results with the skills_dim table to get the skill names.
*/

SELECT 
    skill_id,
    COUNT(*) as skill_count
FROM
    skills_job_dim AS sjd
INNER JOIN job_postings_fact AS j ON sjd.job_id = j.job_id
WHERE sjd.skill_id IN(
    SELECT skill_id
    FROM skills_dim
)
GROUP BY
    sjd.skill_id
ORDER BY skill_count DESC
LIMIT 5;

/* Find the count of the number of remote job postings per skill
- Display the top 5 skills by their demand in remote jobs
- Include skill id, name, and count of postings requiring the skill
*/

WITH remote_job_skills AS (
    SELECT
        skill_id,
        COUNT(*) AS skill_count
    FROM
        skills_job_dim AS sjd
    INNER JOIN job_postings_fact AS j ON sjd.job_id = j.job_id
    WHERE 
        j.job_work_from_home = True
    GROUP BY 
        skill_id
)

SELECT 
    s.skill_id,
    s.skills,
    skill_count
FROM remote_job_skills
INNER JOIN skills_dim AS s ON remote_job_skills.skill_id = s.skill_id
ORDER BY 
    skill_count DESC
LIMIT 5;

/*
- Find job postings from the first quarter that have a salary greater than $70K
- Combine job posting tables from the first quarter of 2023 (Jan-Mar)
- Get job postings with an average yearly salary > $70,000
*/

SELECT 
    quarter1_job_postings.job_title_short,
    quarter1_job_postings.job_location,
    quarter1_job_postings.job_via,
    quarter1_job_postings.job_posted_date::DATE,
    quarter1_job_postings.salary_year_avg
FROM(
    SELECT *
    FROM january_jobs

    UNION ALL -- Don't want to lose any duplicates

    SELECT *
    FROM february_jobs

    UNION ALL

    SELECT *
    FROM march_jobs
) AS quarter1_job_postings
WHERE 
    quarter1_job_postings.salary_year_avg > 70000 AND
    quarter1_job_postings.job_title_short = 'Data Analyst'
ORDER BY
    quarter1_job_postings.salary_year_avg DESC;


/*
- Get the corresponding skill and skill type for each job posting for q1.
- Include those without any skills too.
- Why? Look at the skills and the type for each job in the first quarter that has salary > $70,000
*/

SELECT 
    q1_jobs.job_title_short,
    s.skills,
    s.type
FROM (
    SELECT *
    FROM january_jobs

    UNION ALL -- Don't want to lose any duplicates

    SELECT *
    FROM february_jobs

    UNION ALL

    SELECT *
    FROM march_jobs    
) AS q1_jobs
INNER JOIN skills_job_dim AS sjd ON sjd.job_id = q1_jobs.job_id
RIGHT JOIN skills_dim AS s ON s.skill_id = sjd.skill_id -- Including data without skills.
WHERE 
    q1_jobs.salary_year_avg > 110000;



