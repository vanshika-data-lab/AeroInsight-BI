# ============================================================
# APP.R - AeroInsight BI Dashboard
# Project: US Airways Financial & Operational Analysis
# Period:  2010-2013 (Pre-merger with American Airlines)
# ============================================================
# HOW THIS FILE IS ORGANIZED:
# 1. source("global.R")     - loads all data and packages
# 2. airports dataframe     - coordinates for route map
# 3. UI definition          - what the user sees
# 4. SERVER definition      - logic behind every chart/table
# 5. shinyApp()             - launches the app
# ============================================================
# HOW SHINY WORKS (quick recap):
# UI    = layout, placeholders (xxxOutput functions)
# SERVER= fills those placeholders (renderXxx functions)
# reactive() = code that re-runs when user changes a filter
# ============================================================

source("global.R")   # loads data, packages, plot functions, constants

# ============================================================
# AIRPORT COORDINATES TABLE
# ============================================================
# WHY: Leaflet route map needs lat/lng for each airport code
# BTS data only provides 3-letter codes (e.g. "PHL", "CLT")
# This lookup table maps codes → coordinates for drawing lines
# More airports listed = more route lines visible on the map

airports <- data.frame(
  code = c(
    # US Airways hubs (most important - shown as red dots)
    "PHL","CLT","PHX",
    # Major Northeast destinations
    "BOS","JFK","LGA","EWR","DCA","IAD","BWI",
    # Major Southeast
    "ATL","MCO","MIA","TPA","FLL","RDU","ORF","RIC",
    # Major Midwest
    "ORD","MDW","DTW","MSP","STL","MCI","CMH","PIT",
    # Major West Coast
    "LAX","SFO","SEA","DEN","LAS","PDX","SAN","SLC",
    # Major South/Southwest
    "DFW","IAH","HOU","MSY","AUS","SAT","BNA",
    # Other US Airways destinations
    "BDL","PVD","GSO","GSP","CHS","JAX","SRQ"
  ),
  lat = c(
    39.87, 35.21, 33.43,
    42.36, 40.64, 40.78, 40.69, 38.85, 38.94, 39.17,
    33.63, 28.43, 25.80, 27.98, 26.07, 35.88, 36.89, 37.51,
    41.97, 41.79, 42.21, 44.88, 38.75, 39.30, 39.99, 40.49,
    33.94, 37.62, 47.45, 39.86, 36.08, 45.59, 32.73, 40.79,
    32.89, 29.99, 29.65, 29.99, 30.19, 29.53, 36.12,
    41.93, 41.72, 36.09, 34.90, 32.90, 30.49, 27.39
  ),
  lng = c(
    -75.24, -80.94, -112.01,
    -71.01, -73.78, -73.87, -74.17, -77.04, -77.46, -76.67,
    -84.42, -81.31, -80.29, -82.53, -80.15, -78.79, -76.01, -77.32,
    -87.90, -87.75, -83.35, -93.22, -90.37, -94.71, -82.89, -80.23,
    -118.40,-122.37,-122.31,-104.67,-115.15,-122.60,-117.19,-111.98,
    -97.04, -95.34, -95.28, -90.26, -97.67, -98.47, -86.68,
    -72.68, -71.43, -79.94, -82.22, -80.04, -81.69, -82.55
  ),
  stringsAsFactors = FALSE
)

# ============================================================
# UI DEFINITION
# ============================================================
# dashboardPage() creates the full layout with 3 sections:
#   dashboardHeader   = top navigation bar
#   dashboardSidebar  = left menu panel
#   dashboardBody     = main content with all tabs
# Each tabItem() is one page/screen of the dashboard

