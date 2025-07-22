
SELECT
	count(*) AS record_count
FROM
	data_analyst.jobs;

WITH get_unique_postings AS (
	SELECT
		count(DISTINCT description) AS record_count
	FROM
		data_analyst.jobs
	GROUP BY
		description
)
SELECT
	sum(record_count) AS total_unique_records
FROM
	get_unique_postings;

WITH get_single_day AS (
	SELECT
		date_time::date AS post_date
	FROM
		data_analyst.jobs
	GROUP BY
		post_date
	ORDER BY
		post_date
)
SELECT
	post_date
FROM
	get_single_day
WHERE NOT EXISTS (
	SELECT generate_series('2022-11-04', '2023-09-08', INTERVAL '1 day')::date
);

SELECT
	company_name,
	count(*) AS same_post_count
FROM
	data_analyst.jobs
GROUP BY
	company_name,
	description
HAVING
	count(*) > 1
ORDER BY
	same_post_count DESC
LIMIT 20;


SELECT
	data_job_id,
	idx,
	title,
	company_name,
	job_location,
	via,
	description_tokens
FROM
	data_analyst.jobs
ORDER BY
	random()
LIMIT 5;


WITH get_totals_cte AS (
	SELECT
		(SELECT * FROM get_record_count) AS total_records,
		count(*) AS no_salary_count
	FROM
		data_analyst.jobs
	WHERE
		salary_standardized IS NULL
)
SELECT
	total_records AS total_record_count,
	no_salary_count,
	total_records - no_salary_count AS record_diff,
	round(100 * no_salary_count::numeric / total_records, 2) AS no_salary_percentage
FROM
	get_totals_cte;


WITH get_hourly_stats AS (
	SELECT
		CASE
			WHEN schedule_type = 'Contractor and Temp work' THEN 'Contractor'
			WHEN schedule_type = 'Full-time and Part-time' OR schedule_type = 'Full-time, Part-time, and Internship' THEN 'Full-time'
			WHEN schedule_type IS NULL THEN 'Uknown'
			ELSE schedule_type
		END AS hourly_rate_schedule_type,
		count(*) AS number_of_jobs,
		round(min(salary_hourly)::NUMERIC, 2) AS hourly_min,
		round(avg(salary_hourly)::NUMERIC, 2) AS hourly_avg,
		round(percentile_cont(0.25) WITHIN GROUP (ORDER BY salary_hourly)::NUMERIC, 2) AS hourly_25_perc,
		round(percentile_cont(0.5) WITHIN GROUP (ORDER BY salary_hourly)::NUMERIC, 2) AS hourly_median,
		round(percentile_cont(0.75) WITHIN GROUP (ORDER BY salary_hourly)::NUMERIC, 2) AS hourly_75_perc,
		round(MODE() WITHIN GROUP (ORDER BY salary_hourly)::NUMERIC, 2) AS hourly_mode,
		round(max(salary_hourly)::NUMERIC, 2) AS hourly_max
	FROM
		data_analyst.jobs
	WHERE
		salary_hourly IS NOT NULL
	GROUP BY
		hourly_rate_schedule_type
)
SELECT
	hourly_rate_schedule_type,
	number_of_jobs,
	cast(hourly_min AS money) AS hourly_min,
	cast(hourly_avg AS money) AS hourly_min,
	cast(hourly_25_perc AS money) AS hourly_25_perc,
	cast(hourly_median AS money) AS hourly_median,
	cast(hourly_75_perc AS money) AS hourly_75_perc,
	cast(hourly_mode AS money) AS hourly_mode,
	cast(hourly_max AS money) AS hourly_max
FROM
	get_hourly_stats;



WITH get_yearly_stats AS (
	SELECT
		COALESCE(schedule_type, 'Unknown') AS yearly_rate_schedule_type,
		count(*) AS number_of_jobs,
		round(min(salary_yearly)::NUMERIC, 2) AS yearly_min,
		round(avg(salary_yearly)::NUMERIC, 2) AS yearly_avg,
		round(percentile_cont(0.25) WITHIN GROUP (ORDER BY salary_yearly)::NUMERIC, 2) AS yearly_25_perc,
		round(percentile_cont(0.5) WITHIN GROUP (ORDER BY salary_yearly)::NUMERIC, 2) AS yearly_median,
		round(percentile_cont(0.75) WITHIN GROUP (ORDER BY salary_yearly)::NUMERIC, 2) AS yearly_75_perc,
		round(MODE() WITHIN GROUP (ORDER BY salary_yearly)::NUMERIC, 2) AS yearly_mode,
		round(max(salary_yearly)::NUMERIC, 2) AS yearly_max
	FROM
		data_analyst.jobs
	WHERE
		salary_yearly IS NOT NULL
	GROUP BY
		schedule_type
)
SELECT
	yearly_rate_schedule_type,
	number_of_jobs,
	cast(yearly_min AS money) AS yearly_min,
	cast(yearly_avg AS money) AS yearly_min,
	cast(yearly_25_perc AS money) AS yearly_25_perc,
	cast(yearly_median AS money) AS yearly_median,
	cast(yearly_75_perc AS money) AS yearly_75_perc,
	cast(yearly_mode AS money) AS yearly_mode,
	cast(yearly_max AS money) AS yearly_max
