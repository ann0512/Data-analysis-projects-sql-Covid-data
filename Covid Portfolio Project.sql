--Data from https://ourworldindata.org/covid-deaths is used here for analysis
--This is global Covid data as of date November 24, 2021

SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths

--Total cases vs total deaths
--Shows the likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, (total_deaths / NULLIF(total_cases,0))*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2

--Total cases vs population
--Shows what percentage of population got Covid
SELECT location, date, population, total_cases, (total_cases / NULLIF(population,0))*100 AS PercentageInfection
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
ORDER BY 1,2

--countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, (MAX(total_cases) / NULLIF(population,0))*100 AS PercentageInfection
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentageInfection DESC

--countries with highest death count per population
SELECT location, continent, SUM(new_deaths) AS totaldeathcount
FROM portfolioproject..coviddeaths
WHERE continent != ''
GROUP BY location, continent
ORDER BY totaldeathcount DESC

--Let's break things down by continent
--total deaths in continents
SELECT continent, SUM(new_deaths) AS totaldeathcount
FROM portfolioproject..coviddeaths
WHERE continent != ''
GROUP BY continent
ORDER BY totaldeathcount DESC

--Global Numbers
SELECT date, SUM(new_cases) AS NewCasesOfTheDay, SUM(SUM(new_cases)) OVER (ORDER BY date) AS TotalCases, 
	SUM(new_deaths) AS NewDeaths, SUM(SUM(new_deaths)) OVER (ORDER BY date) AS TotalDeaths,
	(SUM(SUM(new_deaths)) OVER (ORDER BY date))/NULLIF((SUM(SUM(new_cases)) OVER (ORDER BY date)),0)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent != ''
GROUP BY date
ORDER BY date

--Vaccination data
SELECT *
FROM PortfolioProject..CovidVaccinations
ORDER BY 3,4

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) 
	AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent != ''
ORDER BY 2,3


-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) 
	AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent != ''
)
SELECT *, CAST(RollingPeopleVaccinated AS FLOAT)/NULLIF(Population,0)*100 AS VaccPercentage
FROM PopvsVac
--WHERE location LIKE 'India'



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date date,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) 
	AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent != ''

Select *, CAST(RollingPeopleVaccinated AS FLOAT)/NULLIF(Population,0)*100 AS VaccPercentage
From #PercentPopulationVaccinated
--WHERE location LIKE 'India'
ORDER BY 2,3


-- Creating View to store data for later visualizations

Create View PopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) 
	AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent != ''

SELECT *
FROM PopulationVaccinated
