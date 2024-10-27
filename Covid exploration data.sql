select *
from Proyecto..['covid deaths$']

order by 3,4

select location, date, total_cases, new_cases, total_deaths,population
from Proyecto..['covid deaths$']
order by 1,2

-- TOTAL CASES VS TOTAL DEATHS
-- muestra la probable que chances que tendrias de morir si te daba covid en esos tiempos (PERU)
SELECT 
    location, 
    date, 
    total_cases, 
    total_deaths, 
    CASE 
        WHEN total_cases = 0 THEN 0
        ELSE (total_deaths / total_cases) * 100 
    END AS Deathpercentage
FROM Proyecto..['covid deaths$']
where location like '%peru%'
ORDER BY 1, 2;


--total casos vs poblacion
-- cuanto % de la poblacion le dio COVID

SELECT 
    location, 
    date, 
	population,
    total_cases, 
    CASE 
        WHEN total_cases = 0 THEN 0
        ELSE (total_cases / population) * 100 
    END AS Deathpercentage
FROM Proyecto..['covid deaths$']
where location like '%peru%'
ORDER BY 1, 2;

--Paises con mayor tasa de contagio en comparacion a su poblacion

SELECT 
    location, 
    population, 
    MAX(total_cases) AS InfectadosContador, 
    CASE 
        WHEN MAX(total_cases) = 0 THEN 0
        ELSE (MAX(total_cases) / population) * 100 
    END AS PorcentajePoblacionInfectada
FROM Proyecto..['covid deaths$']
GROUP BY location, population
ORDER BY PorcentajePoblacionInfectada desc

--Paises con mayor numero de muertes por Poblacion

SELECT 
    location, 
    MAX(cast(total_deaths as int)) AS totalMuertosContador
   
FROM Proyecto..['covid deaths$']
where continent is not null
GROUP BY location
ORDER BY totalMuertosContador desc

--por continente

--Mostrar el continente con mayor numero de muertos

SELECT 
    continent, 
    MAX(cast(total_deaths as int)) AS totalMuertosContador
   
FROM Proyecto..['covid deaths$']
where continent is not null
GROUP BY continent
ORDER BY totalMuertosContador desc

-- Numero Globales

SELECT 
    SUM(new_cases) AS total_cases,
    SUM(CAST(new_deaths AS int)) AS total_deaths,
    CASE 
        WHEN SUM(new_cases) = 0 THEN 0
        ELSE SUM(CAST(new_deaths AS int)) / SUM(new_cases) * 100 
    END AS PorcentajeMuertos
FROM Proyecto..['covid deaths$']
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1, 2;

--Total poblacion vs Vacunados

WITH PopvsVac (Continent, Location, Date, Population, new_vaccinations, PersonaVacunadas) AS (
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(CONVERT(bigint, ISNULL(vac.new_vaccinations, 0))) OVER (
            PARTITION BY dea.location 
            ORDER BY dea.location, dea.date
        ) AS PersonasVacunadas
    FROM 
        Proyecto..['covid deaths$'] dea
    JOIN 
        Proyecto..[covidVacunas$] vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE 
        dea.continent IS NOT NULL
    -- ORDER BY 2,3
)

SELECT *, (PersonaVacunadas/Population) *100
FROM PopvsVac;

--TEMP TABLE
DROP TABLE IF EXISTS #PorcentajePoblacionVacunada;

CREATE TABLE #PorcentajePoblacionVacunada (
    continent nvarchar(255),
    location nvarchar(255),
    date datetime,
    population numeric,
    new_vaccinations numeric, 
    PersonasVacunadas numeric
);

INSERT INTO #PorcentajePoblacionVacunada
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CONVERT(bigint, ISNULL(vac.new_vaccinations, 0))) OVER (
        PARTITION BY dea.location 
        ORDER BY dea.location, dea.date
    ) AS PersonasVacunadas
FROM 
    Proyecto..['covid deaths$'] dea
JOIN 
    Proyecto..[covidVacunas$] vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL;

SELECT *,
       (PersonasVacunadas / population) * 100 AS PorcentajePoblacionVacunada
FROM #PorcentajePoblacionVacunada;

--view

Create View PorcentajePoblacionVacunada as
SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(CONVERT(bigint, ISNULL(vac.new_vaccinations, 0))) OVER (
            PARTITION BY dea.location 
            ORDER BY dea.location, dea.date
        ) AS PersonaVacunadas
    FROM 
        Proyecto..['covid deaths$'] dea
    JOIN 
        Proyecto..[covidVacunas$] vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE 
        dea.continent IS NOT NULL
    -- ORDER BY 2,3

	select *
	from PorcentajePoblacionVacunada

	DROP VIEW IF EXISTS PorcentajePoblacionVacunada;
