-- Create Database
CREATE DATABASE ENERGYDB2;
USE ENERGYDB2;

-- 1. Country Table
CREATE TABLE country (
    CID VARCHAR(10) PRIMARY KEY,
    Country VARCHAR(100) UNIQUE
);

-- Country Table
SELECT * FROM COUNTRY;
DESCRIBE COUNTRY;

-- 2. Emission Table
CREATE TABLE emission_3 (
    country VARCHAR(100),
    energy_type VARCHAR(50),
    year INT,
    emission INT,
    per_capita_emission DOUBLE,
    FOREIGN KEY (country) REFERENCES country(Country)
);

-- Emission Table
SELECT * FROM emission_3;
DESCRIBE emission_3;

-- 3. Population Table
CREATE TABLE population (
    country VARCHAR(100),
    year INT,
    Value DOUBLE,
    FOREIGN KEY (country) REFERENCES country(Country)
);

-- Population Table
SELECT * FROM population;
DESCRIBE population;

-- 4. Production Table
CREATE TABLE production (
    country VARCHAR(100),
    energy VARCHAR(50),
    year INT,
    production INT,
    FOREIGN KEY (country) REFERENCES country(Country)
);

-- Production Table
SELECT * FROM production;
DESCRIBE production;

-- 5. GDP Table
CREATE TABLE gdp_3 (
    Country VARCHAR(100),
    year INT,
    Value DOUBLE,
    FOREIGN KEY (Country) REFERENCES country(Country)
);

-- GDP Table
SELECT * FROM gdp_3;
DESCRIBE gdp_3;

-- 6. Consumption Table
CREATE TABLE consumption (
    country VARCHAR(100),
    energy VARCHAR(50),
    year INT,
    consumption INT,
    FOREIGN KEY (country) REFERENCES country(Country)
);

-- Consumption Table
SELECT * FROM consumption;
DESCRIBE consumption;


-- Data Analysis Questions:
-- General & Comparative Analysis:
-- 1. What is the total emission per country for the most recent year available?

SELECT country, SUM(emission) AS total_emission
FROM emission_3
WHERE year = (SELECT MAX(year) FROM emission_3)
GROUP BY country
ORDER BY total_emission DESC;

-- 2. What are the top 5 countries by GDP in the most recent year?

SELECT Country, Value AS GDP
FROM gdp_3
WHERE year = (SELECT MAX(year) FROM gdp_3)
ORDER BY GDP DESC
LIMIT 5;

-- 3. Compare energy production and consumption by country and year?

SELECT p.country, p.year,
       SUM(p.production) AS total_production,
       SUM(c.consumption) AS total_consumption,
       (SUM(p.production) - SUM(c.consumption)) AS balance
FROM production p
JOIN consumption c 
     ON p.country = c.country AND p.year = c.year
GROUP BY p.country, p.year
ORDER BY p.year DESC, p.country;

-- 4. Which energy types contribute most to emissions across all countries?

SELECT energy_type, SUM(emission) AS total_emission
FROM emission_3
GROUP BY energy_type
ORDER BY total_emission DESC;


-- Trend Analysis Over Time
-- 5. How have global emissions changed year over year?

SELECT year, SUM(emission) AS global_emission
FROM emission_3
GROUP BY year
ORDER BY year;

-- 6. What is the trend in GDP for each country over the given years?

SELECT Country, year, Value AS GDP
FROM gdp_3
ORDER BY Country, year;

-- 7. How has population growth affected total emissions in each country?

SELECT p.country, 
       p.year, 
       MAX(p.Value) AS population, 
       SUM(e.emission) AS total_emission
FROM population p
JOIN emission_3 e 
     ON p.country = e.country 
    AND p.year = e.year
GROUP BY p.country, p.year;

-- 8. Has energy consumption increased or decreased over the years for major economies?

SELECT country, year, SUM(consumption) AS total_consumption
FROM consumption
WHERE country IN ('China','United States','India','Russia','Japan')
GROUP BY country, year
ORDER BY country, year;

-- 9. What is the average yearly change in emissions per capita for each country?

SELECT country,
       AVG(yearly_change) AS avg_yearly_change_per_capita
FROM (
    SELECT e.country,
           e.year,
           (e.emission / p.Value) AS per_capita_emission,
           ((e.emission / p.Value) - 
            LAG(e.emission / p.Value) OVER (PARTITION BY e.country ORDER BY e.year)) AS yearly_change
    FROM emission_3 e
    JOIN population p ON e.country = p.country AND e.year = p.year
) AS t
WHERE yearly_change IS NOT NULL
GROUP BY country
ORDER BY avg_yearly_change_per_capita DESC;


-- Ratio & Per Capita Analysis
-- 10. What is the emission-to-GDP ratio for each country by year?

SELECT 
    e.country,
    e.year,
    SUM(e.emission) / g.Value AS emission_to_GDP_ratio
FROM emission_3 e
JOIN gdp_3 g 
    ON e.country = g.Country AND e.year = g.year
