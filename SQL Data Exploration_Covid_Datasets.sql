/*
SQL Data Exploration using Covid 19

These are the skills used for this project: 
Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

SELECT * 
FROM CovidVaccinations;

SELECT * 
FROM PortfolioProject.dbo.CovidDeaths;

SELECT * 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4;

/*SELECT * 
FROM PortfolioProject..CovidVaccinations;*/

-- ANALYZING CovidDeaths DATASET


SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL;


-- Analysis of COVID-19 Impact by seeing Total Cases versus Total Deaths 
-- This query calculates the percentage of deaths among confirmed COVID-19 cases,
-- indicating the likelihood of dying from COVID-19 in a country.

-- Using CAST to ensure floating-point division and avoid integer division

SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS FLOAT) / CAST(total_cases AS FLOAT))*100 AS death_percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location like '%States%'
AND continent IS NOT NULL
Order by location, date;


-- Seeing Total Cases versus Population
-- This query calculates the percentage of the population that has been infected with COVID-19.

SELECT location, date, total_cases, population, (CAST(total_cases AS FLOAT) / CAST(population AS FLOAT))*100 AS infection_percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location like '%States%';


-- Identifying countries with the highest infection rates relative to their population size

SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((CAST(total_cases AS FLOAT) / CAST(population AS FLOAT)))*100 AS percentage_population_infected
FROM PortfolioProject.dbo.CovidDeaths
GROUP BY location, population
ORDER BY percentage_population_infected DESC;

-- Identifying countries with the highest death count relative to their population size

SELECT location, MAX(total_deaths) AS highest_deaths_count
FROM PortfolioProject.dbo.CovidDeaths
-- Filtering out null values from the Continent column 
-- to avoid incorrect entries like 'World' or misclassified continent names in the Location column
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY highest_deaths_count DESC;


-- BREAKING DATA DOWN BY CONTINENT
-- Displaying continents with the highest death count relative to population

SELECT continent, MAX(total_deaths) AS highest_deaths_count
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY highest_deaths_count DESC;


-- GLOBAL DAILY STATISTICS 
-- This query calculates the total new cases and new deaths across the world PER DAY
-- Using daily counts to compute the death percentage per day
/*Note: 
	Casting new_deaths and new_cases as DECIMAL(20, 2) to avoid integer division
	DECIMAL(20, 2) allows up to 20 digits in total, with 2 digits after the decimal point
	However, SQL query results may show more decimal places if not explicitly rounded
	To ensure the result ends with exactly 2 decimal places, we can use the 'ROUND()' function
	This ensures a precise calculation of the death percentage, avoiding rounding to 0. */

SELECT date, SUM(new_cases) AS total_new_cases, SUM(new_deaths) AS total_new_deaths,
	(CAST(SUM(new_deaths) AS DECIMAL(20, 2)) / CAST(SUM(new_cases) AS DECIMAL(20, 2))) * 100 AS daily_death_percentage_across_world
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;


-- Total across world without filtering on date

SELECT SUM(new_cases) AS total_new_cases, SUM(new_deaths) AS total_new_deaths,
	(CAST(SUM(new_deaths) AS DECIMAL(20, 2)) / CAST(SUM(new_cases) AS DECIMAL(20, 2))) * 100 AS daily_death_percentage_across_world
FROM CovidDeaths
WHERE continent IS NOT NULL;


-- GLOBAL CUMULATIVE STATISTICS 
-- This query calculates the cumulative global total cases, total deaths, and death percentage up to each date not new cases or new deaths per day

SELECT date, SUM(total_cases) AS total_cases_across_world, SUM(total_deaths) AS total_deaths_across_world,
	(CAST(SUM(total_deaths) AS DECIMAL(20, 2)) / CAST(SUM(total_cases) AS DECIMAL(20, 2))) * 100 AS death_percentage_across_world
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;


-- JOINING CovidVaccinations with CovidDeaths DATASET
-- Total Population VS Vaccinations
-- It calculates the rolling total of individuals who have received at least one Covid vaccine,
-- using a window function "PARTITION BY" to sum new vaccinations over time for each location 
-- (Simple words: rolling total of new vaccinations for each location over time.)

SELECT * 
FROM PortfolioProject.dbo.CovidVaccinations

SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccines.new_vaccinations, 
	SUM(CONVERT(int,vaccines.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date)
	AS rolling_people_vaccinated
FROM PortfolioProject.dbo.CovidDeaths deaths
JOIN PortfolioProject.dbo.CovidVaccinations vaccines
	ON deaths.location = vaccines.location 
	and deaths.date = vaccines.date
WHERE deaths.continent IS NOT NULL
ORDER BY 2,3;


-- This query calculates and shows the percentage of the population that has received at least one Covid vaccine.
-- Using a Common Table Expression (CTE) to perform calculations with the PARTITION BY clause in the previous query

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, Rolling_People_Vaccinated)
AS
(SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccines.new_vaccinations, 
	SUM(CONVERT(int,vaccines.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date)
	AS rolling_people_vaccinated
FROM PortfolioProject.dbo.CovidDeaths deaths
JOIN PortfolioProject.dbo.CovidVaccinations vaccines
	ON deaths.location = vaccines.location 
	and deaths.date = vaccines.date
WHERE deaths.continent IS NOT NULL
)

SELECT *, (CAST(Rolling_People_Vaccinated AS DECIMAL(20,2))/CAST(Population AS DECIMAL(20,2))) * 100 AS percent_population_vaccinated
FROM popvsvac;


-- USING TEMP(Temporary) TABLE FOR POPULATION VS VACCINATIONS
-- Creates a temporary table to calculate the rolling total of vaccinated individuals by location & date just like previous query

DROP TABLE IF EXISTS #PercentagePopulationVaccinated;
CREATE TABLE #PercentagePopulationVaccinated
(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_Vaccinations numeric,
	Rolling_People_vaccinated numeric
)
INSERT INTO #PercentagePopulationVaccinated
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccines.new_vaccinations, 
	SUM(CONVERT(int,vaccines.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date)
	AS rolling_people_vaccinated
FROM PortfolioProject.dbo.CovidDeaths deaths
JOIN PortfolioProject.dbo.CovidVaccinations vaccines
	ON deaths.location = vaccines.location 
	and deaths.date = vaccines.date


-- SELECTING FROM TEMP TABLE
-- This query selects data from the temporary table & calculates the percentage of the population vaccinated

SELECT *, (CAST(Rolling_People_Vaccinated AS DECIMAL(20,2))/CAST(Population AS DECIMAL(20,2))) * 100 AS percent_population_vaccinated
FROM #PercentagePopulationVaccinated;


-- CREATED VIEW (Virtual Table) FOR LATER VISUALIZATION
-- Run below command to make sure the view is created in current database
-- USE ProjectPortfolio;

CREATE VIEW dbo.PercentagePopulationVaccinated AS
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccines.new_vaccinations, 
	SUM(CONVERT(int,vaccines.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date)
	AS rolling_people_vaccinated
FROM PortfolioProject.dbo.CovidDeaths deaths
JOIN PortfolioProject.dbo.CovidVaccinations vaccines
	ON deaths.location = vaccines.location 
	and deaths.date = vaccines.date
WHERE deaths.continent IS NOT NULL;

