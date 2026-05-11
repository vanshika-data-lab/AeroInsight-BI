# ============================================================
# KPI CALCULATIONS FOR AEROINSIGHT BI
# US Airways Financial & Operational Analysis (2010-2013)
# ============================================================
# WHY THIS FILE EXISTS:
# Raw BTS data gives us flights, costs, fuel numbers
# But raw numbers alone don't tell a story
# KPIs convert raw data into meaningful financial metrics
# Run AFTER data_prep.R
# ============================================================

library(tidyverse)
library(scales)

# ── STEP 0A: P-5.2 QUARTERLY TOTALS ──────────────────────────
# WHY: P-5.2 has one row per AIRCRAFT TYPE per quarter
# We need ONE row per quarter (total across all aircraft)
# Without this, joins create duplicates and wrong calculations
# NOTE: FUEL_FLY_OPS and PILOT_FLY_OPS multiplied by 1000 HERE
# because they were not converted in data_prep.R

p52_quarterly <- p52 %>%
  filter(!is.na(TOT_AIR_OP_EXPENSES)) %>%
  group_by(YEAR, QUARTER) %>%
  summarise(
    TOT_AIR_OP_EXPENSES = sum(TOT_AIR_OP_EXPENSES, na.rm=TRUE), # already in $
    TOT_FLY_OPS         = sum(TOT_FLY_OPS,         na.rm=TRUE), # already in $
    TOT_DIR_MAINT       = sum(TOT_DIR_MAINT,        na.rm=TRUE), # already in $
    FUEL_FLY_OPS        = sum(FUEL_FLY_OPS  * 1000, na.rm=TRUE), # $000s → $
    PILOT_FLY_OPS       = sum(PILOT_FLY_OPS * 1000, na.rm=TRUE), # $000s → $
    .groups = "drop"
  )

cat("P-5.2 quarterly rows:", nrow(p52_quarterly),
    "(should be 16 = 4 years × 4 quarters)\n")

# ── STEP 0B: T-100 QUARTERLY TOTALS ──────────────────────────
# WHY: T-100 is monthly, financial data is quarterly
# Must aggregate T-100 to quarterly to match P-5.2 for joins

t100_quarterly <- t100 %>%
  mutate(QUARTER = ceiling(MONTH / 3)) %>%
  group_by(YEAR, QUARTER) %>%
  summarise(
    Total_ASM        = sum(ASM,                  na.rm=TRUE),
    Total_Seats      = sum(SEATS,                na.rm=TRUE),
    Total_Passengers = sum(PASSENGERS,           na.rm=TRUE),
    Total_Flights    = sum(DEPARTURES_PERFORMED, na.rm=TRUE),
    .groups = "drop"
  )

cat("T-100 quarterly rows:", nrow(t100_quarterly),
    "(should be 16)\n")

# ── KPI 1: CASM ───────────────────────────────────────────────
# Cost per Available Seat Mile
# THE most important cost efficiency metric in aviation
# Answers: "How much does it cost to fly one seat one mile?"
# Industry benchmark 2010-2013: ~10-15 cents
# Lower CASM = more efficient airline
# Broken into components: Fuel, Labor, Maintenance

casm_data <- p52_quarterly %>%
  left_join(t100_quarterly, by=c("YEAR","QUARTER")) %>%
  mutate(
    CASM       = ifelse(Total_ASM > 0, TOT_AIR_OP_EXPENSES / Total_ASM, NA),
    Fuel_CASM  = ifelse(Total_ASM > 0, FUEL_FLY_OPS        / Total_ASM, NA),
    Labor_CASM = ifelse(Total_ASM > 0, PILOT_FLY_OPS       / Total_ASM, NA),
    Maint_CASM = ifelse(Total_ASM > 0, TOT_DIR_MAINT       / Total_ASM, NA),
    Period     = paste0(YEAR, " Q", QUARTER)
  )

cat("✅ CASM calculated\n")
cat("   Total CASM:",  round(mean(casm_data$CASM,       na.rm=TRUE), 4), "\n")
cat("   Fuel CASM:",   round(mean(casm_data$Fuel_CASM,  na.rm=TRUE), 4), "\n")
cat("   Labor CASM:",  round(mean(casm_data$Labor_CASM, na.rm=TRUE), 4), "\n")
cat("   Maint CASM:",  round(mean(casm_data$Maint_CASM, na.rm=TRUE), 4), "\n")

# ── KPI 2: LOAD FACTOR ────────────────────────────────────────
# How full were the planes on each route each month?
# Higher = more revenue per flight
# Industry target: 80%+ is healthy
# Calculated at route level to find best/worst performing routes

load_factor <- t100 %>%
  group_by(YEAR, MONTH, ORIGIN, DEST) %>%
  summarise(
    Total_Passengers = sum(PASSENGERS,           na.rm=TRUE),
    Total_Seats      = sum(SEATS,                na.rm=TRUE),
    Total_Flights    = sum(DEPARTURES_PERFORMED, na.rm=TRUE),
    Total_ASM        = sum(ASM,                  na.rm=TRUE),
    Avg_Distance     = mean(DISTANCE,            na.rm=TRUE),
    LoadFactor       = ifelse(sum(SEATS) > 0,
                              sum(PASSENGERS) / sum(SEATS), NA),
    .groups = "drop"
  ) %>%
  mutate(
    LowPerforming = LoadFactor < 0.70,  # flag underperforming routes
    QUARTER       = ceiling(MONTH / 3)
  )

cat("✅ Load Factor calculated\n")
cat("   Average:", round(mean(load_factor$LoadFactor, na.rm=TRUE)*100, 1), "%\n")
cat("   Low performing routes (<70%):",
    sum(load_factor$LowPerforming, na.rm=TRUE), "\n")