GROUP BY e.country, e.year, g.Value
ORDER BY e.country, e.year;

-- 11. What is the energy consumption per capita for each country over the last decade?

SELECT 
    c.country,
    c.year,
    SUM(c.consumption) / p.Value AS consumption_per_capita
FROM consumption c
JOIN population p 
    ON c.country = p.country AND c.year = p.year
WHERE c.year >= YEAR(CURDATE()) - 10
GROUP BY c.country, c.year, p.Value
ORDER BY c.country, c.year;

-- 12. How does energy production per capita vary across countries?

SELECT 
    p.country,
    p.year,
    SUM(p.production) / pop.Value AS production_per_capita
FROM production p
JOIN population pop 
    ON p.country = pop.country AND p.year = pop.year
GROUP BY p.country, p.year, pop.Value
ORDER BY p.country, p.year;

-- 13. Which countries have the highest energy consumption relative to GDP?

SELECT 
    c.country,
    c.year,
    SUM(c.consumption) / g.Value AS consumption_to_GDP_ratio
FROM consumption c
JOIN gdp_3 g 
    ON c.country = g.Country AND c.year = g.year
GROUP BY c.country, c.year, g.Value
ORDER BY consumption_to_GDP_ratio DESC;

-- 14. What is the correlation between GDP growth and energy production growth?

WITH gdp_clean AS (
    SELECT country, year, AVG(value) AS gdp_value FROM gdp_3 GROUP BY country, year),
gdp_growth AS (
    SELECT country, year,
        (gdp_value - LAG(gdp_value) OVER (PARTITION BY country ORDER BY year)) 
            / NULLIF(LAG(gdp_value) OVER (PARTITION BY country ORDER BY year), 0) AS gdp_growth_pct
    FROM gdp_clean),
prod_clean AS (
    SELECT country, year, SUM(production) AS total_production FROM production GROUP BY country, year),
prod_growth AS (
    SELECT country, year,
        (total_production - LAG(total_production) OVER (PARTITION BY country ORDER BY year))
            / NULLIF(LAG(total_production) OVER (PARTITION BY country ORDER BY year), 0) AS prod_growth_pct
    FROM prod_clean)
SELECT
    g.country, g.year,
    ROUND(g.gdp_growth_pct, 4) AS gdp_growth_pct, ROUND(p.prod_growth_pct, 4) AS prod_growth_pct
FROM gdp_growth g JOIN prod_growth p ON g.country = p.country AND g.year = p.year
WHERE g.gdp_growth_pct IS NOT NULL AND p.prod_growth_pct IS NOT NULL
ORDER BY g.country, g.year;


-- Global Comparisons
-- 15. What are the top 10 countries by population and how do their emissions compare?

SELECT 
    p.country,
    p.Value AS population,
    SUM(e.emission) AS total_emission
FROM population p
JOIN emission_3 e
    ON p.country = e.country AND p.year = e.year
WHERE p.year = 2023
GROUP BY p.country, p.Value
ORDER BY p.Value DESC
LIMIT 10;

-- 16. Which countries have improved (reduced) their per capita emissions the most over the last decade?

SELECT 
    e.country,
    MAX(CASE WHEN e.year = 2023 THEN e.emission / p.Value END) AS latest_pc_emission,
    MAX(CASE WHEN e.year = 2020 THEN e.emission / p.Value END) AS earliest_pc_emission,
    (MAX(CASE WHEN e.year = 2020 THEN e.emission / p.Value END) -
     MAX(CASE WHEN e.year = 2023 THEN e.emission / p.Value END)) AS reduction
FROM emission_3 e
JOIN population p
    ON e.country = p.country AND e.year = p.year
WHERE e.year IN (2020, 2023)
GROUP BY e.country
HAVING reduction > 0
ORDER BY reduction DESC;

-- 17. What is the global share (%) of emissions by country?

SELECT 
    e.country,
    SUM(e.emission) AS country_emission,
    ROUND(SUM(e.emission) / (SELECT SUM(emission) FROM emission_3 WHERE year = 2023) * 100, 2) AS global_share_pct
FROM emission_3 e
WHERE e.year = 2023
GROUP BY e.country
ORDER BY global_share_pct DESC;

-- 18. What is the global average GDP, emission, and population by year?

SELECT y.year,
    ROUND(g.avg_gdp, 2) AS avg_gdp,
    ROUND(e.avg_emission, 2) AS avg_emission,
    ROUND(p.avg_population, 2) AS avg_population
FROM 
    (SELECT DISTINCT year FROM gdp_3) y
LEFT JOIN 
    (SELECT year, AVG(Value) AS avg_gdp
     FROM gdp_3
     GROUP BY year) g ON y.year = g.year
LEFT JOIN 
    (SELECT year, AVG(emission) AS avg_emission
     FROM emission_3
     GROUP BY year) e ON y.year = e.year
LEFT JOIN 
    (SELECT year, AVG(Value) AS avg_population
     FROM population
     GROUP BY year) p ON y.year = p.year
ORDER BY y.year;

