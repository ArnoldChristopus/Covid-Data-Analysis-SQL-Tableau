/*
DATA CLEANING
*/
-- Cleaning CovidCases table
SELECT *
FROM covid.covidcases;


-- Changing some column names to make it easier to type
ALTER TABLE covid.covidcases
RENAME COLUMN `Country,Other` TO Country,
RENAME COLUMN `Serious,Critical` TO Serious;


-- Checking for nulls or empty strings in covidcases table
SELECT *
FROM covid.covidcases
WHERE
	`#` IN ('', ' ', 'N/A') OR
	Country IN ('', ' ', 'N/A') OR
    TotalCases IN ('', ' ', 'N/A') OR
    NewCases IN ('', ' ', 'N/A') OR
    TotalDeaths IN ('', ' ', 'N/A') OR
    NewDeaths IN ('', ' ', 'N/A') OR
    TotalRecovered IN ('', ' ', 'N/A') OR
    NewRecovered IN ('', ' ', 'N/A') OR
    ActiveCases IN ('', ' ', 'N/A') OR
    Serious IN ('', ' ', 'N/A') OR
    TotalTests IN ('', ' ', 'N/A') OR
    Population IN ('', ' ', 'N/A') OR
    Continent IN ('', ' ', 'N/A')
    ;


-- Since the majority of the newcases, newdeaths and newrecovered are empty, they can be dropped. 
-- For the other columns, I'm imputing the empty data with 0 and removing the commas from the number if it's not empty
UPDATE covid.covidcases
SET
	Country = CASE 
		WHEN Country IN ('

') THEN 'Other' 
		ELSE REPLACE(Country, '\n', '') END,
	TotalCases = CASE
		WHEN TotalCases IN ('', ' ', 'N/A') THEN 0 
        ELSE REPLACE(TotalCases, ',', '') END,
	TotalDeaths = CASE 
		WHEN TotalDeaths IN ('', ' ', 'N/A') THEN 0 
        ELSE REPLACE(TotalDeaths, ',', '') END,
	TotalRecovered = CASE 
		WHEN TotalRecovered IN ('', ' ', 'N/A') THEN 0 
        ELSE REPLACE(TotalRecovered, ',', '') END,
	ActiveCases = CASE 
		WHEN ActiveCases IN ('', ' ', 'N/A') THEN 0 
        ELSE REPLACE(ActiveCases, ',', '') END,
	Serious = CASE 
		WHEN Serious IN ('', ' ', 'N/A') THEN 0 
        ELSE REPLACE(Serious, ',', '') END,
	TotalTests = CASE 
		WHEN TotalTests IN ('', ' ', 'N/A') THEN 0 
        ELSE REPLACE(TotalTests, ',', '') END,
	Population = CASE 
		WHEN Population IN ('', ' ', 'N/A') THEN 0 
        ELSE REPLACE(Population, ',', '') END,
	Continent = CASE 
		WHEN Continent IN ('

', '') THEN 'Other' ELSE Continent END;

ALTER TABLE covid.covidcases
DROP COLUMN NewCases,
DROP COLUMN NewDeaths,
DROP COLUMN NewRecovered, 
DROP COLUMN `#`; -- Removing the # column whilst at it because it's useless.


SELECT *
FROM covid.covidcases
WHERE
	Country IN ('', ' ', 'N/A') OR
    TotalCases IN ('', ' ', 'N/A') OR
    TotalDeaths IN ('', ' ', 'N/A') OR
    TotalRecovered IN ('', ' ', 'N/A') OR
    ActiveCases IN ('', ' ', 'N/A') OR
    Serious IN ('', ' ', 'N/A') OR
    TotalTests IN ('', ' ', 'N/A') OR
    Population IN ('', ' ', 'N/A') OR
    Continent IN ('', ' ', 'N/A')
    ;


-- Removing the totals at the bottom because there are already totals at the top rows and also removing the empty row
DELETE FROM covid.covidcases WHERE country = 'Total:' OR totalcases = 0;


-- Changing country names to match the other tables
UPDATE covid.covidcases
SET country = 
		CASE
			WHEN country LIKE 'USA' THEN 'United States'
			WHEN country LIKE 'UK' THEN 'United Kingdom'
			WHEN country LIKE 'UAE' THEN 'United Arab Emirates'
			WHEN country LIKE 'S. Korea' THEN 'South Korea'
			WHEN country LIKE 'CAR' THEN 'Central African Republic'
			WHEN country LIKE 'DRC' THEN 'Democratic Republic of Congo'
			WHEN country LIKE 'Turks and Caicos' THEN 'Turks and Caicos Islands'
            WHEN country LIKE 'Cura%' THEN 'Curacao'
            WHEN country LIKE 'R%union' THEN 'Reunion'
			ELSE TRIM(country)
		END;


-- Creating a separate table for the continents 
DROP TABLE IF EXISTS covid.continentcases;
     
CREATE TABLE covid.continentcases AS (
	SELECT tmp.continent, TotalCases,
		TotalDeaths, TotalRecovered,
        ActiveCases, Serious,
        tmp.totaltests, tmp.population
    FROM (
		SELECT *
        FROM covid.covidcases
        WHERE country IN (continent, 'world', 'oceania')
    ) AS c
    JOIN (
		SELECT continent AS continent,
			SUM(totaltests) AS totaltests,
			SUM(population) AS population
		FROM covid.covidcases
		GROUP BY continent
    ) AS tmp
    ON c.continent = tmp.continent
);

-- Adding the totaltests and population of world
UPDATE covid.continentcases
SET 
	totaltests = (
		SELECT SUM(totaltests)
        FROM covid.covidcases
        WHERE country NOT IN (continent, 'oceania')
),
	population = (
		SELECT SUM(population)
        FROM covid.covidcases
        WHERE country NOT IN (continent, 'oceania')
)
WHERE continent = 'All';

SELECT *
FROM covid.continentcases;

-- Removing the continent rows from the country table
DELETE FROM covid.covidcases WHERE Country IN (continent, 'world', 'oceania');
 

-- Cleaning Vaccines table
-- Checking for nulls or empty strings in vaccines table
SELECT *
FROM covid.vaccines;

-- Removing the empty row
DELETE FROM covid.vaccines WHERE location = '';

-- Changing country names
UPDATE covid.vaccines
SET location =
	CASE
		WHEN location LIKE 'Palestine%' THEN 'Palestine'
		WHEN location LIKE 'Israel%' THEN 'Israel'
		WHEN location LIKE 'Sint%' THEN 'Sint Maarten'
        WHEN location LIKE 'Timor' THEN 'Timor-Leste'
		WHEN location LIKE 'Cape Verde' THEN 'Cabo Verde'
        WHEN location LIKE 'Cote%' THEN 'Ivory Coast'
		ELSE TRIM(location)
	END;


-- Cleaning Vaccinated table
SELECT *
FROM covid.vaccinated;

-- Removing the empty row
DELETE FROM covid.vaccinated WHERE country = '';

-- Shortening the column names
ALTER TABLE covid.vaccinated
RENAME COLUMN `People fully vaccinated against COVID-19` TO FullyVaccinated,
RENAME COLUMN `People only partly vaccinated against COVID-19` TO PartlyVaccinated,
RENAME COLUMN Country TO Countries;

-- Changing country names
UPDATE covid.vaccinated  
SET countries =
	CASE
		WHEN countries LIKE 'Palestine%' THEN 'Palestine'
		WHEN countries LIKE 'Israel%' THEN 'Israel'
		WHEN countries LIKE 'Sint%' THEN 'Sint Maarten'
		WHEN countries LIKE 'Timor' THEN 'Timor-Leste'
		WHEN countries LIKE 'Cape Verde' THEN 'Cabo Verde'
        WHEN countries LIKE 'Cote%' THEN 'Ivory Coast'
		ELSE TRIM(countries)
	END;


-- Checking for nulls or empty strings in vaccinated table
SELECT *
FROM covid.vaccinated
WHERE
	countries IN ('', ' ', 'N/A') OR
	FullyVaccinated IN ('', ' ', 'N/A') OR
    PartlyVaccinated IN ('', ' ', 'N/A');


-- Imputing empty values in vaccinated table with 0
UPDATE covid.vaccinated
SET
	FullyVaccinated = CASE 
		WHEN FullyVaccinated IN ('', ' ', 'N/A')
        THEN '0'
        ELSE FullyVaccinated
        END,
	PartlyVaccinated = CASE 
		WHEN PartlyVaccinated IN ('', ' ', 'N/A')
        THEN '0'
        ELSE PartlyVaccinated
        END;

-- Stripping the dates from the values
UPDATE covid.vaccinated
SET fullyvaccinated = TRIM(SUBSTRING(fullyvaccinated, 13)),
	partlyvaccinated = TRIM(SUBSTRING(partlyvaccinated, 13))
WHERE fullyvaccinated LIKE '%202%';
    
    

UPDATE covid.vaccinated
SET fullyvaccinated =
	CASE 
		WHEN fullyvaccinated LIKE '%million'
			THEN ROUND((REPLACE(fullyvaccinated, ' million', ''))*1000000)
		WHEN fullyvaccinated LIKE '%billion'
			THEN ROUND((REPLACE(fullyvaccinated, ' billion', ''))*1000000000)
		ELSE REPLACE(fullyvaccinated, ',', '')
	END,
	partlyvaccinated =
	CASE
		WHEN partlyvaccinated LIKE '%million'
			THEN ROUND((REPLACE(partlyvaccinated, ' million', ''))*1000000)
		WHEN partlyvaccinated LIKE '%billion'
			THEN ROUND((REPLACE(partlyvaccinated, ' billion', ''))*1000000000)
		ELSE REPLACE(partlyvaccinated, ',', '')
	END;


        
-- Join the three tables
DROP TABLE IF EXISTS covid.merged;

CREATE TABLE covid.merged AS (
	SELECT *
	FROM covid.covidcases c
	JOIN covid.vaccines v
		ON c.Country = v.Location
	JOIN covid.vaccinated vd
		ON c.Country = vd.Countries
);


SELECT *
FROM covid.merged
ORDER BY Country;
    
    
-- Removing unnecessary columns
ALTER TABLE covid.merged
DROP COLUMN location,
DROP COLUMN countries,
DROP COLUMN `last observation date`;


-- Checking if there are countries that are left out from the merged table due to naming difference of the countries in the 3 tables
SELECT *
FROM covid.vaccinated
WHERE countries NOT IN (
	SELECT Country
    FROM covid.merged
)
ORDER BY countries;


SELECT *
FROM covid.vaccines
WHERE location NOT IN (
	SELECT Country
    FROM covid.merged
)
ORDER BY location;


SELECT *
FROM covid.covidcases
WHERE country NOT IN (
	SELECT Country
    FROM covid.merged
)
ORDER BY country;



/*
EXPLORATORY DATA ANALYSIS
*/
-- Infection rate, case fatality rate, recovery rate and positive rate of each country
SELECT country,
	totalcases/population*100 AS InfectionRate,
	totaldeaths/totalcases*100 AS CaseFatalityRate,
    totalrecovered/totalcases*100 AS RecoveryRate,
    totalcases/totaltests*100 AS PositiveRate
FROM covid.covidcases
ORDER BY CaseFatalityRate DESC;


-- Infection rate, case fatality rate, recovery rate and positive rate of each continent
SELECT continent,
	totalcases/population*100 AS InfectionRate,
    totaldeaths/totalcases*100 AS CaseFatalityRate,
    totalrecovered/totalcases*100 AS RecoveryRate,
    totalcases/totaltests*100 AS PositiveRate
FROM covid.continentcases
ORDER BY CaseFatalityRate DESC;


-- Percentage of the countries' population that is vaccinated
SELECT country, population, fullyvaccinated, partlyvaccinated,
	(fullyvaccinated + partlyvaccinated)/population*100 AS VaccinationPercentage
FROM covid.merged
ORDER BY VaccinationPercentage DESC;


-- Most used vaccine type
-- Finding the highest count of vaccine types a country uses
SELECT
	Location,
    vaccines, 
    CHAR_LENGTH(vaccines) - CHAR_LENGTH(REPLACE(vaccines, ',', '')) + 1 AS HighestVacTypeCounts
FROM
	covid.vaccines
WHERE
	CHAR_LENGTH(vaccines) - CHAR_LENGTH(REPLACE(vaccines, ',', '')) + 1 = (
		SELECT
			MAX(CHAR_LENGTH(vaccines) - CHAR_LENGTH(REPLACE(vaccines, ',', '')) + 1)
		FROM
			covid.vaccines
);


-- Creating a custom function to save space
DELIMITER //

CREATE FUNCTION GetVaccineComponent(vaccines VARCHAR(255), index1 INT, index2 INT)
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
    DECLARE comp1 VARCHAR(255);
    DECLARE comp2 VARCHAR(255);

    SET comp1 = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(vaccines, ',', index1), ',', -1));
    SET comp2 = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(vaccines, ',', index2), ',', -1));

    IF comp1 != comp2 THEN
        RETURN comp1;
    ELSE
        RETURN NULL;
    END IF;
