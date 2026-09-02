# Tourism Demand Forecasting — SARIMA Models for Melbourne Business & Holiday Trips

Quarterly time series forecasting of tourism demand to Melbourne, Australia (1998–2017), comparing Business vs. Holiday travel patterns and fitting seasonal ARIMA models to forecast 8 quarters ahead.

## Overview

Business and Holiday travel to a destination don't necessarily follow the same rhythm — different drivers, different seasonality, different growth trajectories. This project takes 20 years of quarterly trip data, split by travel purpose, and asks: **do these two series need different models, and can we forecast each reliably?**

The answer is yes to both. The two series required different decomposition models (additive for Business, multiplicative for Holiday, since Holiday's seasonal swings grow with the trend) and different final SARIMA specifications, but both produced white-noise residuals — meaning the fitted models capture the available structure well.

## Key Findings

- **Both series trended upward** over 1998–2017, but Holiday travel grew faster: **+100%** (400 → 800 trips) vs. Business's **+57%** (400 → 700 trips).
- **Business trips show clear quarterly seasonality tied to mid-year peaks** (Q2–Q3), while Holiday trips peak in Q3 with a wider Q4 spread — consistent with school/public holiday timing.
- **Different decomposition models fit better for each series**: additive for Business (seasonal swings stay constant in size as the trend rises), multiplicative for Holiday (seasonal swings grow proportionally with the trend).
- **Final models**: `ARIMA(1,1,2)(2,1,0)₄` for Business, `ARIMA(0,1,1)(1,1,1)₄` for Holiday — both selected via an exhaustive CAIC search, restricted to at most one order of differencing per level after an unrestricted search proved unstable to estimate at this sample size (n=80).
- **No volatility clustering** in either series' residuals — an ARCH/GARCH extension isn't warranted.
- 8-quarter-ahead forecasts (2018 Q1–2019 Q4) continue each series' trend and seasonal pattern, with prediction intervals widening from ~230 trips (Business) / ~223 trips (Holiday) at 1 quarter ahead to ~294 / ~245 trips at 8 quarters ahead.

### Business Series Forecast
![Business forecast](docs/images/business_forecast.png)

### Holiday Series Forecast
![Holiday forecast](docs/images/holiday_forecast.png)

## Tech Stack

- **R**, using `forecast` and `tseries` packages for SARIMA fitting, ACF/PACF diagnostics, and forecasting
- **LaTeX** for the written report

## Project Structure

```
tourism-time-series-forecasting/
├── scripts/
│   ├── tourism_sarima_analysis.R                # Original script
│   ├── tourism_sarima_analysis_reproducible.R    # Fixed paths + figure export (see note below)
├── report/
│   ├── main.tex, Q0.tex – Q6.tex                 # LaTeX source, by section
│   └── fig/                                      # Figures for the report, compiled by R
├── docs/
│   ├── Tourism_SARIMA_Forecasting_Report.pdf     # Compiled report (ready to read)
│   └── images/                                   # README chart images
├── data/
│   └── README.md                                 # Dataset description
└── README.md
```

## Getting Started

**To read the report:** open `docs/Tourism_SARIMA_Forecasting_Report.pdf` directly — no setup needed.

**To reproduce the analysis:**
```bash
git clone <repo-url>
cd tourism-time-series-forecasting
```
Place your copy of the tourism dataset at `data/tourism_Project.csv` (see `data/README.md`), then:
```bash
cd scripts
Rscript tourism_sarima_analysis_reproducible.R
```
This regenerates all 29 figures referenced in the report into `scripts/figures/`. See `report/README.md` for how to then compile the LaTeX source to PDF.

## Methodology

1. **Data description** — 80 quarterly observations (1998 Q1–2017 Q4) each for Business and Holiday trips to Melbourne, Victoria.
2. **Exploratory analysis** — time plots, annual aggregates, and seasonal boxplots for both series.
3. **Decomposition** — additive and multiplicative models compared for each series; additive selected for Business, multiplicative for Holiday, based on which produced more stable (constant-variance) residuals.
4. **Correlation structure** — ACF/PACF confirm both series are non-stationary, with Business showing strong seasonal autocorrelation and Holiday showing strong trend-driven autocorrelation.
5. **Model fitting** — first and seasonal differencing applied, then an exhaustive SARIMA search (via a custom `get.best.sarima()` function minimizing CAIC) identifies the best-fitting model within a differencing-order-restricted search space. All final coefficients are statistically significant (95% CIs exclude zero).
6. **Forecasting** — 8-quarter-ahead point forecasts and 95% prediction intervals for both series.
7. **Volatility check** — squared-residual ACF shows no significant autocorrelation for either series, ruling out conditional heteroskedasticity.

## My Contribution

This was a 2-person group project for a Time Series course. Per the report's own contribution table: **I (Indayang Fyna Desyna) conducted the complete analysis, R implementation, interpretation, and report writing for the Business series**, and also handled all report typesetting/LaTeX integration and presentation slides for the Business series. My groupmate independently conducted the full parallel analysis for the Holiday series using the same structure.

## Limitations

- Sample size (n=80) limits how much seasonal differencing can be reliably estimated — an unrestricted model search selected a model with `D=2` for the Business series, but confidence intervals for most of its coefficients couldn't be computed reliably, so that model was not pursued.
- Forecasts assume the historical trend and seasonal pattern continue unchanged; neither model accounts for external shocks (economic conditions, policy changes, unexpected events).
- `CSS` (conditional sum of squares) estimation was used throughout rather than full maximum likelihood, for computational speed during the model search.

## Future Improvements

- [RECOMMENDED IMPROVEMENT] Cross-validate forecast accuracy against the actual 2018–2019 data (not available in the original dataset window) to assess real-world forecast performance.
- [RECOMMENDED IMPROVEMENT] Compare the SARIMA results against a simpler benchmark (e.g., seasonal naive) to quantify how much the modeling adds over a naive forecast.
- [RECOMMENDED IMPROVEMENT] Re-run the final model fit with full MLE instead of CSS for more precise coefficient estimates.

## License

MIT — see [LICENSE](LICENSE). This covers the code, analysis, and written report in this repo; it does not extend to the third-party dataset (see `data/README.md` for its source and license).
