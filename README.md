<div align="center"> 
  
  # ✈️ AeroInsight BI
</div>

<div align="center"> 
  
### Flight Operations & Analytics — A Case Study on US Airways Inc.
**Guided By: Mr. Kunwar Saurabh Bisen** 
> **M.Sc. Data Science Project** | **Chandigarh University** | **2024–2026**

> **Built with R Shiny · Plotly · Leaflet · BTS Data · Live API Integration**

</div>


<div align="center">

![R](https://img.shields.io/badge/R-4.5.1-276DC3?style=for-the-badge&logo=r&logoColor=white)
![Shiny](https://img.shields.io/badge/R_Shiny-Dashboard-blue?style=for-the-badge)
![BTS](https://img.shields.io/badge/Data-BTS_Transtats-orange?style=for-the-badge)
![Records](https://img.shields.io/badge/Records-1.6M_Flights-green?style=for-the-badge)
![License](https://img.shields.io/badge/License-Academic-red?style=for-the-badge)

</div>

---

## 📋 Table of Contents

- [About the Project](#-about-the-project)
- [Live Demo](#-live-demo)
- [Key Findings](#-key-findings)
- [Dashboard Features](#-dashboard-features)
- [Data Sources](#-data-sources)
- [Project Structure](#-project-structure)
- [Installation & Setup](#-installation--setup)
- [Running the Dashboard](#-running-the-dashboard)
- [KPI Definitions](#-kpi-definitions)
- [Technology Stack](#-technology-stack)
- [Academic Context](#-academic-context)
- [Author](#-author)

---

## 🎯 About the Project

**AeroInsight BI** is a fully interactive Business Intelligence dashboard built
using R Shiny that transforms over **1.6 million flight records** from the
Bureau of Transportation Statistics (BTS) into actionable financial intelligence
for aviation management.

The project analyses **US Airways Inc.** — the 5th largest US carrier during its
operational period — across the years **2010 to 2013**, the four years immediately
preceding its landmark merger with American Airlines in December 2013.

### Why US Airways 2010–2013?

- ✅ Complete operational lifecycle — post-recession recovery through merger
- ✅ Three major hubs: Philadelphia (PHL), Charlotte (CHL), Phoenix (PHX)
- ✅ Rich publicly available BTS datasets covering all four years
- ✅ Financially significant period: fuel price volatility, hedging strategy,
  operational optimisation
- ✅ Natural analytical endpoint: CASM declining in 2013 Q3–Q4 signals
  pre-merger optimisation

---

## 🌐 Live Demo

> 🔗 **Dashboard:** [your-app-name.shinyapps.io/AeroInsight-BI](https://your-app.shinyapps.io/AeroInsight-BI)

> *Replace with your actual shinyapps.io link after deployment*

---

## 📊 Key Findings

| KPI | Value | Benchmark | Status |
|-----|-------|-----------|--------|
| Average CASM | **10.65¢/ASM** | Industry 2024: 11.2¢ | ✅ Below average |
| System Load Factor | **81.2%** | Industry benchmark: 80% | ✅ Above benchmark |
| Fuel % of Operating Cost | **17.9%** | Industry average: 30% | ✅ Significantly below |
| Avg Fuel Price | **$2.81/gallon** | Peak 2011: $3.30 | 📈 Volatile period |
| Total Delay Cost (4yr) | **$1.44 Billion** | $100/delay minute | ⚠️ 22% controllable |
| Strongest Hub | **Charlotte (CLT)** | 12M passengers in 2013 | ✅ 83.6% load factor |

---

## 🖥️ Dashboard Features

The dashboard comprises **9 interactive analytical tabs**:

### Tab 1 — Executive Overview
- 4 KPI value boxes (CASM, Load Factor, Delay Cost, Fuel %)
- CASM quarterly trend line chart
- Cost component breakdown donut chart
- Monthly load factor area chart
- Key findings summary panel

### Tab 2 — Route Analytics
- **Interactive Leaflet route map** — colour-coded by load factor
  (green = high LF, navy = mid, red = low)
- Filter by year (2010–2013) and hub (All/PHL/CLT/PHX)
- Top 20 routes by passengers (horizontal bar)
- Load factor distribution histogram with 80% benchmark line

### Tab 3 — Fleet Cost Analysis
- Stacked CASM components (Fuel / Labor / Maintenance)
- Year-over-year CASM change chart
- Cost efficiency metrics panel
- Searchable quarterly operating expense table

### Tab 4 — Fuel Intelligence
- Quarterly fuel price per gallon trend
- Fuel cost vs total operating cost grouped bars
- Fuel % of total cost trend with 30% industry benchmark line

### Tab 5 — Hub Performance
- PHL vs CLT vs PHX comparison across 4 years
- Passengers, Load Factor, Routes, Departures charts
- 2013 Hub Scorecard with colour-coded performance badges

### Tab 6 — Delay Cost Impact ⭐ *Original KPI*
- Monthly estimated delay cost trend ($100/minute standard)
- Delay cause breakdown: Carrier (22.3%) vs Weather (1.76%) vs Other
- Carrier vs weather delay % time series

### Tab 7 — Financial What-If Simulator ⭐ *Unique Feature*
- Three interactive sliders: CASM reduction, fuel price, delay reduction
- Real-time estimated annual savings calculation
- Pre-defined scenario comparison table

### Tab 8 — Live Industry Benchmarks
- US Airways historical vs current BTS industry averages
- Auto-refreshable via BTS PREZIP API
- Benchmark interpretation panel

### Tab 9 — About This Project
- Project objectives, datasets, KPI definitions
- Technology stack documentation
- Key findings summary

---

## 📦 Data Sources

All data sourced from **Bureau of Transportation Statistics (BTS) Transtats**
(https://www.transtats.bts.gov) — publicly available, no API key required.

| Dataset | BTS Name | Records | Used For |
|---------|----------|---------|----------|
| T-100 Domestic Segment | Form 41 Traffic | 42,142 routes | Routes, ASM, Load Factor |
| Schedule P-5.2 | Form 41 Financial | 380 records | Operating expenses, CASM |
| Schedule P-12A | Form 41 Financial | 48 records | Fuel cost & consumption |
| On-Time Performance | Reporting Carrier | 1,632,669 flights | Delay cost analysis |

> **Note:** On-Time Performance data is downloaded automatically via the
> BTS PREZIP API during `data_prep.R` execution. The other three datasets
> must be downloaded manually from transtats.bts.gov (instructions below).

---

## 📁 Project Structure

```
AeroInsight_BI/
│
├── app.R                    # Main Shiny application (UI + Server)
├── global.R                 # Data loader & package imports (runs once)
├── AeroInsight_BI.Rproj     # RStudio project file
│
├── R/
│   ├── data_prep.R          # Data ingestion & cleaning pipeline
│   ├── kpi_calc.R           # KPI calculation engine
│   └── plots.R              # Reusable chart function library
│
├── www/
│   └── custom.css           # Custom CSS styling (Barlow fonts, brand colors)
│
├── data/
│   └── processed/           # Auto-generated RDS files 
│       ├── t100_clean.rds
│       ├── p52_clean.rds
│       ├── p12a_clean.rds
│       ├── ontime_clean.rds
│       ├── kpi_casm.rds
│       ├── kpi_loadfactor.rds
│       ├── kpi_fuel.rds
│       ├── kpi_delays.rds
│       ├── kpi_hubs.rds
│       ├── p52_quarterly.rds
│       └── t100_quarterly.rds
│
├── README.md             
│
├── LICENSE                # MIT License
│
└── .gitignore             # files that are ignored due to large datasets
```

---

## ⚙️ Installation & Setup

### Prerequisites

- **R** (version 4.0 or higher) — https://cran.r-project.org
- **RStudio** — https://posit.co/products/open-source/rstudio/
- **Git** — https://git-scm.com
- Internet connection (for On-Time data download)

### Step 1 — Clone the Repository

```bash
git clone https://github.com/YOUR-USERNAME/AeroInsight-BI.git
cd AeroInsight-BI
```

### Step 2 — Open in RStudio

Open the file `AeroInsight_BI.Rproj` in RStudio.
This automatically sets the working directory correctly.

### Step 3 — Install Required Packages

Run this in the RStudio Console:

```r
install.packages(c(
  "shiny",
  "shinydashboard",
  "tidyverse",
  "data.table",
  "plotly",
  "leaflet",
  "DT",
  "scales",
  "httr",
  "lubridate"
))
```

### Step 4 — Download BTS Datasets Manually

Go to https://www.transtats.bts.gov and download the following,
saving to the directories shown:

**T-100 Domestic Segment → `data/raw/t100/`**
- Aviation → Air Carrier Statistics (Form 41 Traffic) - U.S. Carriers
- Filter: Carrier = US, Year = 2010 (repeat for 2011, 2012, 2013)
- Save as: `t100_2010.csv`, `t100_2011.csv`, etc.

**Schedule P-5.2 → `data/raw/p52/`**
- Aviation → Air Carrier Financial Reports → Schedule P-5.2
- Filter: Carrier = US, Year = 2010–2013 (one file per year)
- Save as: `p52_2010.csv`, etc.

**Schedule P-12A → `data/raw/p12a/`**
- Aviation → Air Carrier Financial Reports → Schedule P-12A
- Filter: Carrier = US, Year = 2010–2013
- Save as: `p12a_2010.csv`, etc.

> ⚡ On-Time Performance data (1.6M records) is downloaded
> **automatically** in Step 5 — no manual download needed.

### Step 5 — Run the Data Pipeline

Run these scripts **in order** from the RStudio Console:

```r
# Step 5a: Clean and process all datasets
# (On-Time data downloads automatically — takes ~10 minutes)
source("R/data_prep.R")

# Step 5b: Calculate all KPIs
source("R/kpi_calc.R")
```

You should see output like:
```
T-100 rows: 42142
P-5.2 rows: 380
P-12A rows: 48
On-Time rows: 1632669
✅ All KPIs saved to data/processed/
```

---

## 🚀 Running the Dashboard

```r
shiny::runApp()
```

Or press the **Run App** button in RStudio.

The dashboard will open in your browser at `http://127.0.0.1:XXXX`

---

## 📐 KPI Definitions

| KPI | Formula | Data Source | Granularity |
|-----|---------|-------------|-------------|
| **CASM** | Total Operating Cost ÷ Available Seat Miles | P-5.2 + T-100 | Quarterly |
| **ASM** | Seats × Distance (miles) | T-100 | Route-Month |
| **Load Factor** | Passengers ÷ Available Seats | T-100 | Route-Month |
| **Fuel %** | Fuel Cost ÷ Total Operating Cost × 100 | P-12A + P-5.2 | Quarterly |
| **Fuel $/gal** | Total Fuel Cost ÷ Total Gallons | P-12A | Quarterly |
| **Delay Cost** | Total Delay Minutes × $100 | On-Time Performance | Monthly |

> **Delay Cost Methodology:** $100 per delay minute is the industry standard
> established by the FAA and Airlines for America for narrow-body aircraft,
> covering crew overtime, fuel burn, and passenger compensation.

---

## 🛠️ Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Language | R 4.5.1 | All data processing and application logic |
| Web Framework | R Shiny + shinydashboard | Interactive dashboard |
| Charts | Plotly | Hover-enabled interactive visualisations |
| Maps | Leaflet + CartoDB Positron | Interactive route network map |
| Tables | DT (DataTables) | Searchable, sortable financial tables |
| Data Processing | tidyverse + data.table | High-performance data cleaning |
| API Requests | httr | BTS PREZIP API for On-Time data |
| Styling | Custom CSS + Google Fonts (Barlow) | Professional UI design |
| Deployment | shinyapps.io | Cloud hosting |

---

## 🎓 Academic Context
  
**Project Title:**
AeroInsight BI – Flight Operations & Analytics Using Data Analysis:
A Case Study on US Airways Inc.

**Program:** Master of Science in Data Science

**Institution:** Chandigarh University (CU Online)

**Academic Year:** 2024–2025

**Guide:** Mr.Kunwar Saurabh Bisen

**Project Objectives:**
1. To explore the use of AeroInsight BI in analyzing flight operations data
   in the aviation industry
2. To apply data analysis techniques to identify patterns and trends in
   flight operations data relevant to financial management
3. To demonstrate the potential benefits of using data analytics for
   financial decision-making in the aviation industry

**Original Contributions:**
- Financial Delay Cost KPI ($1.44B estimated over 4 years)
- Interactive Financial What-If Simulator
- Integrated 4-dataset BTS pipeline with automated On-Time data download

---

## ⚠️ Important Notes

- **Raw data files** (`data/raw/`) are **not included** in this repository
  due to file size. Download them manually following Step 4 above.
- **Processed RDS files** (`data/processed/`) are in this repository for reference.
  Run `data_prep.R` and `kpi_calc.R` to regenerate them after downlaoding the raw datasets.
- The `.gitignore` file is pre-configured to exclude large data files.

---

## 📜 License

This project is submitted as an academic project for Chandigarh University.
All BTS data used is publicly available under US government open data policy.

---

## 👩‍💻 Author

**Vanshika Aggarwal**

**M.Sc. Data Science | Chandigarh University**

**Guide: Mr.Kunwar Saurabh Bisen**

---

<div align="center">

*Built with guidance using R Shiny | Data: Bureau of Transportation Statistics*

**[⭐ Star this repo if you found it helpful]**

</div>
