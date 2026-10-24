# UK Retail Sales & Inflation Analysis (2017–2023)

## Project Overview
This project analyses the impact of the UK cost-of-living crisis on retail sales across different sectors. It uses R to clean ONS retail sales data and CPIH/HCI inflation data, conducts descriptive statistics, correlation analysis, and sector-by-sector linear regression models, and visualises the results using ggplot2.

## Data Sources
**Retail Sales:** ONS Retail Sales Index (Chained volume, seasonally adjusted).
**Inflation:** ONS CPIH indices and Household Cost Index (HCI).
*(Note: The raw data files are included for reproducibility. Cleaned datasets are provided as _clean.csv files).*


## 📊 Visualisations & Key Findings

### 1. Retail Sales Trends Over Time
[Retail Trend Annotated](retail_trend_annotated.png)
Figure 1: UK Retail Sales Volume (2017–2023) with key events marked. The chart clearly shows the massive dip during the March 2020 pandemic lockdown, followed by a recovery. However, right as the inflation surge hits in late 2021, sales volume begins to stagnate and drop again.

[Retail Trend Faceted](retail_trend_faceted.png)
Figure 2: Retail Sales by Sector (Faceted). By splitting the sectors, we can see that while online and food sales grew during the crisis, sectors like "Clothing" and "Household Goods" suffered significant declines.

### 2. The Inflation Surge
[Inflation Annotated Chart](inflation_annotated_chart.png)
Figure 3: CPI vs Household Cost Index (HCI). This chart highlights the timeline of the crisis. We can see a dramatic surge starting in late 2021 and peaking in early 2023. Notably, the Household Cost Index (HCI) rose much faster and higher than the standard Consumer Prices Index (CPI), showing the real pressure on households.

[CPIH Trend Chart](cpih_trend_chart.png)
Figure 4: CPIH Indices by Category. Food and Housing inflation (essential items) skyrocketed compared to other categories, severely impacting household disposable income.

### 3. Before vs During the Crisis
[Retail Change Chart](retail_change_chart.png)
Figure 5: Change in Average Retail Index (Before: 2017-2019 vs During: 2021-2023). This bar chart shows the absolute change in sales. "Clothing" and "Household Goods" saw the biggest negative changes, while "Food" and "Online" saw positive growth.

[Inflation Change Chart](inflation_change_chart.png)
Figure 6: Change in Inflation Rates (Before vs During). Shows how much each inflation measure increased between the two periods, confirming that the crisis represented a massive macroeconomic shift.

### 4. Correlation & Regression Analysis
[Correlation HCI Chart](correlation_hci_chart.png)
Figure 7: Correlation between Retail Sales and HCI by Sector. This shows how strongly each sector's sales are negatively correlated with inflation. Non-essential retail sectors show the strongest negative correlations.

[Regression HCI Effect](regression_hci_effect.png)
Figure 8: Regression Analysis (HCI Coefficient). Using linear models, this chart shows the actual impact of HCI on sales while holding other CPIH variables constant. A negative value means sales fall as inflation rises. "Clothing" and "Household Goods" are the most sensitive to inflation.

---

## 💻 Key Files
Dissertation.R: The main R script for data cleaning, merging, analysis, and visualization.
regression_by_sector.csv: Statistical results showing how inflation impacts each sector.
correlation_by_sector.csv: Correlation matrix for all sectors.

##  How to Run
Ensure you have the required R packages installed (`readxl`, `tidyr`, `dplyr`, `lubridate`, `janitor`, `ggplot2`, `broom`, `lmtest`, `car`).
Open Dissertation.R in RStudio.
Run the script to reproduce the analysis and charts.

---


## Conclusion & Recommendations

Based on the data and regression analysis, it is clear that the cost-of-living crisis severely damaged the UK retail sector, but it did not affect all sectors equally. 

**Key Takeaways:**
**Essentials vs. Non-Essentials:** When inflation (specifically Food and Housing) surged, consumers had no choice but to spend their money on necessities. As a result, "non-essential" sectors like Clothing and Household Goods saw the sharpest decline in sales.
**The HCI Impact:** The Household Cost Index (HCI) proved to be a highly accurate predictor of retail decline. As the HCI went up, retail sales went down.

**Proposed Solutions (What can be done?):**
If a similar crisis happens in the future, here are three practical solutions based on this analysis:

**Targeted Tax Cuts:** The government could temporarily reduce VAT or taxes on essential items (like food, heating, and fuel). By lowering the tax on essentials, households keep more of their money, allowing them to continue spending on non-essential retail and keeping the economy moving.
**Targeted Support for Vulnerable Households:** Because the data shows that non-essential retail suffers the most, the government should provide direct financial support (like energy grants) to low-income families. This prevents them from cutting all discretionary spending, which protects retail jobs.
**Support for Retailers:** The government could offer business rates relief for physical retail stores (especially clothing and household goods) which were hit the hardest by the drop in consumer spending. 

**Final Thought:** 
Inflation is not just a number on a chart, it is a household budget crisis. The data proves that when inflation rises, the first thing people cut is their retail spending. Therefore, keeping inflation low, especially for essentials is vital for the health of the retail economy.
