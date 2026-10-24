

# DISSERTATION DATA CLEANING SCRIPT
# Cost-of-Living Crisis and UK Retail Performance (2017-2023)


####INSTALL AND LOAD PACKAGES####

install.packages(c("readxl", "tidyr", "dplyr", "lubridate", "janitor","ggplot2", "broom", "lmtest"))

library(readxl)
library(tidyr)
library(dplyr)
library(lubridate)
library(janitor)
library(ggplot2)
library(broom)
library(lmtest)

#####CLEAN RETAIL SALES INDEX####

retail_sales <- read_excel("retail-sales-index-time-series-v45-filtered-2026-10-03T16-58-36Z.xlsx",
                           sheet="Dataset",
                           skip=2)
print(names(retail_sales))

# clean column names

retail_sales <- clean_names(retail_sales)

print(names(retail_sales)[1:10])

# keep only what we need

retail_sfiltered <- retail_sales %>%
  filter(prices == "Chained volume of retail sales") %>%
  filter(seasonal_adjustment == "Seasonally Adjusted") %>%
  select(-geography,-geography_code,-seasonal_adjustment,-prices)

print(unique(retail_sfiltered$unofficial_standard_industrial_classification))


# Remove data marking columns

retail_sfiltered <- retail_sfiltered %>%
  select(-starts_with("data_marking"))

#Rename sector column

retail_sfiltered <- retail_sfiltered %>%
  rename(sector = unofficial_standard_industrial_classification)


#Reshape from wide to long
#Months are column, I need one row per sector month

retail_reshape <- retail_sfiltered %>%
  pivot_longer(
    cols = -sector,
    names_to = "months",
    values_to = "retail_index"
  )

print(unique(retail_reshape$months)[ 1:20])


# Check what clean_names did to the month columns
print(names(retail_sfiltered)[1:20])

# Check actual months values
retail_reshape <- retail_sfiltered %>%
  pivot_longer(
    cols = -sector,
    names_to = "months",
    values_to = "retail_index"
  )
print(head(unique(retail_reshape$months), 20))
print(tail(unique(retail_reshape$months), 20))



#convert month to proper date

retail_reshape <- retail_reshape %>%
  mutate(

#months looks like "jan_17","feb", etc.
#convert to date:2017-01-01, 2017-02-01 etc.

    dates = dmy(paste0("01-", gsub("_","-", months)))

  )

# CHECK - do NOT filter yet

print(head(unique(retail_reshape$months), 20))

print(head(unique(retail_reshape$dates), 20))

print(range(retail_reshape$dates, na.rm = TRUE))

# Count rows per sector
retail_reshape %>%
  count(sector)

# Or simply
print(table(retail_reshape$sector))


# filter to 2017-2023

retail_clean <- retail_reshape %>%
  filter(dates>="2017-01-01" & dates <= "2023-12-31")%>%
  select(-months)

print(table(retail_clean$sector))

print(range(retail_clean$dates))

print(head(retail_clean, 10))

# save

write.csv(retail_clean, "retail_clean.csv", row.names = FALSE)


##### CLEAN CPIH DATA ############


cpih_rawD <- read_excel(
  "cpih01-time-series-v67-filtered-2026-10-03T15-46-38Z.xlsx",
  sheet = "Dataset",
  skip = 2
)

# clean column name

cpih_rawD <- clean_names(cpih_rawD)

# keep only what we need

cpih_sfiltered <- cpih_rawD %>%
  select(-geography, -geography_code)

print(unique(cpih_sfiltered$aggregate))


## Reshape from wide to long

cpih_reshape <- cpih_sfiltered %>%
  pivot_longer(
    cols = -aggregate,
    names_to = "months",
    values_to = "cpih_index"
  )

# Convert months to proper dates

cpih_reshape <- cpih_reshape %>%
  mutate(
    dates = dmy(paste0("01-", gsub("_","-",months)))
  )

#Filter to 2017-2023

cpih_clean <- cpih_reshape %>%
  filter(dates >= "2017-01-01" & dates <= "2023-12-31")%>%
  select(-months) %>%



