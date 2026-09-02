# Packages
library(forecast)
library(tseries)

# Import Data
tourism <- read.csv("C:/Users/USER/Downloads/tourism_Project.csv", header=TRUE)
class(tourism)

# Convert to Time Series data and separate into 2 series
y1 <- ts(tourism$Trips[tourism$Purpose == "Business"], start = c(1998, 1), frequency = 4)
y2 <- ts(tourism$Trips[tourism$Purpose == "Holiday"], start = c(1998, 1), frequency = 4)
summary(y1)
summary(y2)

## 1. Time Plot
plot(y1, 
	main = "Business Trips to Melbourne, Victoria (1998 Q1 – 2017 Q4)",
	xlab = "Year", ylab = "Estimated trips")

plot(y2, 
     main = "Holiday Trips to Melbourne, Victoria (1998 Q1 – 2017 Q4)",
     xlab = "Year", ylab = "Estimated trips")

# Aggregate
layout(1:2)
plot(aggregate(y1))
plot(aggregate(y2))

# Boxplot
boxplot(y1 ~ cycle(y1),
		names = c("Q1","Q2","Q3","Q4"),
		main = "Seasonal boxplot of Business Trips",
		xlab = "Quarter", ylab = "Number of Trips")

boxplot(y2 ~ cycle(y2),
        names = c("Q1","Q2","Q3","Q4"),
        main = "Seasonal Boxplot of Holiday Trips",
        xlab = "Quarter",ylab = "Number of Trips")

		
## 2. Time Series Decomposition
decom1.add <- decompose(y1)
decom1.mul <- decompose (y1, type="mult")
plot(decom1.add)
plot(decom1.mul)

decom2.add <- decompose(y2)
decom2.mul <- decompose(y2, type = "mult")
plot(decom2.add)
plot(decom2.mul)


## 3. Correlation Structure 

acf(y1, main = "Business Series")
pacf(y1, main = "Business Series")

acf(y2, main = "Holiday Series")
pacf(y2, main = "Holiday Series")

## 4. Fit and Compare Models
layout(1:2)
acf(diff(y1), main="First Difference")
pacf(diff(y1), main="First Difference")

acf(diff(diff(y1), lag=4),
    main="First and Seasonal Difference")
pacf(diff(diff(y1), lag=4),
     main="First and Seasonal Difference")

acf(diff(y2), main="First Difference")
pacf(diff(y2), main="First Difference")

acf(diff(diff(y2), lag=4),
    main="First and Seasonal Difference")
pacf(diff(diff(y2), lag=4),
     main="First and Seasonal Difference")





get.best.sarima <- function(x.ts, maxord = c(1,1,1,1,1,1))
{best.aic <- Inf
  n <- length(x.ts)
  for(p in 0:maxord[1])for(d in 0:maxord[2]) for(q in 0:maxord[3])
  for(P in 0:maxord[4])for(D in 0:maxord[5]) for(Q in 0:maxord[6])
  {fit <- arima(x.ts,order=c(p, d, q),
                 seasonal=list(order = c(P, D, Q),frequency(x.ts)),
                 method = "CSS")
    fit.aic <- -2 * fit$loglik + (log(n) + 1) * length(fit$coef)
    if (fit.aic < best.aic)
    {best.aic   <- fit.aic
      best.fit   <- fit
      best.order <- c(p, d, q, P, D, Q)}}
  list(best.aic, best.fit, best.order)}

y1.best <- get.best.sarima(y1, maxord = c(2,2,2,2,2,2))
y1.best
confint(y1.best[[2]])

y1.best2 <- get.best.sarima(y1, maxord = c(2,1,2,2,1,2))
y1.best2
confint(y1.best2[[2]])

y1.sarima <- arima(y1, order = c(1,1,2),
                    seasonal = list(order = c(2,1,0), 4),
                    method = "CSS")
y1.sarima
confint(y1.sarima)

y1.resid <- residuals(y1.sarima)
acf(y1.resid,
    main = "Residuals")



y2.best <- get.best.sarima(y2, maxord = c(2,1,1,1,1,1))
y2.best
confint(y2.best[[2]])


y2.best2 <- get.best.sarima(y2, maxord = c(1,1,2,2,1,2))
y2.best2
confint(y2.best2[[2]])

y2.sarima <- arima(y2, order = c(1,1,2),
                   seasonal = list(order = c(2,1,0), 4),
                   method = "CSS")
y2.sarima
confint(y2.sarima)

y2.resid <- residuals(y2.sarima)
acf(y2.resid,
    main = "Residuals")



## 5. Forecasting
y1.predict <- predict(y1.sarima, n.ahead = 8)
y1.predict

ts.plot(y1, y1.predict$pred, xlab="Year", lty=c(1,2),
        ylab="Estimated Trips", 
        main="Business Trips to Melbourne: Forecast")

y2.predict <- predict(y2.sarima, n.ahead = 8)
y2.predict

ts.plot(y2, y2.predict$pred,lty=c(1,3),
        xlab = "Year",
        ylab = "Estimated Trips",
        main = "Holiday Trips to Melbourne: Forecast")
        






## 6.Volatility

acf(resid(y1.sarima)^2, main="Squared Residuals")

acf(resid(y2.sarima)^2,
    main = "Squared Residuals")





