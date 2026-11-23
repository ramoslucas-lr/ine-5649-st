# ==============================================================================
# INE5649 - ANÁLISE DE SÉRIES TEMPORAIS: MODELOS AUTORREGRESSIVOS (BASE CS2)
# ==============================================================================


library(tidyverse)
library(tsibble)
library(fable)
library(feasts)
library(lubridate)

# 1. Mesma base e divisão de Treino / Teste do grupo
cs2_daily <- read_csv("cs2_daily.csv") %>%
  mutate(
    date = as_date(date),
    mes  = factor(month(date), levels = 1:12)
  ) %>%
  as_tsibble(index = date)

treino <- cs2_daily %>% filter(date <= as_date("2026-10-16"))
teste  <- cs2_daily %>% filter(date >  as_date("2026-10-16"))

# 2. Teste de estacionariedade (KPSS / ADF) e gráficos ACF / PACF
treino %>%
  features(players_peak, unitroot_kpss)

treino %>%
  features(players_peak, unitroot_ndiffs)

treino %>%
  gg_tsdisplay(players_peak, plot_type = "partial") +
  labs(title = "Série de Treino, FAC e FACP - Pico Diário CS2")

# 3. Ajuste de modelos autorregressivos puros AR(p) -> ARIMA(p, 0, 0)
modelos_ar <- treino %>%
  model(
    AR1 = ARIMA(players_peak ~ pdq(1, 0, 0) + PDQ(0, 0, 0)),
    AR2 = ARIMA(players_peak ~ pdq(2, 0, 0) + PDQ(0, 0, 0)),
    AR3 = ARIMA(players_peak ~ pdq(3, 0, 0) + PDQ(0, 0, 0)),
    AR7 = ARIMA(players_peak ~ pdq(7, 0, 0) + PDQ(0, 0, 0))
  )

# Critérios de ajuste no treino (AIC, AICc, BIC)
glance(modelos_ar) %>%
  select(.model, sigma2, AIC, AICc, BIC) %>%
  arrange(AIC)

# 4. Previsão fora da amostra (30 dias) e métricas de erro
prev_ar <- modelos_ar %>%
  forecast(new_data = teste)

accuracy(prev_ar, teste) %>%
  select(.model, RMSE, MAE, MAPE) %>%
  arrange(RMSE)

# 5. Diagnóstico de resíduos do modelo AR escolhido
residuos_ar <- augment(modelos_ar) %>%
  filter(.model == "AR3")

# Gráficos dos resíduos ao longo do tempo e distribuição
ggplot(residuos_ar, aes(x = date, y = .innov)) +
  geom_line(color = "gray35") +
  theme_minimal() +
  labs(
    title = "Resíduos ao Longo do Tempo - Modelo AR(3)",
    x = "Data",
    y = "Resíduo (.innov)"
  )

ggplot(residuos_ar, aes(x = .innov)) +
  geom_histogram(bins = 30, fill = "#1f77b4", color = "white", alpha = 0.8) +
  theme_minimal() +
  labs(
    title = "Distribuição dos Resíduos - Modelo AR(3)",
    x = "Resíduo (.innov)",
    y = "Frequência"
  )

# FAC e teste formal de Ljung-Box usando resíduos não-NA
res_limpos <- residuos_ar %>%
  as_tibble() %>%
  filter(!is.na(.innov))

stats::acf(res_limpos$.innov, main = "FAC dos Resíduos - Modelo AR(3)")
stats::Box.test(res_limpos$.innov, lag = 14, type = "Ljung-Box")
