# ==============================================================================
# INE5649 - ANÁLISE DE SÉRIES TEMPORAIS: REGRESSÃO (BASE DIÁRIA CS2)
# ==============================================================================

# 1. Carregamento de pacotes
library(tidyverse)
library(tsibble)
library(fable)
library(feasts)
library(lubridate)

# 2. Importação e preparação dos dados
cs2_daily <- read_csv("../data/processed/cs2_daily.csv") %>%
  mutate(
    date = as_date(date),
    mes  = factor(month(date), levels = 1:12) # Garante todos os 12 níveis em qualquer recorte
  ) %>%
  as_tsibble(index = date)

# 3. Divisão em Treino e Teste
treino <- cs2_daily %>% filter(date <= as_date("2026-10-16")) # 1.116 obs
teste  <- cs2_daily %>% filter(date >  as_date("2026-10-16")) # 30 obs

# 4. Ajuste dos Modelos de Regressão (TSLM) na base de treino
modelos_reg <- treino %>%
  model(
    M1_Tend_Linear       = TSLM(players_peak ~ trend()),
    M2_Tend_Semanal      = TSLM(players_peak ~ trend() + season(period = "week")),
    M3_Tend_Saz_Completa = TSLM(players_peak ~ trend() + season(period = "week") + mes),
    M4_Tend_Quad_Saz     = TSLM(players_peak ~ trend() + I(trend()^2) + season(period = "week") + mes),
    M5_Piecewise_Saz     = TSLM(players_peak ~ trend(knots = as_date("2025-04-12")) + season(period = "week") + mes)
  )

# 5. Métricas de Ajuste e Critérios de Informação (Treino)
glance(modelos_reg) %>%
  select(.model, r_squared, adj_r_squared, sigma2, AIC, AICc, BIC) %>%
  arrange(AIC)

# Detalhamento dos coeficientes do melhor modelo (M4 - Tendência Quadrática + Sazonalidades)
modelos_reg %>%
  select(M4_Tend_Quad_Saz) %>%
  report()

# 6. Previsão e Acurácia Fora da Amostra (Teste - 30 dias)
previsoes <- modelos_reg %>%
  forecast(new_data = teste)

accuracy(previsoes, teste) %>%
  select(.model, RMSE, MAE, MAPE) %>%
  arrange(RMSE)

# 7. Diagnóstico de Resíduos do Modelo Selecionado (M4)
modelos_reg %>%
  select(M4_Tend_Quad_Saz) %>%
  gg_tsresiduals() +
  labs(title = "Diagnóstico de Resíduos - Modelo M4 (Regressão Quadrática + Sazonalidades)")

# Teste formal de autocorrelação residual (Ljung-Box)
augment(modelos_reg) %>%
  filter(.model == "M4_Tend_Quad_Saz") %>%
  features(.innov, ljung_box, lag = 14, dof = 20)

# 8. Visualização: Série Real vs. Ajustada e Previsão
autoplot(cs2_daily, players_peak, color = "gray60") +
  autolayer(augment(modelos_reg) %>% filter(.model == "M4_Tend_Quad_Saz"), .fitted, color = "#1f77b4", size = 0.8) +
  autolayer(previsoes %>% filter(.model == "M4_Tend_Quad_Saz"), level = 95, color = "#d62728") +
  labs(
    title = "Pico Diário de Jogadores Simultâneos (CS2) - Regressão TSLM",
    subtitle = "Ajuste Quadrático com Sazonalidade Semanal e Mensal (2023–2026)",
    x = "Data",
    y = "Pico de Jogadores"
  ) +
  theme_minimal()

