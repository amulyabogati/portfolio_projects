# Portfolio Project: Apartment Selection

## Overview

This SQL project focuses on apartment selection for the final session of an MBA program. It utilizes various SQL techniques and geospatial analysis to identify potential locations based on criteria such as distance, population density, and rental costs.

### Situation
Apartment hunting for the final session of an MBA program, aiming to find suitable locations near a university while considering factors like rental costs, commute time, and population density.

### Task
Utilize SQL skills to analyze geographic and rental data, calculate distances, and identify potential locations that meet specified criteria. The goal is to create a comprehensive analysis to aid decision-making in the apartment selection process.

### Action
The project involves the following key steps:
1. **Data Setup:** Creation of tables for geographical and rental data.
2. **Geospatial Analysis:** Calculating distances between potential locations and a university using the Haversine formula.
3. **Rental Analysis:** Analyzing rental data to understand average costs and variations.
4. **Location Identification:** Identifying potential apartment locations based on criteria such as distance, population density, and rental costs.
5. **Final Analysis:** Calculating overall balance considering factors like salary, rent, and other monthly expenses.

### Result
The project provides a structured analysis of potential apartment locations, considering various factors critical for decision-making. The final results include a view of locations that meet specified criteria, facilitating an informed choice for the apartment selection process.

## SQL Skills Utilized

- Fundamental SQL operations (SELECT, FROM, WHERE, ORDER BY)
- Common Table Expressions (CTEs)
- Window Functions
- Temporary Tables
- Function creation for geospatial analysis (Haversine formula)
- Data type conversions
- Statistical analysis (AVG, STDDEV)
- Randomness introduction for simulation
- Modular code structure for readability and maintainability

## Data Source References

**US Zip Code Data:**
   - Source: SimpleMaps
   - Dataset: uszips.csv
   - URL: https://simplemaps.com/data/us-zips

**Fair Market Rent Data (FY24):**
   - Source: HUD User
   - Dataset: FY24_FMRs
   - URL: https://www.huduser.gov/portal/datasets/fmr.html#documents_2024
