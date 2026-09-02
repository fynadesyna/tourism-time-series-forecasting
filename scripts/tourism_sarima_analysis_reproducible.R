# =============================================================================
# Tourism SARIMA Analysis - Reproducible version
#
# This is a lightly modified version of tourism_sarima_analysis.R (the
# original submitted script) with two changes so it runs on any machine
# and regenerates the figures referenced in report/*.tex:
#   1. The hardcoded local path (C:/Users/USER/Downloads/...) is replaced
#      with a relative path to data/tourism_Project.csv.
#   2. Each plot is wrapped in png(...)/dev.off() so it's written to
#      scripts/figures/ instead of only rendering to an interactive device.
#
# The original, unmodified script is kept as tourism_sarima_analysis.R
# for an accurate record of what was actually run for the assignment.
# =============================================================================

library(forecast)
library(tseries)

# --- Import Data -------------------------------------------------------
tourism <- read.csv("../data/tourism_Project.csv", header = TRUE)
class(tourism)

fig_dir <- "figures"
if (!dir.exists(fig_dir)) dir.create(fig_dir)

# Convert to Time Series data and separate into 2 series
y1 <- ts(tourism$Trips[tourism$Purpose == "Business"], start = c(1998, 1), frequency = 4)
y2 <- ts(tourism$Trips[tourism$Purpose == "Holiday"], start = c(1998, 1), frequency = 4)
summary(y1)
summary(y2)

## 1. Time Plot
png(file.path(fig_dir, "y1timeplot.png"), width = 800, height = 500)
plot(y1,
     main = "Business Trips to Melbourne, Victoria (1998 Q1 - 2017 Q4)",
     xlab = "Year", ylab = "Estimated trips")
dev.off()

png(file.path(fig_dir, "figy2timeplot.png"), width = 800, height = 500)
plot(y2,
     main = "Holiday Trips to Melbourne, Victoria (1998 Q1 - 2017 Q4)",
     xlab = "Year", ylab = "Estimated trips")
dev.off()

# Aggregate
png(file.path(fig_dir, "y1aggregate.png"), width = 800, height = 500)
plot(aggregate(y1))
dev.off()

png(file.path(fig_dir, "y2aggregate.png"), width = 800, height = 500)
plot(aggregate(y2))
dev.off()

# Boxplot
png(file.path(fig_dir, "y1boxplot.png"), width = 700, height = 500)
boxplot(y1 ~ cycle(y1),
        names = c("Q1", "Q2", "Q3", "Q4"),
        main = "Seasonal boxplot of Business Trips",
        xlab = "Quarter", ylab = "Number of Trips")
dev.off()

png(file.path(fig_dir, "y2boxplot.png"), width = 700, height = 500)
boxplot(y2 ~ cycle(y2),
        names = c("Q1", "Q2", "Q3", "Q4"),
        main = "Seasonal Boxplot of Holiday Trips",
        xlab = "Quarter", ylab = "Number of Trips")
dev.off()

## 2. Time Series Decomposition
decom1.add <- decompose(y1)
decom1.mul <- decompose(y1, type = "mult")

png(file.path(fig_dir, "y1add.png"), width = 700, height = 600)
plot(decom1.add)
dev.off()

png(file.path(fig_dir, "y1mul.png"), width = 700, height = 600)
plot(decom1.mul)
dev.off()

decom2.add <- decompose(y2)
decom2.mul <- decompose(y2, type = "mult")

png(file.path(fig_dir, "y2add.png"), width = 700, height = 600)
plot(decom2.add)
dev.off()

png(file.path(fig_dir, "y2mul.png"), width = 700, height = 600)
plot(decom2.mul)
dev.off()

## 3. Correlation Structure
png(file.path(fig_dir, "y1acf.jpg"), width = 700, height = 500)
acf(y1, main = "Business Series")
dev.off()

png(file.path(fig_dir, "y1pacf.jpg"), width = 700, height = 500)
pacf(y1, main = "Business Series")
dev.off()

png(file.path(fig_dir, "y2acf.png"), width = 700, height = 500)
acf(y2, main = "Holiday Series")
dev.off()

png(file.path(fig_dir, "y2pacf.png"), width = 700, height = 500)
pacf(y2, main = "Holiday Series")
dev.off()

## 4. Fit and Compare Models
png(file.path(fig_dir, "y1diff.png"), width = 700, height = 700)
layout(1:2)
acf(diff(y1), main = "First Difference")
pacf(diff(y1), main = "First Difference")
dev.off()

