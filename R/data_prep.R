# ============================================================
# DATA PREPARATION FOR AEROINSIGHT BI
# Loads raw BTS files, filters to US Airways, saves clean .rds
# WHY THIS FILE: Raw CSVs are slow to load and need cleaning
# Run this ONCE - output saved to data/processed/
# ============================================================

library(data.table)  # fast CSV reading for large files
library(tidyverse)   # data manipulation
library(httr)        # for downloading on-time data via API

# ── 1. T-100 DOMESTIC SEGMENT ─────────────────────────────────
# WHY: Route-level operations data - flights, seats, passengers
# One row per route per month per aircraft type
t100_files <- list.files("data/raw/t100/", pattern="*.csv", full.names=TRUE)

t100 <- lapply(t100_files, fread) %>%
  bind_rows() %>%
  filter(UNIQUE_CARRIER == "US") %>%   # keep only US Airways
  mutate(
    MONTH      = as.integer(MONTH),
    YEAR       = as.integer(YEAR),
    # Load Factor: % of seats filled with passengers
    LoadFactor = ifelse(SEATS > 0, PASSENGERS / SEATS, NA),
    # ASM: total capacity = seats × miles flown
    ASM        = SEATS * DISTANCE
  ) %>%
  filter(SEATS > 0, DEPARTURES_PERFORMED > 0)  # remove empty rows

cat("T-100 rows:", nrow(t100), "| cols:", ncol(t100), "\n")
saveRDS(t100, "data/processed/t100_clean.rds")

# ── 2. P-5.2 OPERATING EXPENSES ───────────────────────────────
# WHY: Aircraft-level operating costs per quarter
# Values in BTS are stored in $000s - multiply by 1000 for dollars
# One row per aircraft type per quarter
p52_files <- list.files("data/raw/p52/", pattern="*.csv", full.names=TRUE)

p52 <- lapply(p52_files, fread) %>%
  bind_rows() %>%
  filter(UNIQUE_CARRIER == "US") %>%
  mutate(
    # Convert from $000s to actual dollars
    # Note: FUEL_FLY_OPS and PILOT_FLY_OPS NOT converted here
    # They are converted later in kpi_calc.R when building p52_quarterly
    TOT_AIR_OP_EXPENSES = TOT_AIR_OP_EXPENSES * 1000,
    TOT_FLY_OPS         = TOT_FLY_OPS * 1000,
    TOT_DIR_MAINT       = TOT_DIR_MAINT * 1000
  )

cat("P-5.2 rows:", nrow(p52), "| cols:", ncol(p52), "\n")
saveRDS(p52, "data/processed/p52_clean.rds")

# ── 3. P-12A FUEL COST & CONSUMPTION ─────────────────────────
# WHY: Quarterly fuel costs and gallons consumed
# IMPORTANT: P-12A costs are in RAW DOLLARS (not $000s like P-5.2)
# Do NOT multiply by 1000
p12a_files <- list.files("data/raw/p12a/", pattern="*.csv", full.names=TRUE)

p12a <- lapply(p12a_files, fread) %>%
  bind_rows() %>%
  filter(UNIQUE_CARRIER == "US") %>%
  mutate(
    # Already in dollars - just calculate derived metric
    FuelPerGallon = ifelse(TOTAL_GALLONS > 0,
                           TOTAL_COST / TOTAL_GALLONS, NA)
  )

cat("P-12A rows:", nrow(p12a), "| cols:", ncol(p12a), "\n")
cat("Fuel/gallon check (expect $2-4):",
    round(mean(p12a$FuelPerGallon, na.rm=TRUE), 2), "\n")
saveRDS(p12a, "data/processed/p12a_clean.rds")

# ── 4. ON-TIME PERFORMANCE ────────────────────────────────────
# WHY: Flight-level delay data - your unique financial KPI
# Downloaded via BTS pre-zipped files (monthly, 2010-2013)
# Each zip contains all carriers - filter to US Airways only

if (file.exists("data/processed/ontime_clean.rds")) {
  # Already downloaded - skip to save time
  cat("On-Time already exists - loading from file\n")
  ontime <- readRDS("data/processed/ontime_clean.rds")
} else {
  ontime_list <- list()
  for (yr in 2010:2013) {
    for (mo in 1:12) {
      cat("Downloading:", yr, "month", mo, "\n")
      url <- paste0(
        "https://transtats.bts.gov/PREZIP/",
        "On_Time_Reporting_Carrier_On_Time_Performance_1987_present_",
        yr, "_", mo, ".zip"
      )
      destfile <- paste0("data/raw/ontime/ontime_", yr, "_", mo, ".zip")
      tryCatch({
        GET(url,
            add_headers(
              "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
              "Referer"    = "https://transtats.bts.gov/"
            ),
            write_disk(destfile, overwrite=TRUE)
        )
        if (file.info(destfile)$size > 10000) {
          csv_file <- unzip(destfile, exdir="data/raw/ontime/")
          temp_df  <- read_csv(csv_file[1], show_col_types=FALSE)
          ontime_list[[paste(yr, mo)]] <- temp_df %>%
            filter(if ("Reporting_Airline" %in% names(.))
              Reporting_Airline == "US"
              else
                UNIQUE_CARRIER == "US")
          file.remove(destfile)
          cat("✅ Got", nrow(ontime_list[[paste(yr, mo)]]), "rows\n")
        }
      }, error = function(e) cat("Failed:", yr, mo, "\n"))
      Sys.sleep(1)
    }
  }
  # Combine all months - convert everything to character first
  # to handle type conflicts between monthly files
  ontime <- bind_rows(lapply(ontime_list, function(df) {
    df %>% mutate(across(everything(), as.character))
  })) %>%
    mutate(
      across(c(DepDelay, DepDelayMinutes, ArrDelay, ArrDelayMinutes,
               Cancelled, Diverted, AirTime, Distance,
               CarrierDelay, WeatherDelay, NASDelay, LateAircraftDelay),
             as.numeric)
    )
  saveRDS(ontime, "data/processed/ontime_clean.rds")
}

cat("On-Time rows:", nrow(ontime), "\n")
cat("\n✅ data_prep.R complete - all files saved to data/processed/\n")
  