/*
Question: What are the most optimal skills to learn (aka it’s in high demand and a high-paying skill)?
- Identify skills in high demand and associated with high average salaries for Data Analyst roles
- Concentrates on remote positions with specified salaries
- Why? Targets skills that offer job security (high demand) and financial benefits (high salaries), offering strategic insights for career development in data analysis
*/

WITH average_salary AS (
    SELECT
        sd.skill_id,
        sd.skills,
        ROUND(AVG(salary_year_avg), 0) AS average_salary_year
    FROM
        job_postings_fact AS jpf
    INNER JOIN skills_job_dim AS sjd ON jpf.job_id = sjd.job_id
    INNER JOIN skills_dim AS sd ON sjd.skill_id = sd.skill_id
    WHERE 
        job_title_short = 'Data Analyst' AND
        salary_year_avg IS NOT NULL
        -- AND jpf.job_work_from_home = TRUE
    GROUP BY
        sd.skill_id
), skills_demand AS ( -- Have to use comma while combining CTEs
    SELECT 
        sjd.skill_id,
        COUNT(sjd.job_id) AS demand_count
    FROM job_postings_fact AS jpf
    LEFT JOIN skills_job_dim AS sjd ON jpf.job_id = sjd.job_id
    INNER JOIN skills_dim AS sd ON sjd.skill_id = sd.skill_id
    WHERE
        jpf.job_title_short = 'Data Analyst' AND
        jpf.job_work_from_home = TRUE
    GROUP BY
        sjd.skill_id
)

SELECT
    skills_demand.skill_id,
    average_salary.skills,
    demand_count,
    average_salary_year
FROM 
    skills_demand
INNER JOIN average_salary ON skills_demand.skill_id = average_salary.skill_id
WHERE
    demand_count > 10
ORDER BY
    -- average_salary DESC,
    demand_count DESC,
    average_salary DESC
LIMIT 25;