# Rename aggregates to simpler names

  mutate(aggregate = case_when(

    aggregate == "01 Food and non-alcoholic beverages" ~ "CPIH_Food",

    aggregate == "04 Housing, water, electricity, gas and other fuels" ~ "CPIH_Housing",

    aggregate == "07 Transport" ~ "CPIH_Transport",

    aggregate == "11 Restaurants and hotels" ~ "CPIH_Restaurants",

    aggregate == "Overall Index" ~ "CPIH_Overall",

    TRUE ~ aggregate
  ))


print(unique(cpih_clean$aggregate))

print(head(cpih_clean, 10))
print(cpih_clean)

#### SAVE #####

write.csv(cpih_clean, "cpih_clean.csv", row.names = FALSE)




##### CLEANING  HCI / CPI DATA ############

hci_rawD <- read.csv(
  "Figure_1__Household_costs_rose_by_4.1%_in_the_12_months_to_September_2025_.csv",
  skip = 6,
  header = TRUE,
  stringsAsFactors = FALSE
)

hci_rawD <- clean_names(hci_rawD)
print(names(hci_rawD))


# Rename columns

hci_clean <- hci_rawD %>%
  rename(
    date_rawD = index_date,
    cpi = consumer_prices_index,
    hci = household_cost_index_all_households
  )
print(names(hci_clean))

## Convert date to proper format ---
  # date_rawD looks like "Jan 2015"

hci_clean <- hci_clean %>%
  mutate(
    dates = dmy(paste0("01 ", date_rawD))
  )

print(head(unique(hci_clean$dates), 10))
print(range(hci_clean$dates, na.rm = TRUE))
print(sum(is.na(hci_clean$dates)))

## Filter to 2017-2023

hci_clean <- hci_clean %>%
  filter( dates >= "2017-01-01" & dates <= "2023-12-31") %>%
  select(-date_rawD)

print(range(hci_clean$dates))

print(head(hci_clean, 10))

# Save

write.csv(hci_clean, "hci_clean.csv", row.names = FALSE)




#### NOW MERGE ALL THREE DATASETS #####

cpih_wide <- cpih_clean %>%
pivot_wider(
  names_from = aggregate,
  values_from = cpih_index
)

print(names(cpih_wide))


## merge retail with cpih
# Retail has multiple rows per month (one per sector).
# CPIH has one row per month.
# So we join CPIH onto retail by date.

merged_data <- retail_clean %>%
  left_join(cpih_wide, by = "dates")

merged_data <- merged_data %>%
  left_join(hci_clean, by ="dates")




print(names(merged_data))

print(range(merged_data$dates))
print(unique(merged_data$sector))
print(table(merged_data$sector))
print(colSums(is.na(merged_data)))
print(head(merged_data, 10))

## SAVE


write.csv(merged_data, "final_merged_data.csv", row.names = FALSE)



######  DESCRIPTIVE STATISTICS ############

summary(merged_data)


##### Descriptive statistics by sector #####
# By sector

sector_stats <- merged_data %>%

  group_by(sector) %>%

  summarise(

    n = n(),

    mean_retail = mean(retail_index, na.rm =TRUE),

    median_retail = median(retail_index, na.rm = TRUE),

    sd_retail = sd(retail_index, na.rm = TRUE),

    min_retail = min(retail_index, na.rm = TRUE),

    max_retail = max(retail_index, na.rm = TRUE),

    range_retail = max_retail - min_retail

  )

print(sector_stats)

write.csv(sector_stats, "Descriptive_stats_by_sector.csv", row.names = FALSE)


#### #  Descriptive statistics for inflation measures



inflation_stats <- merged_data %>%
  summarise(
    mean_CPIH_Food = mean(CPIH_Food, na.rm = TRUE),
    sd_CPIH_Food = sd(CPIH_Food, na.rm = TRUE),
    mean_CPIH_Housing = mean(CPIH_Housing, na.rm = TRUE),
    sd_CPIH_Housing = sd(CPIH_Housing, na.rm = TRUE),
    mean_CPIH_Transport = mean(CPIH_Transport, na.rm = TRUE),
    sd_CPIH_Transport = sd(CPIH_Transport, na.rm = TRUE),
    mean_CPIH_Restaurants = mean(CPIH_Restaurants, na.rm = TRUE),
    sd_CPIH_Restaurants = sd(CPIH_Restaurants, na.rm = TRUE),
    mean_CPIH_Overall = mean(CPIH_Overall, na.rm = TRUE),
    sd_CPIH_Overall = sd(CPIH_Overall, na.rm = TRUE),
    mean_cpi = mean(cpi, na.rm = TRUE),
    sd_cpi = sd(cpi, na.rm = TRUE),
    mean_hci = mean(hci, na.rm = TRUE),
    sd_hci = sd(hci, na.rm = TRUE)
  )