END //

DELIMITER ;


-- Splitting the 1 column vaccine list of each country into multiple columns and store them in a CTE
WITH vaccine AS (
	SELECT
		TRIM(SUBSTRING_INDEX(vaccines, ',', 1)) AS vac1,
		GetVaccineComponent(vaccines, 2, 1) AS vac2,
		GetVaccineComponent(vaccines, 3, 2) AS vac3,
		GetVaccineComponent(vaccines, 4, 3) AS vac4,
		GetVaccineComponent(vaccines, 5, 4) AS vac5,
		GetVaccineComponent(vaccines, 6, 5) AS vac6,
		GetVaccineComponent(vaccines, 7, 6) AS vac7,
		GetVaccineComponent(vaccines, 8, 7) AS vac8,
		GetVaccineComponent(vaccines, 9, 8) AS vac9
	FROM covid.vaccines
)
-- Using UNION ALL to combine the columns into 1 column with each row having 1 vaccine instead of a vaccine list for counting each vaccine type
SELECT vac1 AS VaccineType, COUNT(vac1) AS count
FROM (
	SELECT vac1 FROM vaccine WHERE vac1 IS NOT NULL
	UNION ALL
	SELECT vac2 FROM vaccine WHERE vac2 IS NOT NULL
	UNION ALL
	SELECT vac3 FROM vaccine WHERE vac3 IS NOT NULL
	UNION ALL
	SELECT vac4 FROM vaccine WHERE vac4 IS NOT NULL
	UNION ALL
	SELECT vac5 FROM vaccine WHERE vac5 IS NOT NULL
	UNION ALL
	SELECT vac6 FROM vaccine WHERE vac6 IS NOT NULL
	UNION ALL
	SELECT vac7 FROM vaccine WHERE vac7 IS NOT NULL
	UNION ALL
	SELECT vac8 FROM vaccine WHERE vac8 IS NOT NULL
    UNION ALL
	SELECT vac9 FROM vaccine WHERE vac9 IS NOT NULL
) AS tmp
GROUP BY VaccineType
ORDER BY count DESC;