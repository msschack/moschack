--SELECT TOP 100 *
--FROM COVID_Vaccination
--ORDER BY location

--SELECT TOP 100 *
--FROM COVID_Deaths
--ORDER BY location

--Selecting Data we need for this Project

--SELECT location, date, total_cases, new_cases, total_deaths, population
--FROM COVID_Deaths
--ORDER BY 1, 2

--Converting Colunms from VARCHAR to Float to get calculations

--EXEC sp_help 'COVID_Deaths';

--ALTER TABLE COVID_Deaths
--ALTER COLUMN Total_Deaths float

--ALTER TABLE COVID_Deaths
--ALTER COLUMN Total_cases float

--Now should be able to make calculations on columns to gather understand specific data we need
--This gives us an idea of the percent of the cases resulted in death

--SELECT location, date, population, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
--FROM COVID_Deaths
--WHERE location LIKE 'United States'
--ORDER BY date

--Now we will look at the percent of cases by population.  This has been isolated to the United States.

--SELECT location, date, population, total_cases, (total_cases/population)*100 AS PopulationAffected
--FROM COVID_Deaths
--WHERE location LIKE 'United States'
--ORDER BY date

--Looking at countries with the highest cases compared to population

--SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
--FROM COVID_Deaths
--GROUP BY Population, location
--ORDER BY PercentPopulationInfected DESC

--Countries with the highest deaths to population. (Saw that Continents were mixed in to countries.
--Had to remove them)
--SELECT location, MAX(Total_Deaths) AS HighestDeathCount
--FROM COVID_Deaths
--WHERE continent IS NOT NULL
--GROUP BY Population, location
--ORDER BY HighestDeathCount DESC

--Now we are going to look at these from the top level by continent. 

--SELECT location, MAX(Total_Deaths) AS HighestDeathCount
--FROM COVID_Deaths
--WHERE continent IS NULL
--GROUP BY location
--ORDER BY HighestDeathCount DESC

--Global Numbers-this will give us the total new cases and new deaths by date. 
--Since some values were in the divisor were 0, I had to add NULLIF to compute the percentages

--SELECT  date, SUM(new_cases), SUM(new_deaths), SUM(new_deaths)/SUM(NULLIF(new_cases,0))*100 AS DeathPercentage
--FROM COVID_Deaths
--WHERE Continent IS NOT NULL
--GROUP BY date
--ORDER BY 1, 2

--In order just to see what the total for the world as of April 2023

--SELECT SUM(new_cases), SUM(new_deaths), SUM(new_deaths)/SUM(NULLIF(new_cases,0))*100 AS DeathPercentage
--FROM COVID_Deaths
--WHERE Continent IS NOT NULL
----GROUP BY date
--ORDER BY 1, 2

--Start looking at other table to start examining possible correlations between cases, deaths and vaccinations.
---Going to start by joining tables to compare and make sure there are matches

--SELECT *
--FROM COVID_Deaths dea
--JOIN COVID_Vaccination vac
--	on dea.location = vac.location
--	and dea.date = vac.date

---Now, going to start looking at total vaccinations vs. total populations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM COVID_Deaths dea
JOIN COVID_Vaccination vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1, 2, 3

--In order to get a running total of daily new vaccination by country we will use SUM and PARTITION

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
		AS RollingPeopleVaccinated
FROM COVID_Deaths dea
JOIN COVID_Vaccination vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
AND dea.location LIKE '%states%'   --Used in order to refine to check totals
ORDER BY 1, 2, 3

--Want to be able to see percentages of vaccinated population and total that.  Will use a CTE first.

WITH PopvsVac (Continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
		AS RollingPeopleVaccinated
FROM COVID_Deaths dea
JOIN COVID_Vaccination vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL)
SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentPeopleVaccinated
FROM PopvsVac

--With a CTE table we may be limited in its use and have to continue to use it.  If we create a temporary table
--we won't have that problem and will be able to continually use it. 

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
		AS RollingPeopleVaccinated
FROM COVID_Deaths dea
JOIN COVID_Vaccination vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentPeopleVaccinated
FROM #PercentPopulationVaccinated

--Creating a view to save for later and be able to call up. 

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
		AS RollingPeopleVaccinated
FROM COVID_Deaths dea
JOIN COVID_Vaccination vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL


