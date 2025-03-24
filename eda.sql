SELECT *
from layoffs_cleaned;

SELECT MIN(total_laid_off), MAX(total_laid_off)
FROM layoffs_cleaned;

SELECT company, total_laid_off
FROM layoffs_cleaned
WHERE total_laid_off = 
	(SELECT MAX(total_laid_off) 
     FROM layoffs_cleaned);
-- Google has the highest number of lay off in a day

SELECT company, SUM(total_laid_off) AS total_number
FROM layoffs_cleaned
GROUP BY company
ORDER BY 2 DESC;
-- Overall big tech companies experience highest layoffs in total with Amazon leading with 18150

SELECT industry, SUM(total_laid_off) AS total_number
FROM layoffs_cleaned
GROUP BY industry
ORDER BY 2 DESC;

SELECT country, SUM(total_laid_off) AS total_number
FROM layoffs_cleaned
GROUP BY country
ORDER BY 2 DESC;
-- Surprisingly, India is the second most affected country during the layoffs wave

WITH monthly_layoffs AS (
	SELECT YEAR(`date`) AS `year`, MONTH(`date`) AS `month`, SUM(total_laid_off) AS total_number
	FROM layoffs_cleaned
	WHERE YEAR(`date`) IS NOT NULL
		AND MONTH(`date`) IS NOT NULL
	GROUP BY `year`, `month`
	ORDER BY `year`, `month` ASC)
SELECT *, SUM(total_number) OVER (ORDER BY year, month ASC) AS rolling_total
FROM monthly_layoffs;
-- It looks like that 2021 was a good year with little layoffs. This might be the results of the world recovering from the pandemic. However, we can see a spike in layoffs in 2022 and 2023 as companies starting to feel the effect of high inflation and interest rate

WITH company_yearly AS (
		SELECT company, YEAR(`date`) AS `year`, SUM(total_laid_off) AS total_number
		FROM layoffs_cleaned
		WHERE YEAR(`date`) IS NOT NULL
		GROUP BY company,  `year`
		HAVING total_number IS NOT NULL
		ORDER BY 2 ASC, 3 DESC), 
	ranked_layoffs AS (
		SELECT *, DENSE_RANK() OVER (PARTITION BY `year` ORDER BY total_number DESC) AS Ranking
		FROM company_yearly)
SELECT *
FROM ranked_layoffs
WHERE Ranking <= 5;
-- Overall, top 5 companies with the highest layoffs across all years are all household name like Uber, Meta, Amazon, Google and so on.