# ── KPI 3: FUEL METRICS ───────────────────────────────────────
# Fuel cost as % of total operating cost
# Fuel = typically 25-35% of airline costs
# Tracks fuel price volatility impact on finances
# IMPORTANT: p12a costs are raw dollars, p52 is already converted

fuel_metrics <- p12a %>%
  left_join(
    p52_quarterly %>% select(YEAR, QUARTER, TOT_AIR_OP_EXPENSES),
    by=c("YEAR","QUARTER")
  ) %>%
  mutate(
    Fuel_Pct_Total_Cost = ifelse(TOT_AIR_OP_EXPENSES > 0,
                                 TOTAL_COST / TOT_AIR_OP_EXPENSES * 100, NA),
    FuelPerGallon       = ifelse(TOTAL_GALLONS > 0,
                                 TOTAL_COST / TOTAL_GALLONS, NA),
    Period = paste0(YEAR, " Q", QUARTER)
  )

cat("✅ Fuel metrics calculated\n")
cat("   Avg Fuel % of costs:",
    round(mean(fuel_metrics$Fuel_Pct_Total_Cost, na.rm=TRUE), 1), "%\n")
cat("   Avg $/gallon: $",
    round(mean(fuel_metrics$FuelPerGallon, na.rm=TRUE), 2), "\n")

# ── KPI 4: DELAY COST ESTIMATION ─────────────────────────────
# YOUR UNIQUE KPI - not in Apoorv's project
# Delays cost money: crew overtime + fuel burn + compensation
# Industry standard: ~$100 per minute of delay (narrow body)
# Broken into: Carrier delays (controllable) vs Weather (not)

delay_costs <- ontime %>%
  mutate(
    ArrDelayMinutes   = as.numeric(ArrDelayMinutes),
    CarrierDelay      = as.numeric(CarrierDelay),
    WeatherDelay      = as.numeric(WeatherDelay),
    NASDelay          = as.numeric(NASDelay),
    LateAircraftDelay = as.numeric(LateAircraftDelay),
    Cancelled         = as.numeric(Cancelled)
  ) %>%
  filter(!is.na(ArrDelayMinutes), ArrDelayMinutes > 0) %>%
  mutate(DelayCost = ArrDelayMinutes * 100) %>%
  group_by(Year, Month) %>%
  summarise(
    Total_Delayed_Flights = n(),
    Avg_Delay_Minutes     = mean(ArrDelayMinutes, na.rm=TRUE),
    Total_Delay_Cost_USD  = sum(DelayCost,        na.rm=TRUE),
    Carrier_Delay_Pct     = mean(!is.na(CarrierDelay) &
                                   CarrierDelay > 0, na.rm=TRUE) * 100,
    Weather_Delay_Pct     = mean(!is.na(WeatherDelay) &
                                   WeatherDelay > 0, na.rm=TRUE) * 100,
    .groups = "drop"
  ) %>%
  mutate(Date = as.Date(paste(Year, Month, "01", sep="-")))

cat("✅ Delay costs calculated\n")
cat("   Total 2010-2013:",
    dollar(sum(delay_costs$Total_Delay_Cost_USD, na.rm=TRUE)), "\n")
cat("   Avg delay:", round(mean(delay_costs$Avg_Delay_Minutes, na.rm=TRUE), 1),
    "minutes\n")

# ── KPI 5: HUB PERFORMANCE ────────────────────────────────────
# US Airways had 3 hubs: PHL, CLT, PHX
# Hub strength = connecting traffic = better load factors = more revenue
# Answers: "Which hub was most financially efficient?"

hub_performance <- t100 %>%
  filter(ORIGIN %in% c("PHL","CLT","PHX")) %>%
  group_by(YEAR, ORIGIN) %>%
  summarise(
    Total_Departures   = sum(DEPARTURES_PERFORMED, na.rm=TRUE),
    Total_Passengers   = sum(PASSENGERS,           na.rm=TRUE),
    Total_Seats        = sum(SEATS,                na.rm=TRUE),
    Total_ASM          = sum(ASM,                  na.rm=TRUE),
    Avg_LoadFactor     = mean(LoadFactor,          na.rm=TRUE),
    Unique_Routes      = n_distinct(DEST),
    .groups = "drop"
  ) %>%
  mutate(
    Avg_LoadFactor_Pct = Avg_LoadFactor * 100,
    Hub_Name = case_when(
      ORIGIN == "PHL" ~ "Philadelphia (PHL)",
      ORIGIN == "CLT" ~ "Charlotte (CLT)",
      ORIGIN == "PHX" ~ "Phoenix (PHX)"
    )
  )

cat("✅ Hub performance calculated\n")
cat("   Hubs:", paste(unique(hub_performance$ORIGIN), collapse=", "), "\n")

# ── SAVE ALL ──────────────────────────────────────────────────
# .rds format: R native, 10x faster than CSV, preserves types
saveRDS(casm_data,       "data/processed/kpi_casm.rds")
saveRDS(load_factor,     "data/processed/kpi_loadfactor.rds")
saveRDS(fuel_metrics,    "data/processed/kpi_fuel.rds")
saveRDS(delay_costs,     "data/processed/kpi_delays.rds")
saveRDS(hub_performance, "data/processed/kpi_hubs.rds")
saveRDS(p52_quarterly,   "data/processed/p52_quarterly.rds")
saveRDS(t100_quarterly,  "data/processed/t100_quarterly.rds")

cat("\n✅ All KPIs saved to data/processed/\n")