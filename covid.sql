Select *
From Covid_Proj..CovidsDeaths$
Where continent is not null
order by 3,4

--Select *
--From Covid_Proj..CovidVaccinations$
--order by 3,4

-- Select Data that we are going to be using
Select Location, date, total_cases, new_cases, total_deaths, population
From Covid_Proj..CovidsDeaths$
order by 1,2

-- Total Cases vs Total Deaths
SELECT Location, date, total_cases, total_deaths,
  CAST(total_deaths AS FLOAT) / CAST(total_cases AS FLOAT) * 100 AS DeathPercentage
FROM Covid_Proj..CovidsDeaths$
Where location like '%states%'
ORDER BY 1, 2

-- Total Cases vs Population
Select Location, date, total_cases, total_deaths, population, (total_cases/population)*100 as PercentPopulationInfected
From Covid_Proj..CovidsDeaths$
Where location like '%states%'
order by 1,2

-- Countries with Highest Infection Rate compared to Population
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
FROM Covid_Proj..CovidsDeaths$
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc

-- Countries with Highest Death Count per Population
Select Location, MAX(cast (total_deaths as int)) as TotalDeathCount
FROM Covid_Proj..CovidsDeaths$
--Where location like '%states%'
Where continent is not null
Group by Location
order by TotalDeathCount desc

-- Looking at continents with the highest death count per population
Select continent, MAX(cast (total_deaths as int)) as TotalDeathCount
FROM Covid_Proj..CovidsDeaths$
--Where location like '%states%'
Where continent is not null
Group by continent
order by TotalDeathCount desc



-- Global numbers
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
FROM Covid_Proj..CovidsDeaths$
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2


-- Total Population vs Vaccinations
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM
    Covid_Proj..CovidsDeaths$ dea
JOIN
    Covid_Proj..CovidVaccinations$ vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL
ORDER BY
    2, 3


-- With CTE
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
    SELECT
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
    FROM
        Covid_Proj..CovidsDeaths$ dea
    JOIN
        Covid_Proj..CovidVaccinations$ vac ON dea.location = vac.location AND dea.date = vac.date
    WHERE
        dea.continent IS NOT NULL
)
SELECT
    *,
    CASE
        WHEN Population > 0 THEN
            CASE
                WHEN RollingPeopleVaccinated > Population THEN 100.0
                ELSE (CAST(RollingPeopleVaccinated AS FLOAT) / CAST(Population AS FLOAT)) * 100
            END
        ELSE NULL
    END AS PercentageVaccinated
FROM
    PopvsVac;




Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Covid_Proj..CovidsDeaths$ dea
Join Covid_Proj..CovidVaccinations$ vac
    On dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not null;

-- Temp table
DROP TABLE IF EXISTS #PercentPopulationVaccinated;
CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO #PercentPopulationVaccinated
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM
    Covid_Proj..CovidsDeaths$ dea
JOIN
    Covid_Proj..CovidVaccinations$ vac
    ON dea.location = vac.location AND dea.date = vac.date;

-- Rest of your script
SELECT
    *,
    (CAST(RollingPeopleVaccinated AS FLOAT) / CAST(Population AS FLOAT)) * 100 AS PercentageVaccinated
FROM
    #PercentPopulationVaccinated;

