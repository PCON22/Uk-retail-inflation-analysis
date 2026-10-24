UK Retail Sales & Inflation Analysis (2017–2023)

## Project Overview
This project analyses the impact of the UK cost-of-living crisis on retail sales across different sectors. It uses R to clean ONS retail sales data and CPIH/HCI inflation data, conducts descriptive statistics, correlation analysis, and sector-by-sector linear regression models, and visualises the results using `ggplot2`.

## Data Sources
**Retail Sales:** ONS Retail Sales Index (Chained volume, seasonally adjusted).
**Inflation:** ONS CPIH indices and Household Cost Index (HCI).
(Note: The raw data files were removed to keep the repository clean. The cleaned datasets are provided as `_clean.csv` files).*

## Key Files
Dissertation.R`: The main R script for data cleaning, merging, analysis, and visualization.
regression_by_sector.csv`: Results showing how inflation impacts different sectors.
retail_trend_annotated.png`: Visualisation of retail trends highlighting the pandemic and inflation surge.
regression_hci_effect.png`: Chart showing the effect of HCI on sales by sector.

## How to Run
1. Ensure you have the required R packages installed (`readxl`, `tidyr`, `dplyr`, `lubridate`, `janitor`, `ggplot2`, `broom`, `lmtest`, `car`).
2. Open Dissertation.R in RStudio.
3. Run the script to reproduce the analysis and charts.
