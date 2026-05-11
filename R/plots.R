# ============================================================
# PLOTS.R - Reusable Chart Functions for AeroInsight BI
# ============================================================
# WHY THIS FILE EXISTS:
# Instead of writing chart code directly in server.R/app.R,
# we define reusable functions here.
# Benefits:
# 1. Consistent styling across ALL charts
# 2. Easy to update - change once, affects all charts
# 3. Cleaner app.R code
# 4. Easier debugging
# ============================================================

# ── AEROINSIGHT PLOT THEME ────────────────────────────────
# Default layout applied to ALL plotly charts
# Ensures consistent fonts, colors, gridlines everywhere

aero_layout <- function(p, title="", xlab="", ylab="") {
  p %>% layout(
    title = list(
      text = title,
      font = list(family="Barlow Condensed", size=16,
                  color="#003366")
    ),
    xaxis = list(
      title      = xlab,
      tickfont   = list(family="Barlow", size=11, color="#334155"),
      titlefont  = list(family="Barlow", size=12, color="#334155"),
      gridcolor  = "#e8ecf0",
      linecolor  = "#e8ecf0",
      showgrid   = TRUE,
      zeroline   = FALSE
    ),
    yaxis = list(
      title      = ylab,
      tickfont   = list(family="JetBrains Mono", size=11,
                        color="#334155"),
      titlefont  = list(family="Barlow", size=12, color="#334155"),
      gridcolor  = "#e8ecf0",
      linecolor  = "#e8ecf0",
      showgrid   = TRUE,
      zeroline   = FALSE
    ),
    plot_bgcolor  = "rgba(0,0,0,0)",
    paper_bgcolor = "rgba(0,0,0,0)",
    margin        = list(l=50, r=20, t=30, b=50),
    font          = list(family="Barlow"),
    hovermode     = "closest",
    legend        = list(
      font        = list(family="Barlow", size=11),
      bgcolor     = "rgba(255,255,255,0.9)",
      bordercolor = "#e8ecf0",
      borderwidth = 1
    )
  )
}

# ── PLOT FUNCTIONS ────────────────────────────────────────

# 1. CASM Trend Line Chart
plot_casm_trend <- function(data) {
  plot_ly(data, x=~Period, y=~CASM,
          type="scatter", mode="lines+markers",
          line   = list(color="#003366", width=2.5,
                        shape="spline"),
          marker = list(color="#003366", size=7,
                        line=list(color="white", width=1.5)),
          fill   = "tozeroy",
          fillcolor = "rgba(0,51,102,0.08)",
          hovertemplate = "<b>%{x}</b><br>CASM: $%{y:.4f}<extra></extra>") %>%
    aero_layout(xlab="Quarter", ylab="CASM ($)")
}

# 2. Cost Breakdown Pie Chart
plot_cost_pie_overview <- function(data) {
  avg <- data %>%
    summarise(
      Fuel        = mean(Fuel_CASM,  na.rm=TRUE),
      Labor       = mean(Labor_CASM, na.rm=TRUE),
      Maintenance = mean(Maint_CASM, na.rm=TRUE)
    )
  plot_ly(
    labels   = names(avg),
    values   = as.numeric(avg),
    type     = "pie",
    hole     = 0.45,  # donut style - more modern
    marker   = list(
      colors = c("#CC0000","#003366","#64748b"),
      line   = list(color="white", width=2)
    ),
    textinfo     = "label+percent",
    textfont     = list(family="Barlow", size=12),
    hovertemplate = "<b>%{label}</b><br>%{percent}<extra></extra>"
  ) %>%
    layout(
      showlegend    = TRUE,
      plot_bgcolor  = "rgba(0,0,0,0)",
      paper_bgcolor = "rgba(0,0,0,0)",
      legend        = list(font=list(family="Barlow", size=11)),
      annotations   = list(list(
        text      = "CASM",
        x         = 0.5, y = 0.5,
        font      = list(family="Barlow Condensed", size=16,
                         color="#003366", weight=700),
        showarrow = FALSE
      ))
    )
}

