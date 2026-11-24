library(forecast)
library(ggplot2) 

### LEITURA DA BASE
base = read.csv("../data/processed/cs2_daily.csv") 
jogadores = ts(base$jogadores_peak, frequency = 7, start = c(1, 4))

### AJUSTE DA MEDIA MOVEL
mod.ar <- arima(jogadores, order = c(1, 1, 0)) 
summary(mod.ar) 
checkresiduals(mod.ar) 

mod.ma <- arima(jogadores, order = c(0, 1, 1)) 
summary(mod.ma) 
checkresiduals(mod.ma) 

mod.arima1 <- arima(jogadores, order = c(1, 1, 1)) 
summary(mod.arima1) 
checkresiduals(mod.arima1)

### AJUSTE DO MODELO ARIMA
mod.arima <- auto.arima(jogadores, seasonal = FALSE) 
summary(mod.arima) 
checkresiduals(mod.arima) 
mod.arima %>% forecast(h = 7) %>% autoplot()

### AJUSTE DO MODELO SARIMA
mod.sarima <- auto.arima(jogadores, seasonal = TRUE) 
summary(mod.sarima) 
checkresiduals(mod.sarima) 
mod.sarima %>% forecast(h = 7) %>% autoplot()

### AJUSTE DOS MODELOS SEPARANDO BASE TREINO E BASE TESTE
treino <- window(jogadores, end = c(160, 6)) 
teste  <- window(jogadores, start = c(160, 7))

mod.arima2 <- auto.arima(treino, seasonal = FALSE) 
prev_arima <- forecast(mod.arima2, h = length(teste)) 

mod.sarima2 <- auto.arima(treino, seasonal = TRUE) 
prev_sarima <- forecast(mod.sarima2, h = length(teste))

### DIAGNÓSTICO DE RESÍDUOS
checkresiduals(mod.arima2) 
checkresiduals(mod.sarima2)

### ANÁLISE GRÁFICA DO AJUSTE

autoplot(prev_arima) + 
  autolayer(prev_arima$mean, series = "Previsto", color = "blue") + 
  autolayer(teste, series = "Real", linetype = "dashed", color = "black") + 
  labs(title = "Previsão vs Valores Reais (ARIMA)", x = "Semanas", y = "Peak jogadores") + 
  theme_minimal()

autoplot(prev_sarima) + 
  autolayer(prev_sarima$mean, series = "Previsto", color = "blue") + 
  autolayer(teste, series = "Real", linetype = "dashed", color = "black") + 
  labs(title = "Previsão vs Valores Reais (SARIMA)", x = "Semanas", y = "Peak jogadores") + 
  theme_minimal()

### ACURACIA DA PREVISAO
teste = cbind(teste, prev_arima$mean, prev_sarima$mean) 
colnames(teste) <- c("Real", "Arima", "Sarima") 
teste = as.data.frame(teste)

eam <- function(yreal, yprev) { mean(abs(yreal - yprev)) } 
eam(yreal = teste$Real, yprev = teste$Arima) 
eam(yreal = teste$Real, yprev = teste$Sarima)

rmse <- function(yreal, yprev) { sqrt(mean((yreal - yprev)^2)) } 
rmse(yreal = teste$Real, yprev = teste$Arima) 
rmse(yreal = teste$Real, yprev = teste$Sarima)