FROM
	get_yearly_stats;



WITH get_skills AS (
	SELECT
		UNNEST(description_tokens) AS technical_skills
	FROM
		data_analyst.jobs
)
SELECT
	technical_skills,
	count(*) AS frequency,
	round(100 * count(*)::NUMERIC / (SELECT * FROM get_record_count), 2) AS freq_perc
FROM
	get_skills
GROUP BY
	technical_skills
ORDER BY
	frequency DESC
LIMIT 5;


SELECT
	initcap(company_name) AS company_name,
	count(*) AS number_of_posts
FROM
	data_analyst.jobs
GROUP BY
	company_name
ORDER BY
	number_of_posts DESC
LIMIT 20;


SELECT
	CASE
		WHEN 
			title LIKE '%sr%' 
			OR title LIKE '%iv%' 
			OR title LIKE '%senior data%' 
		THEN 'Senior Data Analyst'
		WHEN 
			title LIKE '%lead%' 
			OR title = 'data analyst 2'
			OR title LIKE '%iii%' 
			OR title LIKE '%ii%' 
		THEN 'Mid-Level Data Analyst'
		WHEN 
			title IN (
				'business intelligence analyst',
				'business analyst', 
				'business systems data analyst',
				'bi data analyst')
		THEN 'Business Data Analyst'
		WHEN 
			title = 'entry level data analyst' 
			OR title IN ( 
				'jr. data analyst', 
				'jr data analyst', 
				'data analyst i',
				'data analyst 1')
		THEN 'Junior Data Analyst'
		WHEN 
			title IN (
				'data analyst (remote)', 
				'data analyst - contract to hire',
				'data analyst - remote', 
				'remote data analyst',
				'data analyst - now hiring',
				'analyst',
				'data analysis')
		THEN 'Data Analyst'
		ELSE initcap(title)
	END AS job_titles,
	count(*) title_count
FROM
	data_analyst.jobs
GROUP BY
	job_titles
ORDER BY
	title_count DESC
LIMIT 10;


WITH get_monthly_jobs AS (
	SELECT
		to_char(date_time, 'Month') AS job_month,
		count(*) AS job_count
	FROM
		data_analyst.jobs
	WHERE
		EXTRACT('year' FROM date_time) = 2023
	AND
		EXTRACT('month' FROM date_time) < 9
	GROUP BY
		job_month
)
SELECT
	job_month,
	job_count,
	round (100 * (job_count - LAG(job_count) OVER (ORDER BY to_date(job_month, 'Month'))) / LAG(job_count) OVER (ORDER BY to_date(job_month, 'Month'))::NUMERIC, 2) AS month_over_month
FROM
	get_monthly_jobs
ORDER BY
	to_date(job_month, 'Month');

WITH get_day_count AS (
	SELECT
		date_time::date AS single_day,
		count(*) AS daily_job_count,
		DENSE_RANK() OVER (ORDER BY count(*) DESC) AS rnk
	FROM
		data_analyst.jobs
	GROUP BY
		date_time::date
	ORDER BY
		single_day
)
SELECT
	single_day,
	daily_job_count
FROM
	get_day_count
WHERE
	rnk < 6
ORDER BY
	rnk;


WITH get_all_extensions AS (
	SELECT
		UNNEST(extensions) AS benefits,
		count(*) AS benefits_count
	FROM
		data_analyst.jobs
	GROUP BY
		benefits
)
SELECT
	benefits,
	benefits_count
FROM
	get_all_extensions
WHERE
	benefits IN ('Health insurance','Dental insurance','Paid time off')
ORDER BY
	benefits_count DESC;



DROP TABLE IF EXISTS company_benefits;
CREATE TEMP TABLE company_benefits AS (
	WITH get_all_extensions AS (
		SELECT
			data_job_id,
			company_name,
			UNNEST(extensions) AS benefits
		FROM
			data_analyst.jobs
	)
	SELECT
		data_job_id,
		initcap(company_name) AS company_name,
		array_agg(benefits) AS benefits
	FROM
		get_all_extensions
	WHERE
		benefits IN ('Health insurance','Dental insurance','Paid time off')
	GROUP BY 
		data_job_id,
		company_name
);

SELECT 
	company_name,
	benefits
FROM 
	company_benefits
LIMIT 10;



SELECT
	company_name,
	CASE
		WHEN ('Health insurance' = ANY(benefits)) = TRUE THEN 'Yes'
		ELSE 'No'
	END AS health_insurance,
	CASE
		WHEN ('Dental insurance' = ANY(benefits)) = TRUE THEN 'Yes'
		ELSE 'No'
	END AS dental_insurance,
	CASE
		WHEN ('Paid time off' = ANY(benefits)) = TRUE THEN 'Yes'
		ELSE 'No'
	END AS paid_time_off
FROM
	company_benefits;


--thankyou..