# 3. Load Factor Area Chart
plot_lf_trend <- function(load_factor) {
  lf_monthly <- load_factor %>%
    group_by(YEAR, MONTH) %>%
    summarise(Avg_LF = mean(LoadFactor, na.rm=TRUE)*100,
              .groups="drop") %>%
    mutate(Date = as.Date(paste(YEAR, MONTH, "01", sep="-")))
  
  plot_ly(lf_monthly, x=~Date, y=~Avg_LF,
          type="scatter", mode="lines",
          fill      = "tozeroy",
          line      = list(color="#003366", width=2,
                           shape="spline"),
          fillcolor = "rgba(0,51,102,0.15)",
          hovertemplate = "<b>%{x|%b %Y}</b><br>Load Factor: %{y:.1f}%<extra></extra>") %>%
    aero_layout(xlab="", ylab="Load Factor %") %>%
    layout(yaxis=list(range=c(60,95)),
           shapes=list(list(
             type="line", x0=0, x1=1, xref="paper",
             y0=80, y1=80,
             line=list(color="#CC0000", dash="dot", width=1.5)
           )))
}

# 4. CASM Components Stacked Bar
plot_casm_components <- function(data) {
  plot_ly(data, x=~Period) %>%
    add_trace(y=~Fuel_CASM,  name="Fuel",
              type="bar",
              marker=list(color="#CC0000",
                          line=list(color="white",width=0.5))) %>%
    add_trace(y=~Labor_CASM, name="Labor",
              type="bar",
              marker=list(color="#003366",
                          line=list(color="white",width=0.5))) %>%
    add_trace(y=~Maint_CASM, name="Maintenance",
              type="bar",
              marker=list(color="#64748b",
                          line=list(color="white",width=0.5))) %>%
    aero_layout(xlab="Quarter", ylab="CASM ($)") %>%
    layout(
      barmode = "stack",
      xaxis   = list(tickangle=-45)
    )
}

# 5. Fuel Price Trend
plot_fuel_price <- function(fuel_metrics) {
  plot_ly(fuel_metrics, x=~Period, y=~FuelPerGallon,
          type="scatter", mode="lines+markers",
          line   = list(color="#CC0000", width=2.5,
                        shape="spline"),
          marker = list(color="#CC0000", size=7,
                        line=list(color="white", width=1.5)),
          hovertemplate = "<b>%{x}</b><br>$%{y:.2f}/gallon<extra></extra>") %>%
    aero_layout(xlab="Quarter", ylab="$ per Gallon") %>%
    layout(xaxis=list(tickangle=-45))
}

# 6. Hub Passengers Bar Chart
plot_hub_passengers <- function(hub_perf) {
  plot_ly(hub_perf,
          x      = ~as.factor(YEAR),
          y      = ~Total_Passengers,
          color  = ~Hub_Name,
          type   = "bar",
          colors = c("#003366","#CC0000","#64748b"),
          hovertemplate = "<b>%{fullData.name}</b><br>Year: %{x}<br>Passengers: %{y:,}<extra></extra>") %>%
    aero_layout(xlab="Year", ylab="Total Passengers") %>%
    layout(barmode="group")
}

# 7. Delay Cost Trend
plot_delay_trend <- function(delay_costs) {
  plot_ly(delay_costs, x=~Date, y=~Total_Delay_Cost_USD,
          type="scatter", mode="lines",
          fill      = "tozeroy",
          line      = list(color="#CC0000", width=2,
                           shape="spline"),
          fillcolor = "rgba(204,0,0,0.12)",
          hovertemplate = "<b>%{x|%b %Y}</b><br>Cost: $%{y:,.0f}<extra></extra>") %>%
    aero_layout(xlab="", ylab="Estimated Delay Cost ($)")
}

# 8. Top Routes Horizontal Bar
plot_top_routes <- function(route_df) {
  route_df %>%
    group_by(ORIGIN, DEST) %>%
    summarise(Total_Pax = sum(Total_Passengers, na.rm=TRUE),
              .groups="drop") %>%
    top_n(20, Total_Pax) %>%
    mutate(Route = paste(ORIGIN, "→", DEST)) %>%
    arrange(Total_Pax) %>%
    plot_ly(
      x           = ~Total_Pax,
      y           = ~reorder(Route, Total_Pax),
      type        = "bar",
      orientation = "h",
      marker      = list(
        color     = ~Total_Pax,
        colorscale = list(c(0,"#0a4080"), c(1,"#CC0000")),
        showscale  = FALSE,
        line       = list(color="white", width=0.5)
      ),
      hovertemplate = "<b>%{y}</b><br>Passengers: %{x:,}<extra></extra>"
    ) %>%
    aero_layout(xlab="Total Passengers", ylab="")
}

cat("✅ plots.R loaded - all chart functions ready\n")