png(file.path(fig_dir, "y1fsdiff.png"), width = 700, height = 700)
layout(1:2)
acf(diff(diff(y1), lag = 4), main = "First and Seasonal Difference")
pacf(diff(diff(y1), lag = 4), main = "First and Seasonal Difference")
dev.off()

png(file.path(fig_dir, "y2diff.png"), width = 700, height = 700)
layout(1:2)
acf(diff(y2), main = "First Difference")
pacf(diff(y2), main = "First Difference")
dev.off()

png(file.path(fig_dir, "y2fsdiff.png"), width = 700, height = 700)
layout(1:2)
acf(diff(diff(y2), lag = 4), main = "First and Seasonal Difference")
pacf(diff(diff(y2), lag = 4), main = "First and Seasonal Difference")
dev.off()

# --- SARIMA model search ------------------------------------------------
get.best.sarima <- function(x.ts, maxord = c(1, 1, 1, 1, 1, 1)) {
  best.aic <- Inf
  n <- length(x.ts)
  for (p in 0:maxord[1]) for (d in 0:maxord[2]) for (q in 0:maxord[3])
    for (P in 0:maxord[4]) for (D in 0:maxord[5]) for (Q in 0:maxord[6]) {
      fit <- arima(x.ts, order = c(p, d, q),
                   seasonal = list(order = c(P, D, Q), frequency(x.ts)),
                   method = "CSS")
      fit.aic <- -2 * fit$loglik + (log(n) + 1) * length(fit$coef)
      if (fit.aic < best.aic) {
        best.aic   <- fit.aic
        best.fit   <- fit
        best.order <- c(p, d, q, P, D, Q)
      }
    }
  list(best.aic, best.fit, best.order)
}

# Business series: unrestricted search (d,D <= 2) -- see report/Q4.tex for
# why this search is not pursued further (confint() cannot compute 95% CIs
# reliably given n = 80 and D = 2)
y1.best <- get.best.sarima(y1, maxord = c(2, 2, 2, 2, 2, 2))
y1.best
confint(y1.best[[2]])

# Business series: restricted search (d,D <= 1) -- this is the search that
# produces the final selected model
y1.best2 <- get.best.sarima(y1, maxord = c(2, 1, 2, 2, 1, 2))
y1.best2
confint(y1.best2[[2]])

# Final selected model: ARIMA(1,1,2)(2,1,0)[4]
y1.sarima <- arima(y1, order = c(1, 1, 2),
                    seasonal = list(order = c(2, 1, 0), 4),
                    method = "CSS")
y1.sarima
confint(y1.sarima)

y1.resid <- residuals(y1.sarima)
png(file.path(fig_dir, "y1qr.png"), width = 700, height = 500)
acf(y1.resid, main = "Residuals")
dev.off()

# Holiday series: unrestricted search
y2.best <- get.best.sarima(y2, maxord = c(2, 1, 1, 1, 1, 1))
y2.best
confint(y2.best[[2]])

y2.best2 <- get.best.sarima(y2, maxord = c(1, 1, 2, 2, 1, 2))
y2.best2
confint(y2.best2[[2]])

# Final selected model: ARIMA(0,1,1)(1,1,1)[4]
y2.sarima <- arima(y2, order = c(1, 1, 2),
                    seasonal = list(order = c(2, 1, 0), 4),
                    method = "CSS")
y2.sarima
confint(y2.sarima)

y2.resid <- residuals(y2.sarima)
png(file.path(fig_dir, "y2qr.png"), width = 700, height = 500)
acf(y2.resid, main = "Residuals")
dev.off()

## 5. Forecasting
y1.predict <- predict(y1.sarima, n.ahead = 8)
y1.predict

png(file.path(fig_dir, "y1frc.png"), width = 800, height = 500)
ts.plot(y1, y1.predict$pred, xlab = "Year", lty = c(1, 2),
        ylab = "Estimated Trips",
        main = "Business Trips to Melbourne: Forecast")
dev.off()

y2.predict <- predict(y2.sarima, n.ahead = 8)
y2.predict

png(file.path(fig_dir, "y2frc.png"), width = 800, height = 500)
ts.plot(y2, y2.predict$pred, lty = c(1, 3),
        xlab = "Year",
        ylab = "Estimated Trips",
        main = "Holiday Trips to Melbourne: Forecast")
dev.off()

## 6. Volatility
png(file.path(fig_dir, "y1sq.png"), width = 700, height = 500)
acf(resid(y1.sarima)^2, main = "Squared Residuals")
dev.off()

png(file.path(fig_dir, "y2sq.png"), width = 700, height = 500)
acf(resid(y2.sarima)^2, main = "Squared Residuals")
dev.off()

cat("\nDone. Figures written to", normalizePath(fig_dir), "\n")
