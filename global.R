# ============================================================
# GLOBAL.R - AeroInsight BI Dashboard
# ============================================================
# WHY THIS FILE EXISTS:
# Shiny apps have 3 special files: global.R, ui.R, server.R
# global.R runs ONCE when the app starts (before anything else)
# Perfect for loading heavy data & packages
# Data loaded here is available to BOTH ui and server
# Without global.R, data would reload on every user click = slow
# ============================================================

# ── PACKAGES ──────────────────────────────────────────────────
library(shiny)          # core dashboard framework
library(shinydashboard) # sidebar + box layout
library(tidyverse)      # data manipulation
library(plotly)         # interactive charts (hover, zoom, click)
library(leaflet)        # interactive route maps
library(DT)             # interactive sortable/searchable tables
library(scales)         # number formatting ($, %, commas)

source("R/plots.R")  # load reusable chart functions

# ── LOAD CLEANED RAW DATA ─────────────────────────────────────
# These are the cleaned BTS datasets from data_prep.R
# Used when charts need row-level detail (e.g. route maps)
t100   <- readRDS("data/processed/t100_clean.rds")   # route operations
p52    <- readRDS("data/processed/p52_clean.rds")    # operating expenses
p12a   <- readRDS("data/processed/p12a_clean.rds")   # fuel data
ontime <- readRDS("data/processed/ontime_clean.rds") # flight delays

# ── LOAD PRE-CALCULATED KPIs ──────────────────────────────────
# These are the financial metrics from kpi_calc.R
# Pre-calculated so dashboard loads instantly, not recalculates
casm_data     <- readRDS("data/processed/kpi_casm.rds")        # cost efficiency
load_factor   <- readRDS("data/processed/kpi_loadfactor.rds")  # seat utilization
fuel_metrics  <- readRDS("data/processed/kpi_fuel.rds")        # fuel analysis
delay_costs   <- readRDS("data/processed/kpi_delays.rds")      # delay financials
hub_perf      <- readRDS("data/processed/kpi_hubs.rds")        # hub comparison
p52_quarterly <- readRDS("data/processed/p52_quarterly.rds")   # quarterly expenses
t100_quarterly<- readRDS("data/processed/t100_quarterly.rds")  # quarterly operations

# ── DASHBOARD CONSTANTS ───────────────────────────────────────
# Reusable values referenced throughout ui.R and server.R
# Define once here rather than hardcoding in multiple places

US_AIRWAYS_COLOR  <- "#003366"  # US Airways navy blue (brand color)
ACCENT_COLOR      <- "#CC0000"  # US Airways red (brand color)
HUB_AIRPORTS      <- c("PHL", "CLT", "PHX")  # US Airways major hubs
ANALYSIS_YEARS    <- 2010:2013  # period of analysis

cat("✅ AeroInsight BI - All data loaded successfully\n")
cat("   T-100 routes:", nrow(t100), "\n")
cat("   On-Time flights:", nrow(ontime), "\n")
cat("   Ready to launch dashboard\n")