print(inflation_stats)

#Check for missing values


print(colSums(is.na(merged_data)))


# Check number of observations per sector

print(table(merged_data$sector))


#  Date range

print(range(merged_data$dates))


#Save

write.csv(inflation_stats, "Descriptive_stats_inflation.csv", row.names = FALSE)



### Trend Over Time (Line Chart)#####

retail_trend_chart <- ggplot(merged_data, aes(x = dates, y = retail_index, colour = sector)) + geom_line() +

  labs(
    title = "UK Retail Sales Volume by Sector (2017 - 2023)",

    subtitle = "Chained volume of retail sales (2019 = 100), seasonally adjusted",

    x = "Dates",
    y = "Retail Index (2019 = 100)",

    colour = "Sector"
  ) +
  theme_minimal()


print(retail_trend_chart)

# Save the chart
ggsave("retail_trend_chart.png", retail_trend_chart, width = 10, height = 6, dpi = 300)

### Add vertical lines for key events

retail_trend_annotated <- ggplot(merged_data, aes(x = dates, y = retail_index, colour = sector)) +
  geom_line(size = 1) +
  geom_vline(xintercept = as.Date("2020-03-01"), linetype = "dashed", colour = "grey50") +
  geom_vline(xintercept = as.Date("2021-10-01"), linetype = "dashed", colour = "grey50") +
  annotate("text", x = as.Date("2020-03-01"), y = 130, label = "Pandemic\nstarts",
           hjust = 1.1, size = 3, colour = "grey40") +
  annotate("text", x = as.Date("2021-10-01"), y = 130, label = "Inflation\nrises",
           hjust = -0.1, size = 3, colour = "grey40") +
  labs(
    title = "UK Retail Sales Volume by Sector (2017–2023)",
    subtitle = "Key events marked: pandemic start (March 2020) and inflation surge (October 2021)",
    x = "Date",
    y = "Retail Index (2019 = 100)",
    colour = "Sector"
  ) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    legend.title = element_blank(),
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 10, colour = "grey40")
  )

print(retail_trend_annotated)

ggsave("retail_trend_annotated.png", retail_trend_annotated, width = 10, height = 6, dpi = 300)


##### Faceted chart: One panel per sector


retail_faceted <- ggplot(merged_data, aes(x = dates, y = retail_index, colour = sector)) +
  geom_line(size = 1) +
  facet_wrap(~ sector, scales = "free_y", ncol = 2) +
  labs(
    title = "UK Retail Sales Volume by Sector (2017–2023)",
    subtitle = "Each panel shows one sector with its own y-axis scale",
    x = "Date",
    y = "Retail Index (2019 = 100)"
  ) +
  theme_minimal() +
  theme(
    legend.position = "none",
    strip.text = element_text(size = 10, face = "bold"),
    plot.title = element_text(size = 14, face = "bold")
  )

print(retail_faceted)

ggsave("retail_trend_faceted.png", retail_faceted, width = 12, height = 8, dpi = 300)



###### # Calculate change from pre-crisis to during-crisis

# Define periods

merged_data <- merged_data %>%
  mutate(period = case_when(
    dates <= "2019-12-31" ~ "Before (2017-2019)",
    dates >= "2021-01-01" ~ "During (2021-2023)",
    TRUE ~ "Transition (2020)"
  ))

