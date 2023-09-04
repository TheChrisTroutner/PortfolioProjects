/*
Data Exploration Project - COVID-19 Data

SQL skills used: filtering, aggregation, joins, subqueries, window functions, CTEs and creating views.
*/

--Select Data to be used.
SELECT	iso_code,
		location,
		date,
		total_cases,
		new_cases,
		total_deaths,
		population
FROM [ProjectPortfolio].[dbo].[covid_deaths]
ORDER BY 2,3;

--Looking at the Percentge of Total Deaths to Total Cases on a daily basis for the USA (DeathPercentage).
--(some numeric data points captured as nvarchar in source data and need to be converted for arithmetic operations)
SELECT	iso_code,
		location,
		date,
		total_cases,
		total_deaths,
		(CONVERT(float,total_deaths)/NULLIF(CONVERT(float,total_cases),0))*100 AS DeathPercentage
FROM [ProjectPortfolio].[dbo].[covid_deaths]
WHERE iso_code = 'USA'
ORDER BY 6 DESC;


/*
Identifying the highest DeathPercentage by country where the minimum amount of total cases is
greater than or equal to 5,000
--obvious data issue with data from France
*/
WITH DeathByLoc AS
(
	SELECT	iso_code,
			location,
			date,
			total_cases,
			total_deaths,
			(CONVERT(float,total_deaths)/NULLIF(CONVERT(float,total_cases),0))*100 AS DeathPercentage
FROM [ProjectPortfolio].[dbo].[covid_deaths]
WHERE continent IS NOT NULL
		AND CAST(total_cases as float) >= 5000
)
SELECT	iso_code,
		location,
		--date,
		MAX(DeathPercentage) AS MaxDeathPerct
FROM DeathByLoc
GROUP BY iso_code, location
ORDER BY MaxDeathPerct DESC;

/*
Looking at Total Cases vs. Population
Shows percentage of population infected with COVID for the USA
*/
SELECT	iso_code,
		location,
		date,
		total_cases,
		population,
		(CONVERT(float,total_cases)/population) AS CasePercentage
FROM [ProjectPortfolio].[dbo].[covid_deaths]
WHERE iso_code = 'USA'
ORDER BY 3;

/*
Looking at countries with the Highest Infection Rates compared to Population
*/
SELECT	iso_code,
		location,
		MAX(CONVERT(float,total_cases)) AS MaxCases,
		population,
		MAX(CONVERT(float,total_cases)/population)*100 AS CasePercentage
FROM [ProjectPortfolio].[dbo].[covid_deaths]
WHERE continent IS NOT NULL
GROUP BY iso_code, location, population
ORDER BY 5 DESC;

/*
Showing Countries by death rate in descending order. 
*/
SELECT	iso_code,
		continent,
		location,
		population,
		MAX(CONVERT(float,total_deaths)) AS MaxDeaths,
		(MAX(CONVERT(float,total_deaths)) / population)* 100 AS MaxDeathPercentage
FROM [ProjectPortfolio].[dbo].[covid_deaths]
WHERE continent IS NOT NULL
GROUP BY iso_code, continent, location, population
ORDER BY 6 DESC;

/* Highest Death Tolls per country */

SELECT	continent, location,
		MAX(Convert(float,total_deaths)) AS MaxDeaths
FROM [ProjectPortfolio].[dbo].covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent, location
ORDER BY 1,2;


--Identifying the Date for each country where the most new cases occurred
		SELECT
			location,
			date,
			new_cases
		FROM [ProjectPortfolio].[dbo].[covid_deaths] as p1
		WHERE new_cases = (	SELECT Max(new_cases)
							FROM [ProjectPortfolio].[dbo].[covid_deaths] as p2
							WHERE p1.location = p2.location
									AND new_cases > 0
									AND continent IS NOT NULL)
		ORDER BY new_cases DESC;

--Total Population vs Vaccinations
--Shows Percentage fo Population that has received at least one Covid vaccine
SELECT	d.continent,
		d.location,
		d.date,
		d.population,
		v.new_vaccinations,
		SUM(CONVERT(float,v.new_vaccinations)) OVER (Partition by d.Location Order by d.location, d.Date) as RollingPeopleVaccinated
FROM ProjectPortfolio.dbo.covid_deaths AS d
	JOIN ProjectPortfolio.dbo.covid_vaccinations AS v
	On d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY 2,3;

/*
Using a CTE to add a rolling percent vaccinated to the previous query.
*/
WITH PopvsVac AS
(
SELECT	d.continent,
		d.location,
		d.date,
		d.population,
		v.new_vaccinations,
		SUM(CONVERT(float,v.new_vaccinations)) OVER (Partition by d.Location Order by d.location, d.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM ProjectPortfolio.dbo.covid_deaths AS d
JOIN ProjectPortfolio.dbo.covid_vaccinations AS v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS RollingPercentVaxxed
FROM PopvsVac
ORDER BY 2,3;

--Creating a View to store for later visulaizations

CREATE VIEW PercentPopulationVaccinated AS
	SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
		SUM(CONVERT(float, v.new_vaccinations)) OVER (Partition by d.location ORDER BY d.location, d.date) AS RollingPeopleVaccinated
	FROM [ProjectPortfolio].[dbo].[covid_deaths] AS d
	INNER JOIN [ProjectPortfolio].[dbo].[covid_vaccinations] AS v
		ON d.location = v.location
		AND d.date = v.date
	WHERE d.continent IS NOT NULL;