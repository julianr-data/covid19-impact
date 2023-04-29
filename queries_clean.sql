--- INFECTIONS AND MORTALITY ---

-- Rolling reported cases vs. population (optional: in one country)
-- i.e. what percentage of population got covid according to official reports
SELECT location, date, total_cases as rolling_reported_cases, population, (total_cases/population)*100 as infection_percentage
FROM covid_death
WHERE location LIKE 'Argentina'
ORDER BY 1, 2 ASC

-- Rolling reported cases vs. population (by country, per month)
-- i.e. what percentage of population got covid according to official reports
SELECT location, date, total_cases as rolling_reported_cases, population, (total_cases/population)*100 as infection_percentage
FROM covid_death
WHERE continent IS NOT NULL AND total_cases IS NOT NULL
ORDER BY 1, 2 ASC

-- Rolling reported cases vs. deaths (optional: in one country)
-- i.e. likelihood of dying if you get the virus
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as fatal_percentage
FROM covid_death
WHERE location LIKE 'Argentina'
ORDER BY 1, 2 DESC

-- Total cases vs. population (by country)
-- i.e. percentage of population of a country infected 
SELECT location, population, MAX(cast(total_cases as int)) as highest_infection_count, MAX((total_cases/population))*100 as max_contagion_percentage
FROM covid_death
WHERE continent IS NOT NULL  AND total_cases IS NOT NULL
GROUP BY location, population
ORDER BY 1

-- Total deaths vs. population (by country)
-- i.e countries with highest death rate when considering their entire population (not just infected)
SELECT location, population, MAX(cast(total_deaths as int)) as max_death_count, MAX((total_deaths/population))*100 as max_death_percentage
FROM covid_death
WHERE continent is not null
GROUP BY location
ORDER BY max_death_percentage DESC

-- Total deaths (by country)
-- i.e. number of deaths (absolute value)
SELECT location, MAX(cast(total_deaths as int)) as total_deaths_sofar
FROM covid_death
WHERE continent IS NOT NULL 
GROUP BY location
ORDER BY total_deaths_sofar DESC

-- Total deaths (by continent)
-- Method 1:
SELECT location, MAX(cast(total_deaths as int)) as total_deaths_sofar
FROM covid_death
WHERE continent IS NULL 
GROUP BY location
ORDER BY total_deaths_sofar DESC

-- Method 2:
SELECT continent, sum(cast(new_deaths as int))
FROM covid_death
WHERE continent IS NOT NULL
GROUP BY continent

-- Evolution of infection and death (daily, worldwide)
SELECT date, SUM(cast(new_cases as int)), SUM(cast(new_deaths as int))
FROM covid_death
WHERE continent IS NOT NULL
GROUP BY date

-- Evolution of infection and death (monthly, worldwide)
-- More realiable, since in many countries certain "daily" reports can summarize info
-- from previous days which are otherwise recorded as uneventful
-- (e.g. a whole week with 0 cases and 0 deaths, which get all recorded on Saturday)
SELECT date, SUM(cast(new_cases as int)), SUM(cast(new_deaths as int))
FROM covid_death
WHERE continent IS NOT NULL
GROUP BY STRFTIME("%m-%Y", date)
ORDER BY date


-- Infection vs. death (by month, worldwide)
-- i.e. how many infected people died globally, per month
SELECT date, SUM(cast(new_cases as int)) as daily_cases, SUM(cast(new_deaths as int)) as daily_deaths, (SUM(cast(new_deaths as int)) / SUM(new_cases))*100 as infection_vs_death_percentage
FROM covid_death
WHERE continent IS NOT NULL
GROUP BY STRFTIME("%m-%Y", date)
ORDER BY date

--- Total cases vs. deaths (worldwide)
SELECT SUM(cast(new_cases as int)) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, (SUM(cast(new_deaths as int)) / SUM(new_cases))*100 as infection_vs_death_percentage
FROM covid_death
WHERE continent IS NOT NULL
/*GROUP BY STRFTIME("%m-%Y", date)
ORDER BY date*/

--- VACCINATIONS ---

-- Vaccinations rolling count, looking at one specific country
SELECT cd.location, cd.date, cd.population, cv.new_vaccinations, SUM(CAST(cv.new_vaccinations AS INT)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS rolling_vacc_count
FROM covid_death cd
	JOIN covid_vacc cv 
		ON cd.location = cv.location 
		AND cd.date = cv.date 
WHERE cd.continent IS NOT NULL AND cd.location LIKE "Argentina"
ORDER BY 2, 3
	
-- Vaccinations and percentage of population vaccinated (rolling), for one specific country
WITH ArgVacs (Location, Date, Population, new_vaccs, rolling_vacc_count)
AS
(SELECT cd.location, cd.date, cd.population, cv.new_vaccinations, SUM(CAST(cv.new_vaccinations AS INT)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS rolling_vacc_count
FROM covid_death cd
	JOIN covid_vacc cv 
		ON cd.location = cv.location 
		AND cd.date = cv.date 
WHERE cd.continent IS NOT NULL AND cd.location LIKE "Argentina"
ORDER BY 2, 3)
SELECT *, (rolling_vacc_count/Population)*100 AS rolling_vacc_percentage
FROM ArgVacs

-- New daily vaccinations, rolling count of vaccinations and rolling percentage of people vaccinated (per country)
-- Using CTE
WITH WorldPopVsVac (Continent, Location, Date, Population, new_vaccs, rolling_vacc_count)
AS
(SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, SUM(CAST(cv.new_vaccinations AS INT)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS rolling_vacc_count
FROM covid_death cd
	JOIN covid_vacc cv 
		ON cd.location = cv.location 
		AND cd.date = cv.date 
WHERE cd.continent IS NOT NULL
ORDER BY 2, 3)
SELECT *, (rolling_vacc_count/Population)*100 AS rolling_vacc_percentage
FROM WorldPopVsVac