ui <- dashboardPage(
  skin = "blue",   # shinydashboard built-in theme base
  
  # ── HEADER ────────────────────────────────────────────────
  # HTML() allows us to use custom HTML inside the title
  # This adds the gold plane icon (fas fa-plane = FontAwesome)
  # FontAwesome icons are automatically available in Shiny
  dashboardHeader(
    title = HTML('
      <span style="font-family: Barlow Condensed, sans-serif;
                   font-weight: 700;
                   letter-spacing: 1.5px;
                   font-size: 17px;">
        <i class="fas fa-plane"
           style="color: #c8a45a; margin-right: 6px;">
        </i>AEROINSIGHT BI
      </span>')
  ),
  
  # ── SIDEBAR ───────────────────────────────────────────────
  # sidebarMenu() contains all menuItem() navigation links
  # tabName in menuItem MUST match tabName in tabItem()
  dashboardSidebar(
    
    # Small label above menu showing project scope
    tags$div(
      style = "padding: 15px 20px 10px;
               color: #4a6080;
               font-size: 10px;
               letter-spacing: 2px;
               font-family: 'Barlow Condensed', sans-serif;
               text-transform: uppercase;
               border-bottom: 1px solid rgba(255,255,255,0.05);
               margin-bottom: 5px;",
      "US Airways 2010\u20132013"   # \u2013 = em dash character
    ),
    
    sidebarMenu(
      menuItem("Executive Overview",  tabName = "overview",
               icon = icon("tachometer-alt")),
      menuItem("Route Analytics",     tabName = "routes",
               icon = icon("plane")),
      menuItem("Fleet Cost Analysis", tabName = "fleet",
               icon = icon("dollar-sign")),
      menuItem("Fuel Intelligence",   tabName = "fuel",
               icon = icon("gas-pump")),
      menuItem("Hub Performance",     tabName = "hubs",
               icon = icon("map-marker-alt")),
      menuItem("Delay Cost Impact",   tabName = "delays",
               icon = icon("clock")),
      menuItem("Cost Simulator",      tabName = "simulator",
               icon = icon("calculator")),
      menuItem("Live Benchmarks",     tabName = "live",
               icon = icon("wifi")),
      menuItem("About This Project",  tabName = "about",
               icon = icon("info-circle"))
    ),
    
    # Sidebar footer showing data stats
    # position:absolute bottom:0 pins it to the bottom
    tags$div(
      style = "position: absolute; bottom: 0; width: 100%;
               padding: 10px 15px;
               border-top: 1px solid rgba(255,255,255,0.05);",
      tags$p(style = "color: #4a6080; font-size: 10px;
                      margin: 0; text-align: center;",
             "Data: BTS 2010\u20132013"),
      tags$p(style = "color: #4a6080; font-size: 10px;
                      margin: 2px 0 0 0; text-align: center;",
             "1,632,669 flights analyzed")
    )
  ),
  
  # ── DASHBOARD BODY ────────────────────────────────────────
  dashboardBody(
    
    # ── HEAD SECTION ──────────────────────────────────────
    # tags$head() injects into the HTML <head>
    # This is where we load external fonts and CSS
    tags$head(
      tags$title("AeroInsight BI"),
      # Google Fonts: Barlow family for professional typography
      # Barlow Condensed = headings and labels
      # Barlow = body text
      # JetBrains Mono = numbers and financial data
      tags$link(
        rel  = "stylesheet",
        href = paste0("https://fonts.googleapis.com/css2?",
                      "family=Barlow:wght@300;400;500;600;700&",
                      "family=Barlow+Condensed:wght@400;600;700&",
                      "family=JetBrains+Mono:wght@400;500&",
                      "display=swap")
      ),
      # Our custom CSS file (saved in www/custom.css)
      # www/ folder is automatically served by Shiny as static files
      tags$link(rel = "stylesheet", type = "text/css",
                href = "custom.css")
    ),
    
    # ── TAB ITEMS ─────────────────────────────────────────
    # All tabs live inside tabItems()
    # Each tabItem(tabName=...) must match a menuItem(tabName=...)
    tabItems(
      
      # ════════════════════════════════════════════════════
      # TAB 1: EXECUTIVE OVERVIEW
      # PURPOSE: The "landing page" of the dashboard
      # Shows 4 KPI cards + 4 charts for quick financial summary
      # Audience: Executives who want the big picture fast
      # ════════════════════════════════════════════════════
      tabItem(tabName = "overview",
              
              # Page title and subtitle
              h2("Executive Overview"),
              tags$p("US Airways Inc. \u2014 Financial & Operational
                Analysis 2010\u20132013"),
              
              # ── KPI VALUE BOXES ──────────────────────────────
              # fluidRow() creates a horizontal row
              # width=3 means 3/12 columns = 25% width each
              # 4 boxes × width 3 = 12 (full row)
              # valueBoxOutput() is a placeholder filled by server
              fluidRow(
                valueBoxOutput("box_casm",       width = 3),
                valueBoxOutput("box_loadfactor", width = 3),
                valueBoxOutput("box_delaycost",  width = 3),
                valueBoxOutput("box_fuelpct",    width = 3)
              ),
              
              # ── CHARTS ROW 1 ─────────────────────────────────
              # box() creates a card container
              # status = color of box header
              # solidHeader = TRUE fills header with color
              # plotlyOutput() = placeholder for interactive chart
              fluidRow(
                box(title = "CASM Trend by Quarter",
                    width = 8, status = "primary", solidHeader = TRUE,
                    plotlyOutput("plot_casm_trend", height = "280px")),
                box(title = "Cost Component Breakdown",
                    width = 4, status = "primary", solidHeader = TRUE,
                    plotlyOutput("plot_cost_breakdown", height = "280px"))
              ),
              
              # ── CHARTS ROW 2 ─────────────────────────────────
              fluidRow(
                box(title = "Monthly Load Factor Trend",
                    width = 7, status = "info", solidHeader = TRUE,
                    plotlyOutput("plot_lf_trend", height = "280px")),
                box(title = "Key Findings",
                    width = 5, status = "warning", solidHeader = TRUE,
                    # uiOutput() = placeholder for dynamic HTML content
                    uiOutput("key_findings"))
              ),
              
              # Data citation footer
              div(class = "footer-text",
                  icon("database"), " ",
                  "Bureau of Transportation Statistics (BTS) | ",
                  "T-100 Domestic Segment \u00b7 Form 41 P-5.2 \u00b7 ",
                  "P-12A \u00b7 On-Time Performance | ",
                  "Period: 2010\u20132013 | ",
                  "42,142 routes \u00b7 1,632,669 flights")
      ),
      
      # ════════════════════════════════════════════════════
      # TAB 2: ROUTE ANALYTICS
      # PURPOSE: Interactive route network visualization
      # Shows which routes were busiest and most efficient
      # Interactive: filter by year + hub updates all charts
      # ════════════════════════════════════════════════════
      tabItem(tabName = "routes",
              
              h2("Route Analytics"),
              tags$p("Interactive route network \u2014 filter by year
                and hub to explore US Airways domestic operations."),
              
              fluidRow(
                # ── FILTER PANEL ───────────────────────────────
                # Left column with dropdown filters
                # These inputs trigger reactive() in server
                box(title = "Filters", width = 3,
                    status = "primary", solidHeader = TRUE,
                    
                    # Year selector
                    selectInput("route_year", "Select Year:",
                                choices  = 2010:2013,
                                selected = 2013),
                    
                    # Hub filter (All = show all routes)
                    selectInput("route_hub", "Filter by Hub:",
                                choices  = c("All", "PHL", "CLT", "PHX"),
                                selected = "All"),
                    
                    hr(),
                    # Dynamic summary stats - update with filters
                    uiOutput("route_summary")
                ),
                
                # ── INTERACTIVE MAP ────────────────────────────
                # leafletOutput() renders the interactive route map
                # Lines = routes, thickness = passenger volume
                # Green/Blue/Red = load factor performance
                box(title = "Route Map \u2014 Top 30 Routes by Passengers",
                    width = 9, status = "primary", solidHeader = TRUE,
                    leafletOutput("route_map", height = "380px"))
              ),
              
              fluidRow(
                box(title = "Top 20 Routes by Passengers",
                    width = 6, status = "info", solidHeader = TRUE,
                    plotlyOutput("plot_top_routes", height = "350px")),
                box(title = "Load Factor Distribution",
                    width = 6, status = "info", solidHeader = TRUE,
                    # Red dashed line at 80% = industry benchmark
                    plotlyOutput("plot_lf_dist", height = "350px"))
              )
      ),
      
      # ════════════════════════════════════════════════════
      # TAB 3: FLEET COST ANALYSIS
      # PURPOSE: Deep dive into operating costs
      # CASM broken into fuel + labor + maintenance components
      # Shows quarterly trends and year-over-year changes
      # ════════════════════════════════════════════════════
      tabItem(tabName = "fleet",
              
              h2("Fleet Cost Analysis"),
              tags$p("Quarterly CASM analysis broken down by fuel,
                labor, and maintenance components."),
              
              fluidRow(
                box(title = "CASM by Quarter \u2014 Stacked Cost Components",
                    width = 8, status = "primary", solidHeader = TRUE,
                    plotlyOutput("plot_casm_components", height = "320px")),
                box(title = "4-Year Cost Summary",
                    width = 4, status = "primary", solidHeader = TRUE,
                    plotlyOutput("plot_cost_pie", height = "320px"))
              ),
              
              fluidRow(
                # Year-over-year CASM change (green=improvement, red=increase)
                box(title = "Year-over-Year CASM Change",
                    width = 6, status = "info", solidHeader = TRUE,
                    plotlyOutput("plot_casm_yoy", height = "260px")),
                # Key efficiency metrics summary
                box(title = "Cost Efficiency Metrics",
                    width = 6, status = "info", solidHeader = TRUE,
                    uiOutput("efficiency_metrics"))
              ),
              
              fluidRow(
                box(title = "Quarterly Operating Expenses \u2014 Detailed",
                    width = 12, status = "primary", solidHeader = TRUE,
                    # DTOutput() = interactive sortable/searchable table
                    DTOutput("table_expenses"))
              )
      ),
      
      # ════════════════════════════════════════════════════
      # TAB 4: FUEL INTELLIGENCE
      # PURPOSE: Fuel cost analysis
      # Fuel = typically 25-35% of airline operating costs
      # US Airways was at 17.9% - suggests fuel hedging strategy
      # ════════════════════════════════════════════════════
      tabItem(tabName = "fuel",
              
              h2("Fuel Intelligence"),
              tags$p("Jet fuel analysis covering price trends,
                consumption, and fuel cost as % of total expenses."),
              
              # KPI row for fuel-specific metrics
              fluidRow(
                valueBoxOutput("box_avg_fuel_price",  width = 4),
                valueBoxOutput("box_total_fuel_cost", width = 4),
                valueBoxOutput("box_fuel_pct",        width = 4)
              ),
              
              fluidRow(
                box(title = "Fuel Price per Gallon \u2014 Quarterly Trend",
                    width = 6, status = "primary", solidHeader = TRUE,
                    plotlyOutput("plot_fuel_price", height = "280px")),
                box(title = "Fuel Cost vs Total Operating Cost",
                    width = 6, status = "primary", solidHeader = TRUE,
                    plotlyOutput("plot_fuel_vs_total", height = "280px"))
              ),
              
              fluidRow(
                # Wide chart showing fuel % trend vs 30% industry benchmark
                box(title = "Fuel % of Total Cost vs Industry Average (30%)",
                    width = 12, status = "info", solidHeader = TRUE,
                    plotlyOutput("plot_fuel_pct_trend", height = "220px"))
              )
      ),
      
      # ════════════════════════════════════════════════════
      # TAB 5: HUB PERFORMANCE
      # PURPOSE: Compare US Airways' 3 major hubs
      # PHL = Philadelphia (East Coast)
      # CLT = Charlotte    (Southeast, busiest hub)
      # PHX = Phoenix      (West/Southwest)
      # Hub strength drives connecting traffic = revenue
      # ════════════════════════════════════════════════════
      tabItem(tabName = "hubs",
              
              h2("Hub Performance"),
              tags$p("PHL vs CLT vs PHX \u2014 comparative hub analysis
                across passengers, load factor, and routes."),
              
              fluidRow(
                box(title = "Total Passengers per Hub per Year",
                    width = 6, status = "primary", solidHeader = TRUE,
                    plotlyOutput("plot_hub_passengers", height = "300px")),
                box(title = "Load Factor by Hub per Year",
                    width = 6, status = "primary", solidHeader = TRUE,
                    plotlyOutput("plot_hub_lf", height = "300px"))
              ),
              
              fluidRow(
                box(title = "Unique Destinations per Hub",
                    width = 4, status = "info", solidHeader = TRUE,
                    plotlyOutput("plot_hub_routes", height = "260px")),
                box(title = "Total Departures per Hub",
                    width = 4, status = "info", solidHeader = TRUE,
                    plotlyOutput("plot_hub_departures", height = "260px")),
                # Hub summary with color-coded performance badges
                box(title = "Hub 2013 Scorecard",
                    width = 4, status = "warning", solidHeader = TRUE,
                    uiOutput("hub_summary_cards"))
              ),
              
              fluidRow(
                box(title = "Hub Summary Table \u2014 All Years",
                    width = 12, status = "primary", solidHeader = TRUE,
                    DTOutput("table_hubs"))
              )
      ),
      
      # ════════════════════════════════════════════════════
      # TAB 6: DELAY COST IMPACT
      # PURPOSE: Financial cost of flight delays
      # YOUR UNIQUE KPI - not in Apoorv's project
      # Industry standard: $100/minute for narrow body aircraft
      # Breaks delays into: carrier (fixable) vs weather (unavoidable)
      # ════════════════════════════════════════════════════
      tabItem(tabName = "delays",
              
              h2("Delay Cost Impact"),
              tags$p("Financial cost of delays using $100/minute
                industry standard. Breakdown by controllable
                (carrier) vs uncontrollable (weather) causes."),
              
              # KPI row for delay metrics
              fluidRow(
                valueBoxOutput("box_total_delays",     width = 4),
                valueBoxOutput("box_avg_delay",        width = 4),
                valueBoxOutput("box_total_delay_cost", width = 4)
              ),
              
              fluidRow(
                box(title = "Monthly Delay Cost Trend (2010\u20132013)",
                    width = 8, status = "danger", solidHeader = TRUE,
                    plotlyOutput("plot_delay_trend", height = "280px")),
                box(title = "Delay Cause Breakdown",
                    width = 4, status = "danger", solidHeader = TRUE,
                    plotlyOutput("plot_delay_causes", height = "280px"))
              ),
              
              fluidRow(
                box(title = "Carrier vs Weather Delay % Over Time",
                    width = 12, status = "warning", solidHeader = TRUE,
                    plotlyOutput("plot_delay_types", height = "220px"))
              )
      ),
      
      # ════════════════════════════════════════════════════
      # TAB 7: COST SIMULATOR (NEW UNIQUE FEATURE)
      # PURPOSE: Financial what-if analysis
      # Lets user model: fleet efficiency, fuel price, delay reduction
      # Calculates estimated cost savings from each scenario
      # This makes the dashboard interactive and decision-oriented
      # Academically: demonstrates data-driven financial decision making
      # ════════════════════════════════════════════════════
      tabItem(tabName = "simulator",
              
              h2("Financial What-If Simulator"),
              tags$p("Model financial scenarios \u2014 adjust fleet
                efficiency, fuel price, and delay reduction to
                estimate potential cost savings."),
              
              fluidRow(
                # ── INPUT PANEL ────────────────────────────────
                # Three sliders let user set simulation parameters
                # actionButton triggers the calculation
                box(title = "Scenario Parameters",
                    width = 4, status = "primary", solidHeader = TRUE,
                    
                    h4(style = "color:#003366;
                          font-family:'Barlow Condensed';
                          margin-bottom:5px;",
                       icon("plane"), " Fleet Efficiency"),
                    # Slider: 0-30% CASM reduction
                    sliderInput("sim_casm_reduction",
                                "CASM Reduction (%):",
                                min = 0, max = 30,
                                value = 10, step = 1),
                    
                    hr(),
                    h4(style = "color:#003366;
                          font-family:'Barlow Condensed';
                          margin-bottom:5px;",
                       icon("gas-pump"), " Fuel Scenario"),
                    # Slider: fuel price from $1.50 to $5.00/gallon
                    sliderInput("sim_fuel_price",
                                "Fuel Price ($/gallon):",
                                min = 1.50, max = 5.00,
                                value = 2.81, step = 0.05),
                    
                    hr(),
                    h4(style = "color:#003366;
                          font-family:'Barlow Condensed';
                          margin-bottom:5px;",
                       icon("clock"), " Delay Reduction"),
                    # Slider: % reduction in delays
                    sliderInput("sim_delay_reduction",
                                "Delay Reduction (%):",
                                min = 0, max = 50,
                                value = 20, step = 5),
                    
                    hr(),
                    # Run Simulation button - triggers eventReactive()
                    actionButton("btn_simulate", "Run Simulation",
                                 icon  = icon("play"),
                                 class = "btn-primary",
                                 style = "width: 100%;")
                ),
                
                # ── RESULTS PANEL ──────────────────────────────
                box(title = "Simulation Results",
                    width = 8, status = "success", solidHeader = TRUE,
                    
                    # Two result boxes side by side
                    fluidRow(
                      column(6, uiOutput("sim_cost_saving")),
                      column(6, uiOutput("sim_new_casm"))
                    ),
                    
                    hr(),
                    # Bar chart showing savings breakdown
                    plotlyOutput("plot_simulator", height = "280px"),
                    
                    hr(),
                    # Written interpretation of results
                    uiOutput("sim_interpretation")
                )
              ),
              
              fluidRow(
                box(title = "Pre-Defined Scenario Comparison",
                    width = 12, status = "info", solidHeader = TRUE,
                    DTOutput("table_scenarios"))
              )
      ),
      
      # ════════════════════════════════════════════════════
      # TAB 8: LIVE BENCHMARKS
      # PURPOSE: Compare US Airways vs current industry
      # Shows how aviation has evolved since 2013 merger
      # US Airways 2010-2013 metrics vs 2024 BTS industry averages
      # ════════════════════════════════════════════════════
      tabItem(tabName = "live",
              
              h2("Live Industry Benchmarks"),
              tags$p("US Airways 2010\u20132013 vs current industry metrics."),
              
              fluidRow(
                box(width = 12, status = "warning",
                    tags$p(
                      icon("info-circle"), " ",
                      strong("How this works: "),
                      "US Airways historical metrics (2010-2013) are
                 compared against 2024 BTS industry averages to
                 show how aviation has evolved since the merger."
                    ),
                    actionButton("btn_refresh", "Refresh Live Data",
                                 icon  = icon("sync"),
                                 class = "btn-primary")
                )
              ),
              
              fluidRow(
                box(title = "CASM \u2014 US Airways vs Industry Today",
                    width = 6, status = "primary", solidHeader = TRUE,
                    plotlyOutput("plot_benchmark_casm", height = "280px")),
                box(title = "Load Factor \u2014 US Airways vs Industry Today",
                    width = 6, status = "primary", solidHeader = TRUE,
                    plotlyOutput("plot_benchmark_lf", height = "280px"))
              ),
              
              fluidRow(
                box(title = "Benchmark Interpretation",
                    width = 12, status = "info", solidHeader = TRUE,
                    uiOutput("benchmark_summary"))
              )
      ),
      
      # ════════════════════════════════════════════════════
      # TAB 9: ABOUT THIS PROJECT
      # PURPOSE: Academic context for panel presentation
      # Contains: objectives, datasets, KPI definitions, findings
      # This tab replaces the need for a separate report
      # ════════════════════════════════════════════════════
      tabItem(tabName = "about",
              
              h2("About AeroInsight BI"),
              
              fluidRow(
                box(title = "Project Overview",
                    width = 6, status = "primary", solidHeader = TRUE,
                    div(class = "about-section",
                        h4("Objectives"),
                        tags$ul(class = "findings-list",
                                tags$li("Explore BI tools in aviation
                           financial management"),
                                tags$li("Apply data analysis to identify
                           financial patterns in flight operations"),
                                tags$li("Demonstrate data-driven decision making
                           for airline financial strategy"),
                                tags$li("Analyze US Airways pre-merger financial
                           health (2010\u20132013)")
                        ),
                        hr(),
                        h4("Case Study: US Airways Inc."),
                        tags$p(
                          "US Airways operated until its merger with
                   American Airlines in December 2013. With hubs at
                   Philadelphia (PHL), Charlotte (CLT), and Phoenix (PHX),
                   it was the 5th largest US carrier by passengers,
                   operating over 3,000 daily flights at its peak."
                        )
                    )
                ),
                
                box(title = "Data Sources & Methodology",
                    width = 6, status = "info", solidHeader = TRUE,
                    div(class = "about-section",
                        h4("Datasets"),
                        # Dataset summary table
                        tags$table(
                          class = "table table-striped",
                          tags$thead(tags$tr(
                            tags$th("Dataset"),
                            tags$th("Source"),
                            tags$th("Records")
                          )),
                          tags$tbody(
                            tags$tr(
                              tags$td("T-100 Domestic Segment"),
                              tags$td("BTS Form 41 Traffic"),
                              tags$td("42,142")
                            ),
                            tags$tr(
                              tags$td("Schedule P-5.2"),
                              tags$td("BTS Form 41 Financial"),
                              tags$td("380")
                            ),
                            tags$tr(
                              tags$td("Schedule P-12A"),
                              tags$td("BTS Form 41 Financial"),
                              tags$td("48")
                            ),
                            tags$tr(
                              tags$td("On-Time Performance"),
                              tags$td("BTS Reporting Carrier"),
                              tags$td("1,632,669")
                            )
                          )
                        ),
                        hr(),
                        h4("KPI Definitions"),
                        tags$ul(class = "findings-list",
                                tags$li(strong("CASM: "),
                                        "Cost per Available Seat Mile (Total Cost / ASM)"),
                                tags$li(strong("Load Factor: "),
                                        "Passengers \u00f7 Available Seats"),
                                tags$li(strong("Fuel %: "),
                                        "Fuel Cost \u00f7 Total Operating Cost"),
                                tags$li(strong("Delay Cost: "),
                                        "$100/minute \u00d7 Total Delay Minutes"),
                                tags$li(strong("ASM: "),
                                        "Available Seat Miles = Seats \u00d7 Distance")
                        )
                    )
                )
              ),
              
              fluidRow(
                box(title = "Technology Stack",
                    width = 4, status = "success", solidHeader = TRUE,
                    div(class = "about-section",
                        tags$ul(class = "findings-list",
                                tags$li(strong("Language: "), "R 4.5"),
                                tags$li(strong("Framework: "),
                                        "R Shiny + shinydashboard"),
                                tags$li(strong("Charts: "),
                                        "Plotly (interactive)"),
                                tags$li(strong("Maps: "),
                                        "Leaflet + CartoDB tiles"),
                                tags$li(strong("Tables: "),
                                        "DT (DataTables)"),
                                tags$li(strong("Data Processing: "),
                                        "tidyverse + data.table"),
                                tags$li(strong("Styling: "),
                                        "Custom CSS + Google Fonts (Barlow)")
                        )
                    )
                ),
                
                box(title = "Key Findings Summary",
                    width = 8, status = "warning", solidHeader = TRUE,
                    div(class = "about-section",
                        tags$ol(class = "findings-list",
                                tags$li(
                                  "CASM of 10.65\u00a2 \u2014 below 2024 industry
                     average of 11.2\u00a2, demonstrating competitive
                     cost efficiency despite older fleet"
                                ),
                                tags$li(
                                  "Load factor of 81.2% exceeded the 80% benchmark
                     consistently across all 4 years"
                                ),
                                tags$li(
                                  "$1.44B estimated delay costs over 4 years;
                     22% from carrier-controllable causes indicating
                     significant operational improvement potential"
                                ),
                                tags$li(
                                  "Charlotte (CLT) was the strongest hub with
                     12M passengers in 2013 and highest load factor
                     growth trajectory (78.4% \u2192 83.6%)"
                                ),
                                tags$li(
                                  "Fuel at 17.9% of operating costs vs 30% industry
                     average suggests effective fuel hedging strategy"
                                ),
                                tags$li(
                                  "CASM declining trend in 2013 Q3-Q4 signals
                     operational improvements ahead of merger
                     with American Airlines"
                                )
                        )
                    )
                )
              )
      )   # end about tabItem
    )     # end tabItems
  )       # end dashboardBody
)         # end dashboardPage

# ============================================================
# SERVER DEFINITION
# ============================================================
# The server function receives:
#   input  = values FROM the user (dropdowns, sliders, buttons)
#   output = values TO the user (charts, tables, text)
#   session= current browser session (for advanced features)
#
# renderXxx() functions fill the corresponding xxxOutput() placeholders
# reactive() creates code that re-runs when inputs change
# eventReactive() creates code that re-runs only on button click

server <- function(input, output, session) {
  
  # ══════════════════════════════════════════════════════════
  # TAB 1: EXECUTIVE OVERVIEW — SERVER LOGIC
  # ══════════════════════════════════════════════════════════
  
  # KPI Box 1: CASM in cents (multiply by 100 to convert to cents)
  output$box_casm <- renderValueBox({
    valueBox(
      value    = paste0(round(mean(casm_data$CASM, na.rm=TRUE)*100, 1), "\u00a2"),
      subtitle = "Avg Cost per ASM (CASM)",
      icon     = icon("dollar-sign"),
      color    = "blue"
    )
  })
  
  # KPI Box 2: Load Factor as percentage
  output$box_loadfactor <- renderValueBox({
    valueBox(
      value    = paste0(round(mean(load_factor$LoadFactor,
                                   na.rm=TRUE)*100, 1), "%"),
      subtitle = "Avg Load Factor",
      icon     = icon("users"),
      color    = "green"
    )
  })
  
  # KPI Box 3: Total delay cost in billions
  output$box_delaycost <- renderValueBox({
    valueBox(
      value    = paste0("$", round(
        sum(delay_costs$Total_Delay_Cost_USD, na.rm=TRUE)/1e9, 2), "B"),
      subtitle = "Total Delay Cost (2010\u20132013)",
      icon     = icon("clock"),
      color    = "red"
    )
  })
  
  # KPI Box 4: Fuel as % of total operating cost
  output$box_fuelpct <- renderValueBox({
    valueBox(
      value    = paste0(round(mean(fuel_metrics$Fuel_Pct_Total_Cost,
                                   na.rm=TRUE), 1), "%"),
      subtitle = "Fuel % of Operating Cost",
      icon     = icon("gas-pump"),
      color    = "yellow"
    )
  })
  
  # CASM Trend Chart - uses plot_casm_trend() from plots.R
  # This function is defined in R/plots.R and loaded via global.R
  output$plot_casm_trend <- renderPlotly({
    plot_casm_trend(casm_data)
  })
  
  # Cost Breakdown Donut Chart - uses plot_cost_pie_overview() from plots.R
  output$plot_cost_breakdown <- renderPlotly({
    plot_cost_pie_overview(casm_data)
  })
  
  # Load Factor Area Chart - uses plot_lf_trend() from plots.R
  output$plot_lf_trend <- renderPlotly({
    plot_lf_trend(load_factor)
  })
  
  # Key Findings HTML list with plane bullet points (from custom.css)
  output$key_findings <- renderUI({
    tags$div(
      style = "padding: 10px;",
      tags$ul(class = "findings-list",
              tags$li(strong("CASM 10.65\u00a2"),
                      " \u2014 competitive for 2010-2013 era"),
              tags$li(strong("81.2% load factor"),
                      " \u2014 above industry 80% benchmark"),
              tags$li(strong("$1.44B delay costs"),
                      " \u2014 22% carrier-caused (controllable)"),
              tags$li(strong("Charlotte (CLT)"),
                      " \u2014 strongest hub, 12M pax in 2013"),
              tags$li(strong("Fuel at 17.9%"),
                      " \u2014 well below 30% industry average"),
              tags$li(strong("CASM declining"),
                      " in 2013 Q3-Q4 \u2014 merger synergy signal")
      )
    )
  })
  
  # ══════════════════════════════════════════════════════════
  # TAB 2: ROUTE ANALYTICS — SERVER LOGIC
  # ══════════════════════════════════════════════════════════
  
  # reactive() — this block re-runs automatically whenever
  # input$route_year or input$route_hub changes
  # All charts in this tab call route_data() to get filtered data
  route_data <- reactive({
    df <- load_factor %>%
      filter(YEAR == input$route_year)
    if (input$route_hub != "All") {
      df <- df %>% filter(ORIGIN == input$route_hub)
    }
    df
  })
  
  # Dynamic stats panel that updates with filters
  output$route_summary <- renderUI({
    df <- route_data()
    tags$div(
      style = "margin-top: 5px;",
      # route-stat class styled in custom.css
      div(class = "route-stat",
          span(class = "route-stat-label", "Total Routes"),
          span(class = "route-stat-value",
               n_distinct(paste(df$ORIGIN, df$DEST)))),
      div(class = "route-stat",
          span(class = "route-stat-label", "Total Passengers"),
          span(class = "route-stat-value",
               comma(sum(df$Total_Passengers, na.rm=TRUE)))),
      div(class = "route-stat",
          span(class = "route-stat-label", "Avg Load Factor"),
          span(class = "route-stat-value",
               paste0(round(mean(df$LoadFactor, na.rm=TRUE)*100, 1), "%")))
    )
  })
  
  # Leaflet Interactive Route Map
  # addProviderTiles(CartoDB.Positron) = clean light gray base map
  # addPolylines() draws flight route lines
  # Color by load factor: green=high, navy=mid, red=low
  # addLegend() explains the color coding
  output$route_map <- renderLeaflet({
    # Get top 30 routes and add coordinates via join
    routes <- route_data() %>%
      group_by(ORIGIN, DEST) %>%
      summarise(
        Passengers = sum(Total_Passengers, na.rm=TRUE),
        Avg_LF     = mean(LoadFactor, na.rm=TRUE),
        .groups    = "drop"
      ) %>%
      top_n(30, Passengers) %>%
      left_join(airports, by=c("ORIGIN"="code")) %>%
      left_join(airports %>% rename(lat2=lat, lng2=lng),
                by=c("DEST"="code")) %>%
      filter(!is.na(lat), !is.na(lat2))   # only draw if coords exist
    
    m <- leaflet() %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      setView(lng=-95, lat=37, zoom=4)
    
    # Loop through each route and draw a line
    for (i in seq_len(nrow(routes))) {
      # Choose line color based on load factor performance
      lf_color <- if      (routes$Avg_LF[i] > 0.82) "#10b981"  # green
      else if (routes$Avg_LF[i] > 0.75)  "#003366"  # navy
      else                                "#CC0000"  # red
      
      m <- m %>%
        addPolylines(
          lng     = c(routes$lng[i], routes$lng2[i]),
          lat     = c(routes$lat[i], routes$lat2[i]),
          # Thicker line = more passengers (log scale prevents extremes)
          weight  = max(1, log(routes$Passengers[i]/50000 + 1) * 2),
          color   = lf_color,
          opacity = 0.7,
          popup   = paste0(
            "<div style='font-family:Barlow,sans-serif;'>",
            "<b>", routes$ORIGIN[i], " \u2192 ",
            routes$DEST[i], "</b><br>",
            "Passengers: ", comma(routes$Passengers[i]), "<br>",
            "Load Factor: ", round(routes$Avg_LF[i]*100, 1), "%",
            "</div>"
          )
        )
    }
    
    # Add red circles for hub airports
    m %>%
      addCircleMarkers(
        data        = airports %>% filter(code %in% HUB_AIRPORTS),
        lng         = ~lng,
        lat         = ~lat,
        label       = ~code,
        color       = "#CC0000",
        fillColor   = "#CC0000",
        radius      = 10,
        fillOpacity = 0.9,
        popup       = ~paste0("<b>US Airways Hub: ", code, "</b>")
      ) %>%
      # Color legend for load factor
      addLegend(
        position = "bottomright",
        colors   = c("#10b981","#003366","#CC0000"),
        labels   = c("High LF (>82%)","Mid LF (75-82%)","Low LF (<75%)"),
        title    = "Load Factor",
        opacity  = 0.8
      )
  })
  
  # Top Routes Chart - uses plot_top_routes() from plots.R
  output$plot_top_routes <- renderPlotly({
    plot_top_routes(route_data())
  })
  
  # Load Factor Histogram with 80% benchmark line
  output$plot_lf_dist <- renderPlotly({
    plot_ly(
      route_data(),
      x      = ~LoadFactor * 100,
      type   = "histogram",
      nbinsx = 30,
      marker = list(
        color     = ~LoadFactor * 100,
        colorscale = list(c(0, "#0a4080"), c(1, "#CC0000")),
        showscale  = FALSE,
        line       = list(color="white", width=0.5)
      ),
      hovertemplate = "LF: %{x:.0f}%<br>Routes: %{y}<extra></extra>"
    ) %>%
      aero_layout(xlab="Load Factor %", ylab="Number of Routes") %>%
      layout(
        # Red dashed vertical line at 80% = industry benchmark
        shapes = list(list(
          type = "line",
          x0=80, x1=80, y0=0, y1=1, yref="paper",
          line = list(color="#CC0000", dash="dash", width=2)
        )),
        annotations = list(list(
          x=81, y=0.95, xref="x", yref="paper",
          text="80% benchmark", showarrow=FALSE,
          font=list(color="#CC0000", size=11, family="Barlow")
        ))
      )
  })
  
  # ══════════════════════════════════════════════════════════
  # TAB 3: FLEET COST ANALYSIS — SERVER LOGIC
  # ══════════════════════════════════════════════════════════
  
  # Stacked bar CASM - uses plot_casm_components() from plots.R
  output$plot_casm_components <- renderPlotly({
    plot_casm_components(casm_data)
  })
  
  # Cost breakdown donut (total $ amounts not CASM)
  output$plot_cost_pie <- renderPlotly({
    total <- sum(p52_quarterly$TOT_AIR_OP_EXPENSES, na.rm=TRUE)
    fuel  <- sum(p52_quarterly$FUEL_FLY_OPS,         na.rm=TRUE)
    labor <- sum(p52_quarterly$PILOT_FLY_OPS,        na.rm=TRUE)
    maint <- sum(p52_quarterly$TOT_DIR_MAINT,         na.rm=TRUE)
    other <- total - fuel - labor - maint
    
    plot_ly(
      labels   = c("Fuel","Labor","Maintenance","Other"),
      values   = c(fuel, labor, maint, other),
      type     = "pie",
      hole     = 0.4,     # hole=0.4 creates donut chart
      marker   = list(
        colors = c("#CC0000","#003366","#64748b","#94a3b8"),
        line   = list(color="white", width=2)
      ),
      textinfo = "label+percent",
      textfont = list(family="Barlow", size=11)
    ) %>%
      layout(
        plot_bgcolor  = "rgba(0,0,0,0)",
        paper_bgcolor = "rgba(0,0,0,0)",
        showlegend    = TRUE,
        legend        = list(font=list(family="Barlow", size=11))
      )
  })
  
  # Year-over-year CASM change chart
  # Green bars = improvement (CASM went down)
  # Red bars   = increase (CASM went up)
  output$plot_casm_yoy <- renderPlotly({
    yoy <- casm_data %>%
      group_by(YEAR) %>%
      summarise(Annual_CASM = mean(CASM, na.rm=TRUE), .groups="drop") %>%
      mutate(
        # lag() gets previous year's value for comparison
        YoY_Change = (Annual_CASM / lag(Annual_CASM) - 1) * 100
      )
    
    plot_ly(
      yoy %>% filter(!is.na(YoY_Change)),
      x    = ~as.factor(YEAR),
      y    = ~YoY_Change,
      type = "bar",
      marker = list(
        # ifelse = green if improvement, red if increase
        color = ~ifelse(YoY_Change > 0, "#CC0000", "#10b981")
      ),
      text         = ~paste0(round(YoY_Change, 1), "%"),
      textposition = "outside",
      hovertemplate = "Year: %{x}<br>Change: %{y:.1f}%<extra></extra>"
    ) %>%
      aero_layout(xlab="Year", ylab="CASM Change (%)") %>%
      # Horizontal zero line for reference
      layout(shapes = list(list(
        type="line", x0=0, x1=1, xref="paper",
        y0=0, y1=0,
        line=list(color="#334155", width=1)
      )))
  })
  
  # Cost efficiency quick stats panel
  output$efficiency_metrics <- renderUI({
    tags$div(
      style = "padding: 10px;",
      div(class="route-stat",
          span(class="route-stat-label", "Total 4-Year Op Cost"),
          span(class="route-stat-value",
               dollar(sum(p52_quarterly$TOT_AIR_OP_EXPENSES)))),
      div(class="route-stat",
          span(class="route-stat-label", "Avg Quarterly Cost"),
          span(class="route-stat-value",
               dollar(mean(p52_quarterly$TOT_AIR_OP_EXPENSES)))),
      div(class="route-stat",
          span(class="route-stat-label", "Total Fuel Cost"),
          span(class="route-stat-value",
               dollar(sum(p52_quarterly$FUEL_FLY_OPS)))),
      div(class="route-stat",
          span(class="route-stat-label", "Fuel Share"),
          span(class="route-stat-value",
               paste0(round(
                 sum(p52_quarterly$FUEL_FLY_OPS) /
                   sum(p52_quarterly$TOT_AIR_OP_EXPENSES) * 100, 1),
                 "%"))),
      div(class="route-stat",
          span(class="route-stat-label", "Best CASM Quarter"),
          span(class="route-stat-value",
               casm_data$Period[which.min(casm_data$CASM)]))
    )
  })
  
  # Expense table with search and sort
  output$table_expenses <- renderDT({
    p52_quarterly %>%
      mutate(
        Period     = paste0(YEAR, " Q", QUARTER),
        Total_Cost = dollar(TOT_AIR_OP_EXPENSES),
        Fuel_Cost  = dollar(FUEL_FLY_OPS),
        Labor_Cost = dollar(PILOT_FLY_OPS),
        Maint_Cost = dollar(TOT_DIR_MAINT),
        # Calculate fuel % for each quarter
        Fuel_Pct   = paste0(round(
          FUEL_FLY_OPS / TOT_AIR_OP_EXPENSES * 100, 1), "%")
      ) %>%
      select(Period, Total_Cost, Fuel_Cost,
             Labor_Cost, Maint_Cost, Fuel_Pct) %>%
      datatable(
        options  = list(pageLength=8, scrollX=TRUE),
        rownames = FALSE,
        colnames = c("Period","Total Cost","Fuel",
                     "Labor","Maintenance","Fuel %")
      )
  })
  
  # ══════════════════════════════════════════════════════════
  # TAB 4: FUEL INTELLIGENCE — SERVER LOGIC
  # ══════════════════════════════════════════════════════════
  
  # KPI: Average fuel price per gallon
  output$box_avg_fuel_price <- renderValueBox({
    valueBox(
      value    = paste0("$", round(mean(fuel_metrics$FuelPerGallon,
                                        na.rm=TRUE), 2)),
      subtitle = "Avg Fuel Price per Gallon",
      icon     = icon("gas-pump"),
      color    = "orange"
    )
  })
  
  # KPI: Total fuel cost
  # FIXED: uses fuel_metrics (already filtered to US Airways only)
  # Previously was using raw p12a which had all carriers = inflated number
  output$box_total_fuel_cost <- renderValueBox({
    valueBox(
      value    = paste0("$", round(
        sum(fuel_metrics$TOTAL_COST, na.rm=TRUE)/1e9, 2), "B"),
      subtitle = "Total Fuel Cost (US Airways)",
      icon     = icon("dollar-sign"),
      color    = "red"
    )
  })
  
  # KPI: Fuel as % of total cost
  output$box_fuel_pct <- renderValueBox({
    valueBox(
      value    = paste0(round(mean(fuel_metrics$Fuel_Pct_Total_Cost,
                                   na.rm=TRUE), 1), "%"),
      subtitle = "Fuel % of Total Cost",
      icon     = icon("percent"),
      color    = "yellow"
    )
  })
  
  # Fuel price line chart - uses plot_fuel_price() from plots.R
  output$plot_fuel_price <- renderPlotly({
    plot_fuel_price(fuel_metrics)
  })
  
  # Fuel vs total cost grouped bar
  output$plot_fuel_vs_total <- renderPlotly({
    plot_ly(fuel_metrics, x=~Period) %>%
      add_trace(y=~TOT_AIR_OP_EXPENSES, name="Total Op Cost",
                type="bar",
                marker=list(color="#003366",
                            line=list(color="white", width=0.5))) %>%
      add_trace(y=~TOTAL_COST, name="Fuel Cost",
                type="bar",
                marker=list(color="#CC0000",
                            line=list(color="white", width=0.5))) %>%
      aero_layout(xlab="Quarter", ylab="Cost ($)") %>%
      layout(barmode="group", xaxis=list(tickangle=-45))
  })
  
  # Fuel % trend with industry benchmark reference line at 30%
  output$plot_fuel_pct_trend <- renderPlotly({
    plot_ly(
      fuel_metrics, x=~Period, y=~Fuel_Pct_Total_Cost,
      type="scatter", mode="lines+markers",
      fill      = "tozeroy",
      line      = list(color="#f59e0b", width=2.5, shape="spline"),
      marker    = list(color="#f59e0b", size=7,
                       line=list(color="white", width=1.5)),
      fillcolor = "rgba(245,158,11,0.15)",
      hovertemplate = "%{x}<br>Fuel %: %{y:.1f}%<extra></extra>"
    ) %>%
      aero_layout(xlab="Quarter", ylab="Fuel % of Total Cost") %>%
      layout(
        xaxis  = list(tickangle=-45),
        # Red dashed reference line at 30% (industry average)
        shapes = list(list(
          type="line", x0=0, x1=1, xref="paper",
          y0=30, y1=30,
          line=list(color="red", dash="dash", width=1.5)
        )),
        annotations = list(list(
          x=0.02, y=31, xref="paper",
          text="Industry avg 30%", showarrow=FALSE,
          font=list(color="red", size=11, family="Barlow")
        ))
      )
  })
  
  # ══════════════════════════════════════════════════════════
  # TAB 5: HUB PERFORMANCE — SERVER LOGIC
  # ══════════════════════════════════════════════════════════
  
  # Hub passengers bar - uses plot_hub_passengers() from plots.R
  output$plot_hub_passengers <- renderPlotly({
    plot_hub_passengers(hub_perf)
  })
  
  # Hub load factor line chart
  # as.factor(YEAR) FIXED the decimal year axis bug
  output$plot_hub_lf <- renderPlotly({
    plot_ly(
      hub_perf,
      x      = ~as.factor(YEAR),   # factor prevents 2010.5, 2011.0 etc.
      y      = ~Avg_LoadFactor_Pct,
      color  = ~Hub_Name,
      type   = "scatter",
      mode   = "lines+markers",
      colors = c("#003366","#CC0000","#64748b"),
      marker = list(size=8),
      hovertemplate =
        "<b>%{fullData.name}</b><br>%{x}: %{y:.1f}%<extra></extra>"
    ) %>%
      aero_layout(xlab="Year", ylab="Load Factor %") %>%
      layout(yaxis=list(range=c(75, 90)))
  })
  
  # Unique routes per hub
  output$plot_hub_routes <- renderPlotly({
    plot_ly(hub_perf,
            x      = ~as.factor(YEAR),
            y      = ~Unique_Routes,
            color  = ~Hub_Name,
            type   = "bar",
            colors = c("#003366","#CC0000","#64748b")) %>%
      aero_layout(xlab="Year", ylab="Unique Destinations") %>%
      layout(barmode="group")
  })
  
  # Total departures per hub
  output$plot_hub_departures <- renderPlotly({
    plot_ly(hub_perf,
            x      = ~as.factor(YEAR),
            y      = ~Total_Departures,
            color  = ~Hub_Name,
            type   = "bar",
            colors = c("#003366","#CC0000","#64748b")) %>%
      aero_layout(xlab="Year", ylab="Total Departures") %>%
      layout(barmode="group")
  })
  
  # Hub scorecard cards with color-coded load factor badges
  # badge-good / badge-warn / badge-bad classes from custom.css
  output$hub_summary_cards <- renderUI({
    latest <- hub_perf %>% filter(YEAR == 2013)
    tags$div(
      style="padding:5px;",
      lapply(1:nrow(latest), function(i) {
        row <- latest[i, ]
        badge_class <- if      (row$Avg_LoadFactor_Pct > 83) "badge-good"
        else if (row$Avg_LoadFactor_Pct > 80) "badge-warn"
        else                                   "badge-bad"
        div(
          style="margin-bottom:10px; padding:10px;
                 background:#f8f9fc; border-radius:8px;
                 border-left:3px solid #003366;",
          tags$b(row$Hub_Name), tags$br(),
          tags$small(
            comma(row$Total_Passengers), " pax | ",
            row$Unique_Routes, " routes"
          ),
          tags$br(),
          span(class=paste("metric-badge", badge_class),
               paste0(round(row$Avg_LoadFactor_Pct, 1), "% LF"))
        )
      })
    )
  })
  
  # Full hub data table
  output$table_hubs <- renderDT({
    hub_perf %>%
      mutate(
        Load_Factor = paste0(round(Avg_LoadFactor_Pct, 1), "%"),
        Passengers  = comma(Total_Passengers),
        Departures  = comma(Total_Departures),
        ASM         = comma(round(Total_ASM/1e9, 2))
      ) %>%
      select(YEAR, Hub_Name, Departures, Passengers,
             Load_Factor, Unique_Routes, ASM) %>%
      datatable(
        options  = list(pageLength=12, scrollX=TRUE),
        rownames = FALSE,
        colnames = c("Year","Hub","Departures","Passengers",
                     "Load Factor","Routes","ASM (Billions)")
      )
  })
  
  # ══════════════════════════════════════════════════════════
  # TAB 6: DELAY COST IMPACT — SERVER LOGIC
  # ══════════════════════════════════════════════════════════
  
  # KPI: Total delayed flights count
  output$box_total_delays <- renderValueBox({
    valueBox(
      value    = comma(sum(delay_costs$Total_Delayed_Flights,
                           na.rm=TRUE)),
      subtitle = "Total Delayed Flights (2010\u20132013)",
      icon     = icon("plane"),
      color    = "red"
    )
  })
  
  # KPI: Average minutes delayed per delayed flight
  output$box_avg_delay <- renderValueBox({
    valueBox(
      value    = paste0(round(mean(delay_costs$Avg_Delay_Minutes,
                                   na.rm=TRUE), 1), " min"),
      subtitle = "Avg Delay per Delayed Flight",
      icon     = icon("clock"),
      color    = "orange"
    )
  })
  
  # KPI: Total estimated delay cost in billions
  output$box_total_delay_cost <- renderValueBox({
    valueBox(
      value    = paste0("$", round(
        sum(delay_costs$Total_Delay_Cost_USD, na.rm=TRUE)/1e9, 2), "B"),
      subtitle = "Total Estimated Delay Cost ($100/min)",
      icon     = icon("dollar-sign"),
      color    = "red"
    )
  })
  
  # Monthly delay cost area chart - uses plot_delay_trend() from plots.R
  output$plot_delay_trend <- renderPlotly({
    plot_delay_trend(delay_costs)
  })
  
  # Delay cause donut chart
  # Carrier = airline's fault = can be improved
  # Weather = external = unavoidable
  # Other = NAS delays, late aircraft
  output$plot_delay_causes <- renderPlotly({
    avg_causes <- delay_costs %>%
      summarise(
        Carrier = mean(Carrier_Delay_Pct, na.rm=TRUE),
        Weather = mean(Weather_Delay_Pct, na.rm=TRUE)
      ) %>%
      mutate(Other = 100 - Carrier - Weather)
    
    plot_ly(
      labels   = c("Carrier (Controllable)",
                   "Weather (Uncontrollable)",
                   "Other (NAS/Late Aircraft)"),
      values   = c(avg_causes$Carrier, avg_causes$Weather,
                   avg_causes$Other),
      type     = "pie",
      hole     = 0.4,
      marker   = list(
        colors=c("#CC0000","#003366","#94a3b8"),
        line=list(color="white", width=2)
      ),
      textinfo = "label+percent",
      textfont = list(family="Barlow", size=11)
    ) %>%
      layout(plot_bgcolor="rgba(0,0,0,0)",
             paper_bgcolor="rgba(0,0,0,0)",
             showlegend=FALSE)
  })
  
  # Carrier vs weather delay % line chart over time
  output$plot_delay_types <- renderPlotly({
    plot_ly(delay_costs, x=~Date) %>%
      add_trace(y=~Carrier_Delay_Pct, name="Carrier %",
                type="scatter", mode="lines",
                line=list(color="#CC0000", width=2, shape="spline")) %>%
      add_trace(y=~Weather_Delay_Pct, name="Weather %",
                type="scatter", mode="lines",
                line=list(color="#003366", width=2, shape="spline")) %>%
      aero_layout(xlab="", ylab="% of Delayed Flights") %>%
      layout(hovermode="x unified")
  })
  
  # ══════════════════════════════════════════════════════════
  # TAB 7: COST SIMULATOR — SERVER LOGIC
  # ══════════════════════════════════════════════════════════
  # eventReactive() waits for button click before running
  # ignoreNULL=FALSE means it runs once on app load with defaults
  # This is your unique differentiating feature
  
  sim_results <- eventReactive(input$btn_simulate, {
    
    # Step 1: Get current baseline financial values
    current_casm      <- mean(casm_data$CASM, na.rm=TRUE)
    current_asm       <- sum(t100_quarterly$Total_ASM, na.rm=TRUE)
    current_fuel_cost <- sum(fuel_metrics$TOTAL_COST, na.rm=TRUE)
    current_gallons   <- sum(p12a$TOTAL_GALLONS, na.rm=TRUE)
    current_delay     <- sum(delay_costs$Total_Delay_Cost_USD, na.rm=TRUE)
    
    # Step 2: Apply user's simulation parameters
    # New CASM = current × (1 - reduction%)
    new_casm       <- current_casm * (1 - input$sim_casm_reduction/100)
    # New total operating cost = new CASM × same ASM
    new_total_cost <- new_casm * current_asm
    # New fuel cost = same gallons × new fuel price
    new_fuel_cost  <- current_gallons * input$sim_fuel_price
    # New delay cost = current × (1 - reduction%)
    new_delay_cost <- current_delay * (1 - input$sim_delay_reduction/100)
    
    # Step 3: Calculate savings from each intervention
    casm_saving  <- (current_casm - new_casm) * current_asm
    fuel_saving  <- current_fuel_cost - new_fuel_cost
    delay_saving <- current_delay - new_delay_cost
    total_saving <- casm_saving + delay_saving  # combined annual saving
    
    # Return all results as a named list
    list(
      current_casm   = current_casm,
      new_casm       = new_casm,
      casm_saving    = casm_saving,
      fuel_saving    = fuel_saving,
      delay_saving   = delay_saving,
      total_saving   = total_saving,
      new_fuel_cost  = new_fuel_cost,
      new_delay_cost = new_delay_cost
    )
  }, ignoreNULL = FALSE)
  
  # Dark result card showing total savings
  output$sim_cost_saving <- renderUI({
    res <- sim_results()
    # simulator-result class styled in custom.css
    div(class="simulator-result",
        tags$h3(dollar(res$total_saving)),
        tags$p("Estimated Annual Savings")
    )
  })
  
  # Dark result card showing new CASM
  output$sim_new_casm <- renderUI({
    res <- sim_results()
    div(class="simulator-result",
        tags$h3(paste0(round(res$new_casm*100, 2), "\u00a2")),
        tags$p("New CASM (was 10.65\u00a2)")
    )
  })
  
  # Bar chart showing savings breakdown by category
  output$plot_simulator <- renderPlotly({
    res    <- sim_results()
    cats   <- c("Fleet/CASM\nSavings", "Delay\nSavings",
                "Fuel\nImpact")
    vals   <- c(res$casm_saving, res$delay_saving, res$fuel_saving)
    colors <- ifelse(vals > 0, "#10b981", "#CC0000")
    
    plot_ly(
      x      = cats,
      y      = vals,
      type   = "bar",
      marker = list(color=colors,
                    line=list(color="white", width=0.5)),
      text   = dollar(abs(vals)),
      textposition = "outside",
      hovertemplate = "<b>%{x}</b><br>$%{y:,.0f}<extra></extra>"
    ) %>%
      aero_layout(xlab="", ylab="Financial Impact ($)") %>%
      layout(shapes=list(list(
        type="line", x0=0, x1=1, xref="paper",
        y0=0, y1=0,
        line=list(color="#334155", width=1)
      )))
  })
  
  # Plain-English interpretation of simulation results
  output$sim_interpretation <- renderUI({
    res <- sim_results()
    tags$div(
      style="padding:10px; background:#f8f9fc;
             border-radius:8px; font-size:13px;",
      tags$p(
        icon("lightbulb", style="color:#f59e0b;"), " ",
        strong("Interpretation: "),
        paste0(
          "A ", input$sim_casm_reduction, "% CASM reduction ",
          "combined with ", input$sim_delay_reduction,
          "% fewer delays would save approximately ",
          dollar(res$total_saving), " annually. ",
          "At $", input$sim_fuel_price, "/gallon, fuel costs would ",
          ifelse(input$sim_fuel_price < 2.81,
                 "decrease, providing additional financial relief.",
                 "increase, adding cost pressure to operations.")
        )
      )
    )
  })
  
  # Pre-defined scenarios comparison table
  output$table_scenarios <- renderDT({
    scenarios <- data.frame(
      Scenario = c(
        "Baseline (Actual 2010-2013)",
        "Fleet Optimization (10% CASM cut)",
        "Fuel Hedging (15% fuel savings)",
        "Operational Delay Reduction (30%)",
        "Combined Best Case"
      ),
      CASM = c(
        "10.65\u00a2", "9.59\u00a2", "10.65\u00a2",
        "10.65\u00a2", "8.52\u00a2"
      ),
      Annual_Saving = c(
        "$0",
        dollar(mean(casm_data$CASM)*0.10*
                 sum(t100_quarterly$Total_ASM)),
        dollar(sum(fuel_metrics$TOTAL_COST)*0.15),
        dollar(sum(delay_costs$Total_Delay_Cost_USD)*0.30/4),
        dollar(mean(casm_data$CASM)*0.20*
                 sum(t100_quarterly$Total_ASM) +
                 sum(delay_costs$Total_Delay_Cost_USD)*0.30/4)
      ),
      Feasibility = c("N/A","High","Medium","High","Low")
    )
    datatable(
      scenarios,
      rownames = FALSE,
      options  = list(dom="t", pageLength=10),
      colnames = c("Scenario","CASM","Annual Saving","Feasibility")
    )
  })
  
  # ══════════════════════════════════════════════════════════
  # TAB 8: LIVE BENCHMARKS — SERVER LOGIC
  # ══════════════════════════════════════════════════════════
  
  # CASM comparison: US Airways (2010-13) vs industry (2024)
  output$plot_benchmark_casm <- renderPlotly({
    us_casm  <- round(mean(casm_data$CASM, na.rm=TRUE)*100, 2)
    ind_casm <- 11.2   # 2024 BTS industry average (cents/ASM)
    
    plot_ly(
      x      = c("Industry\n2024", "US Airways\n2010-2013"),
      y      = c(ind_casm, us_casm),
      type   = "bar",
      marker = list(color=c("#CC0000","#003366"),
                    line=list(color="white", width=0.5)),
      text   = c(paste0(ind_casm,"\u00a2"), paste0(us_casm,"\u00a2")),
      textposition = "outside",
      hovertemplate = "<b>%{x}</b><br>CASM: %{y}\u00a2<extra></extra>"
    ) %>%
      aero_layout(xlab="", ylab="CASM (cents per ASM)") %>%
      layout(yaxis=list(range=c(0, 14)))
  })
  
  # Load factor comparison
  output$plot_benchmark_lf <- renderPlotly({
    us_lf  <- round(mean(load_factor$LoadFactor, na.rm=TRUE)*100, 1)
    ind_lf <- 85.3   # 2024 BTS industry average load factor
    
    plot_ly(
      x      = c("Industry\n2024", "US Airways\n2010-2013"),
      y      = c(ind_lf, us_lf),
      type   = "bar",
      marker = list(color=c("#CC0000","#003366"),
                    line=list(color="white", width=0.5)),
      text   = c(paste0(ind_lf,"%"), paste0(us_lf,"%")),
      textposition = "outside",
      hovertemplate = "<b>%{x}</b><br>LF: %{y}%<extra></extra>"
    ) %>%
      aero_layout(xlab="", ylab="Load Factor %") %>%
      layout(yaxis=list(range=c(70, 90)))
  })
  
  # Written analysis of what the benchmark comparison means
  output$benchmark_summary <- renderUI({
    us_casm <- round(mean(casm_data$CASM, na.rm=TRUE)*100, 2)
    us_lf   <- round(mean(load_factor$LoadFactor, na.rm=TRUE)*100, 1)
    
    tags$div(
      style="padding:15px;",
      tags$h4(style="color:#003366;
                     font-family:'Barlow Condensed';",
              "What This Means"),
      fluidRow(
        column(6,
               tags$ul(class="findings-list",
                       tags$li(
                         strong("CASM: "), us_casm,
                         "\u00a2 (US Airways) vs 11.2\u00a2 (Industry 2024) \u2014 ",
                         "US Airways was more cost-efficient than today's average,
               despite operating older aircraft"
                       ),
                       tags$li(
                         strong("Load Factor: "), us_lf,
                         "% (US Airways) vs 85.3% (Industry 2024) \u2014 ",
                         "Today's airlines fill ~4% more seats, driven by
               post-merger capacity discipline"
                       )
               )
        ),
        column(6,
               tags$ul(class="findings-list",
                       tags$li(
                         strong("Merger Impact: "),
                         "The AA+US Airways merger created significant cost
               synergies that contributed to industry-wide CASM
               improvements post-2013"
                       ),
                       tags$li(
                         strong("Key Takeaway: "),
                         "US Airways was operationally efficient but faced
               structural cost pressures that made merger with
               American Airlines the financially logical path"
                       )
               )
        )
      )
    )
  })
  
}  # end server function

# ============================================================
# LAUNCH THE APP
# ============================================================
# shinyApp() combines UI + SERVER and launches the application
# Run from RStudio console using: shiny::runApp()
# Do NOT run shinyApp() directly in console after sourcing files

shinyApp(ui = ui, server = server)