# Average by sector and period
period_comparison <- merged_data %>%
  filter(period != "Transition (2020)") %>%
  group_by(sector, period) %>%
  summarise(avg_retail = mean(retail_index, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = period, values_from = avg_retail) %>%
  mutate(
    change = `During (2021-2023)` - `Before (2017-2019)`,
    pct_change = round((change / `Before (2017-2019)`) * 100, 1)
  ) %>%
  arrange(change)

print(period_comparison)

write.csv(period_comparison, "retail_change_before_during.csv", row.names = FALSE)


#Bar chart: Change by sector

change_chart <- ggplot(period_comparison, aes(x = reorder(sector, change), y = change, fill = sector)) +
  geom_col() +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey50") +
  coord_flip() +
  labs(
    title = "Change in Average Retail Index: Before vs During Cost-of-Living Crisis",
    subtitle = "Before = 2017-2019; During = 2021-2023",
    x = "Sector",
    y = "Change in Retail Index (2019 = 100)"
  ) +
  theme_minimal() +
  theme(
    legend.position = "none",
    plot.title = element_text(size = 14, face = "bold")
  )

print(change_chart)

ggsave("retail_change_chart.png", change_chart, width = 10, height = 6, dpi = 300)








## Inflation Trends (Line Chart)####

#Reshape for plotting

Inflation_reshape <- merged_data %>%

  select(dates, CPIH_Food, CPIH_Housing, CPIH_Transport, CPIH_Restaurants, CPIH_Overall, cpi, hci) %>%

  pivot_longer(cols = -dates,

  names_to = "measure",

  values_to = "value" )

  inflation_chart <- ggplot(Inflation_reshape, aes(x = dates, y = value , colour = measure )) +

  geom_line() +

  labs(
  title = "Inflation Measures Over Time (2017 - 2023)",

  subtitle = "CPIH indices (2015 = 100) and CPI/HCI annual inflation rates (%)",

  x = "Dates",
  y = "Index / Rate ",
  colour = "Measure"
         ) +
         theme_minimal()

  print(inflation_chart)

  ggsave("inflation_trend_chart.png", inflation_chart, width = 10, height = 6, dpi = 300)


  # Separate charts: CPIH indices vs CPI/HCI rates

  # Chart A: CPIH indices only
  cpih_long <- merged_data %>%
    select(dates, CPIH_Food, CPIH_Housing, CPIH_Transport, CPIH_Restaurants, CPIH_Overall) %>%
    pivot_longer(cols = -dates, names_to = "measure", values_to = "value")

  cpih_chart <- ggplot(cpih_long, aes(x = dates, y = value, colour = measure)) +
    geom_line(size = 1) +
    labs(
      title = "CPIH Indices by Category (2017–2023)",
      subtitle = "Index: 2015 = 100",
      x = "Date",
      y = "CPIH Index",
      colour = "Category"
    ) +
    theme_minimal() +
    theme(
      legend.position = "bottom",
      legend.title = element_blank(),
      plot.title = element_text(size = 14, face = "bold")
    )

  print(cpih_chart)
  ggsave("cpih_trend_chart.png", cpih_chart, width = 10, height = 6, dpi = 300)

  # Chart B: CPI vs HCI rates only
  rates_long <- merged_data %>%
    select(dates, cpi, hci) %>%
    pivot_longer(cols = -dates, names_to = "measure", values_to = "value")

  rates_chart <- ggplot(rates_long, aes(x = dates, y = value, colour = measure)) +
    geom_line(size = 1) +
    labs(
      title = "Consumer Prices Index (CPI) vs Household Cost Index (HCI)",
      subtitle = "Annual inflation rate (%)",
      x = "Date",
      y = "Inflation Rate (%)",
      colour = "Measure"
    ) +
    theme_minimal() +
    theme(
      legend.position = "bottom",
      legend.title = element_blank(),
      plot.title = element_text(size = 14, face = "bold")
    )

  print(rates_chart)
  ggsave("cpi_hci_trend_chart.png", rates_chart, width = 10, height = 6, dpi = 300)




## Annotated chart: Highlight key events

  inflation_annotated <- ggplot(rates_long, aes(x = dates, y = value, colour = measure)) +
    geom_line(size = 1) +
    geom_vline(xintercept = as.Date("2021-10-01"), linetype = "dashed", colour = "grey50") +
    geom_vline(xintercept = as.Date("2023-03-01"), linetype = "dashed", colour = "grey50") +
    annotate("text", x = as.Date("2021-10-01"), y = 14, label = "Inflation\nsurge",
             hjust = -0.1, size = 3, colour = "grey40") +
    annotate("text", x = as.Date("2023-03-01"), y = 14, label = "Inflation\npeaks",
             hjust = -0.1, size = 3, colour = "grey40") +
    labs(
      title = "CPI vs HCI: Inflation Surge and Peak (2017–2023)",
      subtitle = "Key events marked: inflation surge (Oct 2021) and peak (Mar 2023)",
      x = "Date",
      y = "Inflation Rate (%)",
      colour = "Measure"
    ) +
    theme_minimal() +
    theme(
      legend.position = "bottom",
      legend.title = element_blank(),
      plot.title = element_text(size = 14, face = "bold")
    )

  print(inflation_annotated)
  ggsave("inflation_annotated_chart.png", inflation_annotated, width = 10, height = 6, dpi = 300)



### Summary table: Inflation by period

  # Define periods
  merged_data <- merged_data %>%
    mutate(period = case_when(
      dates <= "2019-12-31" ~ "Before (2017-2019)",
      dates >= "2021-01-01" ~ "During (2021-2023)",
      TRUE ~ "Transition (2020)"
    ))

  # Average inflation by period
  inflation_period <- merged_data %>%
    filter(period != "Transition (2020)") %>%
    group_by(period) %>%
    summarise(
      avg_CPIH_Food = mean(CPIH_Food, na.rm = TRUE),
      avg_CPIH_Housing = mean(CPIH_Housing, na.rm = TRUE),
      avg_CPIH_Transport = mean(CPIH_Transport, na.rm = TRUE),
      avg_CPIH_Restaurants = mean(CPIH_Restaurants, na.rm = TRUE),
      avg_CPIH_Overall = mean(CPIH_Overall, na.rm = TRUE),
      avg_cpi = mean(cpi, na.rm = TRUE),
      avg_hci = mean(hci, na.rm = TRUE)
    )

  print(inflation_period)


  #Calculate inflation change from before to during crisis

  inflation_change <- inflation_period %>%
    pivot_longer(
      cols = -period,
      names_to = "measure",
      values_to = "value"
    ) %>%
    pivot_wider(
      names_from = period,
      values_from = value
    ) %>%
    mutate(
      change = `During (2021-2023)` - `Before (2017-2019)`,
      pct_change = round((change / `Before (2017-2019)`) * 100, 1)
    ) %>%
    arrange(desc(change))

  print(inflation_change)

  write.csv(inflation_change, "inflation_change_before_during.csv", row.names = FALSE)



  # Bar chart: Inflation change by measure

  inflation_change_chart <- ggplot(inflation_change, aes(x = reorder(measure, change), y = change, fill = measure)) +
    geom_col() +
    geom_hline(yintercept = 0, linetype = "dashed", colour = "grey50") +
    coord_flip() +
    labs(
      title = "Change in Inflation: Before vs During Cost-of-Living Crisis",
      subtitle = "Before = 2017-2019; During = 2021-2023",
      x = "Measure",
      y = "Change in Inflation Rate (%)"
    ) +
    theme_minimal() +
    theme(
      legend.position = "none",
      plot.title = element_text(size = 14, face = "bold")
    )

  print(inflation_change_chart)
  ggsave("inflation_change_chart.png", inflation_change_chart, width = 10, height = 6, dpi = 300)






#### Correlation Analysis ####

  ## Overall correlation

  overall_cor <- merged_data %>%
    summarise(
      cor_HCI = round(cor(retail_index, hci, use = "complete.obs"), 3),
      cor_CPI = round(cor(retail_index, cpi, use = "complete.obs"), 3)
    )
  print(overall_cor)


  # Correlation by Sector (with all inflation measures)

  sector_cor <- merged_data %>%
    group_by(sector) %>%
    summarise(
      cor_HCI = round(cor(retail_index, hci, use = "complete.obs"), 3),
      cor_CPI = round(cor(retail_index, cpi, use = "complete.obs"), 3),
      cor_CPIH_Food = round(cor(retail_index, CPIH_Food, use = "complete.obs"), 3),
      cor_CPIH_Housing = round(cor(retail_index, CPIH_Housing, use = "complete.obs"), 3),
      cor_CPIH_Transport = round(cor(retail_index, CPIH_Transport, use = "complete.obs"), 3),
      cor_CPIH_Restaurants = round(cor(retail_index, CPIH_Restaurants, use = "complete.obs"), 3),
      .groups = "drop"
    ) %>%
    arrange(cor_HCI) # Sort from most negative to most positive

  print(sector_cor)


  # Save the table
  write.csv(sector_cor, "correlation_by_sector.csv", row.names = FALSE)


  ### Visualise Correlation with HCI by Sector

  cor_chart <- ggplot(sector_cor, aes(x = reorder(sector, cor_HCI), y = cor_HCI, fill = sector)) +
    geom_col() +
    geom_hline(yintercept = 0, linetype = "dashed", colour = "grey50") +
    coord_flip() +
    labs(
      title = "Correlation Between Retail Sales and Household Cost Index (HCI)",
      subtitle = "Negative values mean sales tend to fall as HCI (inflation) rises",
      x = "Sector",
      y = "Correlation Coefficient"
    ) +
    theme_minimal() +
    theme(
      legend.position = "none",
      plot.title = element_text(size = 14, face = "bold")
    )

  print(cor_chart)
  ggsave("correlation_hci_chart.png", cor_chart, width = 10, height = 6, dpi = 300)



  ### Visualise Correlation with CPIH Food by Sector

  # (Just to see if food inflation specifically hits sectors differently)

  cor_chart_food <- ggplot(sector_cor, aes(x = reorder(sector, cor_CPIH_Food), y = cor_CPIH_Food, fill = sector)) +
    geom_col() +
    geom_hline(yintercept = 0, linetype = "dashed", colour = "grey50") +
    coord_flip() +
    labs(
      title = "Correlation Between Retail Sales and Food Inflation (CPIH_Food)",
      subtitle = "Negative values mean sales tend to fall as food prices rise",
      x = "Sector",
      y = "Correlation Coefficient"
    ) +
    theme_minimal() +
    theme(
      legend.position = "none",
      plot.title = element_text(size = 14, face = "bold")
    )

  print(cor_chart_food)
  ggsave("correlation_food_chart.png", cor_chart_food, width = 10, height = 6, dpi = 300)











#### Regression Analysis (The Core)#####

# Overall Regression (All sectors pooled together)

  # Model: Retail Index ~ CPIH categories + HCI
  # We use HCI as the main inflation rate, and CPIH for specific categories.

    model_overall <- lm(retail_index ~ CPIH_Food + CPIH_Housing + CPIH_Transport +
                        CPIH_Restaurants + CPIH_Overall + hci,
                        data = merged_data)
  print(summary(model_overall))

  # Save tidy output for easy reading
  overall_results <- tidy(model_overall)
  write.csv(overall_results, "regression_overall.csv", row.names = FALSE)


#By sector
# Run separate models for each sector
  # 5.2 Sector-by-Sector Regression
  # We run the same model separately for each sector.
  # This shows how inflation affects Food differently to Clothing, etc

 sectors <- unique(merged_data$sector)

 # Create an empty data frame to store results
 sector_regression_results <- data.frame()

 for (s in sectors) {

   sector_data <- merged_data %>%
     filter(sector == s)

   model_sector <- lm(retail_index ~ CPIH_Food + CPIH_Housing + CPIH_Transport + CPIH_Restaurants + CPIH_Overall + hci,

               data = sector_data)

   # Print summary
   print(summary(model_sector))


   # Extract coefficients and add sector name
   tidy_model <- tidy(model_sector) %>%
     mutate(sector = s) %>%
     select(sector, term, estimate, std.error, statistic, p.value)

   # Bind to master results dataframe
   sector_regression_results <- bind_rows(sector_regression_results, tidy_model)

 }

 # Save sector results
 write.csv(sector_regression_results, "regression_by_sector.csv", row.names = FALSE)


 ### Create a summary table of HCI effect only

 # HCI is the key measure of household inflation. Let's see its effect per sector.

 hci_summary <- sector_regression_results %>%
   filter(term == "hci") %>%
   select(sector, estimate, std.error, p.value) %>%
   arrange(estimate) # Sort by effect size

 print(hci_summary)

 ## Plot the effect of HCI by Sector

 hci_plot <- ggplot(hci_summary, aes(x = reorder(sector, estimate), y = estimate, fill = sector)) +
   geom_col() +
   geom_errorbar(aes(ymin = estimate - 1.96*std.error,
                     ymax = estimate + 1.96*std.error),
                 width = 0.2) +
   geom_hline(yintercept = 0, linetype = "dashed", colour = "grey50") +
   coord_flip() +
   labs(
     title = "Effect of Household Cost Index (HCI) on Retail Sales by Sector",
     subtitle = "Coefficient estimate with 95% confidence intervals. Negative = sales fall as inflation rises.",
     x = "Sector",
     y = "HCI Coefficient"
   ) +
   theme_minimal() +
   theme(
     legend.position = "none",
     plot.title = element_text(size = 14, face = "bold")
   )

 print(hci_plot)
 ggsave("regression_hci_effect.png", hci_plot, width = 10, height = 6, dpi = 300)




 ### Check Model Fit (R-squared)


 # We need to run the models again to extract R-squared
 # (or we could have extracted it in the loop above, but this is easier)

 r_squared_results <- data.frame()

 for (s in sectors) {
   sector_data <- merged_data %>% filter(sector == s)
   model_sector <- lm(retail_index ~ CPIH_Food + CPIH_Housing + CPIH_Transport + CPIH_Restaurants + hci, data = sector_data)

   r_squared_results <- bind_rows(r_squared_results, data.frame(
     sector = s,
     r_squared = summary(model_sector)$r.squared,
     adj_r_squared = summary(model_sector)$adj.r.squared
   ))
 }

 print(r_squared_results)
 write.csv(r_squared_results, "regression_r_squared.csv", row.names = FALSE)





# Comparison of Sectors (Coefficient Plot)

 # Extract HCI coefficient for each sector
 library(broom)

 sector_results <- merged_data %>%
   group_by(sector) %>%
   do(tidy(lm(retail_index ~ hci, data = .))) %>%
   filter(term == "hci")

 ggplot(sector_results, aes(x = reorder(sector, estimate), y = estimate, fill = sector)) +
   geom_col() +
   geom_errorbar(aes(ymin = estimate - 1.96*std.error,
                     ymax = estimate + 1.96*std.error), width = 0.2) +
   coord_flip() +
   labs(
     title = "Effect of Household Cost Index on Retail Sales by Sector",
     x = "Sector",
     y = "Coefficient (negative = sales fall when inflation rises)"
   ) +
   theme_minimal()

####### Before/After Crisis Comparison #####

 # Create period variable

 merged_data <- merged_data %>%

   mutate(period = case_when(

     dates <= "2019-12-31" ~ "Before crisis (2017-2019)",

     dates >= "2021-01-01" ~ "During crisis (2021-2023)",

     TRUE ~ "Transition (2020)"
   ))

 # Average by sector and period

 crisis_comparison <- merged_data %>%

   filter(period != "Transition (2020)") %>%

   group_by(sector, period) %>%

   summarise(avg_retail = mean(retail_index, na.rm = TRUE)) %>%

   pivot_wider(names_from = period, values_from = avg_retail) %>%

   mutate(change = `During crisis (2021-2023)` - `Before crisis (2017-2019)`)


#### Pandemic Effect Check ####

merged_data <- merged_data %>%

   mutate(pandemic = ifelse(dates >= as.Date("2020-03-01") & dates <= as.Date("2021-06-30"), 1, 0))

 model_with_pandemic <- lm(retail_index ~ CPIH_Food + CPIH_Housing + CPIH_Transport +
                             CPIH_Restaurants + CPIH_Overall + hci + pandemic,
                           data = merged_data)
 summary(model_with_pandemic)


#### Diagnostic Checks#####


 # Residual plots
 plot(model_overall)

 # VIF (variance inflation factor)
 library(car)
 vif(model_overall)

 # Durbin-Watson test
 library(lmtest)
 dwtest(model_overall)

 # Breusch-Pagan test
 bptest(model_overall)



#### Summary Table for Dissertation ######




