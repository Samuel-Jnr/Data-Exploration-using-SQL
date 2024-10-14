--DATA EXPLORATION WITH SQL

USE PortFolioProjects

SELECT *
FROM PortFolioProjects..CovidDeaths
ORDER BY 3, 4

SELECT *
FROM PortFolioProjects..CovidDeaths
ORDER BY 3, 4

--select country, date, total_cases, new_cases, total_deaths, population columns and sort them by country and date in ascending order
SELECT 
	country, 
	date, 
	total_cases, 
	new_cases, 
	total_deaths, 
	population
FROM PortFolioProjects..CovidDeaths
Where Continent IS NOT NULL
ORDER BY 1, 2


-- calculate the likelihood of death if infected by Covid-19  in Nigeria
----NULLIF function was applied to avoid "Divide by zero error", The NULLIF function returns NULL if the second argument is zero, preventing the division by zero error 

SELECT 
	country, 
	date, 
	total_cases, 
	total_deaths, 
	(total_deaths/Nullif(total_cases,0))*100 As DeathRate
FROM PortFolioProjects..CovidDeaths
WHERE country like '%Nigeria%'
ORDER BY 1, 2

-- Covid-19 Infection rate trend in Nigeria

SELECT 
	country, 
	date, 
	total_cases, 
	population, 
	(total_cases/Nullif(population,0))*100 As InfectionRate
FROM PortFolioProjects..CovidDeaths
Where country like '%Nigeria%'
and Continent IS NOT NULL
ORDER BY 1, 2

--infection rate trend of other countries sorted in descendng order 

SELECT 
	country, 
	population, 
	Max(total_cases) as HighestReportedCases,  
	Max((total_cases/Nullif(population,0)))*100 As InfectionRate
FROM PortFolioProjects..CovidDeaths
Where Continent IS NOT NULL
GROUP BY country, population
ORDER BY InfectionRate Desc

-- total reported death and Covid-19 death ratios by countries

SELECT
	country,
	TotalDeaths,
	TotalCases,
	(TotalDeaths/NULLIF(TotalCases,0))*100 AS DeathRatio
FROM
	(
		SELECT 
			country, 
			 MAX(CAST(total_deaths AS INT)) OVER (PARTITION BY country) AS TotalDeaths,
			 MAX(total_cases) OVER (PARTITION by country) AS TotalCases
        FROM 
            PortFolioProjects..CovidDeaths
	) AS Subquery
GROUP BY 
    country, TotalDeaths, TotalCases
ORDER BY 
    Country, TotalDeaths DESC;


-- Total Death by Continent

SELECT
	continent,
	ContinentTotalDeaths,
	ContinentTotalCases,
	(ContinentTotalDeaths/NULLIF(ContinentTotalCases,0))*100 AS ContinentDeathRatio
FROM
	(
		SELECT 
			continent, 
			 MAX(CAST(total_deaths AS INT)) OVER (PARTITION BY continent) AS ContinentTotalDeaths,
			 MAX(total_cases) OVER (PARTITION by continent) AS ContinentTotalCases
        FROM 
            PortFolioProjects..CovidDeaths
	) AS Subquery
GROUP BY 
    continent, ContinentTotalDeaths, ContinentTotalCases
ORDER BY 
    ContinentTotalDeaths DESC;

--continents with highest death count

SELECT 
		continent, 
		Max(Cast(total_deaths as INT)) as TotalDeathByContinent  
FROM PortFolioProjects..CovidDeaths
GROUP BY continent
ORDER BY TotalDeathByContinent Desc

--Using Joins
-- total population that have being vaccinnated 

SELECT 
		death.continent, 
		death.
		country, 
		Death.date, 
		death.population, 
		vac.new_vaccinations, 
		SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY death.country ORDER BY Death.country, Death.date) AS TotalVaccinated
FROM PortFolioProjects..CovidDeaths Death
	JOIN PortFolioProjects..CovidVaccination Vac
		ON Death.country = Vac.country
		and Death.date = Vac.date
ORDER BY 2,3

--checking for how many persons is vaccinated per country | Ceating CTE and Temp Table

--USE CTE

WITH PopVac 
			(
				continent, 
				country, 
				date, 
				population, 
				new_vaccinations, 
				Totalvaccinated
			)
AS
	(
		SELECT 
				death.continent, 
				death.
				country, 
				Death.date, 
				death.population, 
				vac.new_vaccinations, 
				SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY death.country ORDER BY Death.country, Death.date) AS Totalvaccinated
		FROM PortFolioProjects..CovidDeaths Death
			JOIN PortFolioProjects..CovidVaccination Vac
				ON Death.country = Vac.country
				and Death.date = Vac.date
	)

SELECT 
		*, 
		(Totalvaccinated/population)*100 AS PercentageTotalVaccinated
FROM PopVac
Where country = 'Nigeria'

--check for total vaccinated per continent

WITH PopVac 
			(
				continent, 
				date, 
				ContinentPopulation, 
				Totalvaccinated
			)
AS
	(
		SELECT 
				death.continent,  
				Death.date, 
				SUM(death.population) OVER (PARTITION BY death.continent)AS ContinentPopulation,  								
				SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY death.continent ORDER BY Death.continent, Death.date) AS Totalvaccinated								
		FROM PortFolioProjects..CovidDeaths Death
			JOIN PortFolioProjects..CovidVaccination Vac
				ON Death.country = Vac.country
				and Death.date = Vac.date
	)
SELECT 
		*, 
		(Totalvaccinated/ContinentPopulation)*100 AS PercentageTotalVaccinated
FROM PopVac


--USE TEMP TABLE

DROP TABLE IF exists #PercentPopulationvaccinated
CREATE TABLE #PercentPopulationvaccinated
			(
				continent nvarchar(255),
				country nvarchar(255),
				date Datetime,
				Population numeric,
				New_vaccination numeric,
				Totalvaccinated numeric
			)

INSERT INTO #PercentPopulationvaccinated
			SELECT 
					death.continent, 
					death.country, 
					Death.date, 
					death.population, 
					vac.new_vaccinations, 
					SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY death.country ORDER BY Death.country, Death.date) AS Totalvaccinated
			FROM PortFolioProjects..CovidDeaths Death
					JOIN PortFolioProjects..CovidVaccination Vac
						ON Death.country = Vac.country
							and Death.date = Vac.date


SELECT *, (Totalvaccinated/population)*100 AS PercentageTotalVaccinated
FROM #PercentPopulationvaccinated


--CREATE VIEWS | Views are permanent, Temp tables are not permanent
Create View DeathRateByCountry AS
SELECT country, Max(Cast(total_deaths as INT)) as HighestDeathRate  
FROM PortFolioProjects..CovidDeaths
--Where Location like '%Nigeria%'
GROUP BY country
--ORDER BY HighestDeathRate Desc | Views doesn't run with Order By clause

Select *
FROM DeathRateByCountry

Create View InfectionRate AS
SELECT 
	country, 
	date, 
	total_cases, 
	population, 
	(total_cases/Nullif(population,0))*100 As InfectionRate
FROM PortFolioProjects..CovidDeaths
Where Continent IS NOT NULL
