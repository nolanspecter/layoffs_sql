SELECT *
FROM layoffs;

-- Create and move data into staging table to avoid accidents with original data 
CREATE TABLE IF NOT EXISTS layoffs_staging
LIKE layoffs;

INSERT INTO layoffs_staging
SELECT *
FROM layoffs;

SELECT *
FROM layoffs_staging;

-- STANDARDISING COLUMNS 
-- Company 
SELECT DISTINCT company
FROM layoffs_staging
ORDER BY 1;

-- There are companies name with leading whitespace 
UPDATE layoffs_staging
SET company = TRIM(company);

SELECT DISTINCT company
FROM layoffs_staging
ORDER BY 1;

-- Industry 
SELECT DISTINCT industry
FROM layoffs_staging
ORDER BY 1;

-- There are different ways that Cryptocurrency industry was recorded in the dataset. It will be standardise in to `Crypto` 
UPDATE layoffs_staging
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT industry
FROM layoffs_staging
ORDER BY 1;

-- Location -- 
SELECT DISTINCT location
FROM layoffs_staging
ORDER BY 1;

-- There are some problem with utf-coding from foreign language, but it is not a big problem. Other than that the column looks in order  

-- Country -- 
SELECT DISTINCT country
FROM layoffs_staging
ORDER BY 1;

-- United States has 2 different ways recorded, one with a dot and one without

UPDATE layoffs_staging
SET country = TRIM(TRAILING '.' FROM country);

SELECT DISTINCT country
FROM layoffs_staging
ORDER BY 1;

-- Date
UPDATE layoffs_staging
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging
MODIFY COLUMN `date` DATE;

-- NULL AND BLANK HANDLING
-- Industry
SELECT *
FROM layoffs_staging
WHERE industry IS NULL
	OR industry = '';

UPDATE layoffs_staging
SET industry = NULL
WHERE industry = '';

SELECT t1.*, t2.industry
FROM layoffs_staging AS t1
JOIN layoffs_staging AS t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE t1.industry IS NULL
	AND t2.industry IS NOT NULL;
    
UPDATE layoffs_staging AS t1
JOIN layoffs_staging AS t2
	ON t1.company = t2.company
    AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
	AND t2.industry IS NOT NULL;
    
-- After updating, we have only 1 company that does not have and industry. We will manually set them to other

UPDATE layoffs_staging
SET industry = 'Other'
WHERE company = 'Bally\'s Interactive';

-- Total laid off & percentage laid off
-- Since there is no figure for us to base on and compute these to variables. We will only aim to drop records where both of them are null
SELECT * 
FROM layoffs_staging
WHERE total_laid_off IS NULL
	AND percentage_laid_off IS NULL;

DELETE
FROM layoffs_staging
WHERE total_laid_off IS NULL
	AND percentage_laid_off IS NULL;

-- REMOVE DUPLICATE
SELECT *, ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

CREATE TABLE layoffs_cleaned
LIKE layoffs_staging;

ALTER TABLE layoffs_cleaned
ADD COLUMN row_num INT;

INSERT INTO layoffs_cleaned
SELECT *, ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

DELETE
FROM layoffs_cleaned
WHERE row_num > 1;

ALTER TABLE layoffs_cleaned
DROP COLUMN row_num;

SELECT *
FROM layoffs_cleaned;