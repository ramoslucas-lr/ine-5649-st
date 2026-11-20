# ==============================================================================
# INE5649 - ANÁLISE DE SÉRIES TEMPORAIS: SUAVIZAÇÃO EXPONENCIAL (BASE DIÁRIA CS2)
# ==============================================================================

library(tidyverse)
library(forecast)
library(lubridate)

# 1. Importação e divisão em Treino e Teste (Holdout de 30 dias)
base <- read_csv("../data/processed/cs2_daily.csv") %>%
  mutate(date = as_date(date)) %>%
  arrange(date)

h_teste <- 30
indice_teste <- tail(1:nrow(base), h_teste)

treino <- base[-indice_teste, ]
teste  <- base[indice_teste, ] %>% select(date, players_peak)

# Objeto ts com sazonalidade semanal (frequency = 7 para dados diários)
base_ts <- ts(treino$players_peak, frequency = 7)

# 2. Visualização da série de treino com todos os Majors da era CS2
df_eventos <- tribble(
  ~evento, ~inicio,
  "Lançamento CS2",    ymd("2023-09-27"),
  "Major Copenhagen",  ymd("2024-03-17"),
  "Major Shanghai",    ymd("2024-11-30"),
  "Major Austin",      ymd("2025-06-02"),
  "Major Budapest",    ymd("2025-11-24"),
  "Major Cologne",     ymd("2026-06-02")
) %>%
  filter(inicio >= min(treino$date) & inicio <= max(treino$date))

teto_y <- max(treino$players_peak, na.rm = TRUE)

ggplot(treino, aes(x = date, y = players_peak)) +
  geom_line(color = "gray30") +
  geom_vline(
    data = df_eventos,
    aes(xintercept = inicio),
    linetype = "dashed",
    color = "#d62728"
  ) +
  geom_text(
    data = df_eventos,
    aes(
      x = inicio,
      y = teto_y * 1.13,
      label = evento
    ),
    angle = 90,
    vjust = -0.4,
    hjust = 1,
    size = 3,
    color = "#d62728",
    inherit.aes = FALSE
  ) +
  scale_y_continuous(
    limits = c(
      min(treino$players_peak, na.rm = TRUE) * 0.95,
      teto_y * 1.15
    ),
    labels = scales::label_number(big.mark = ".", decimal.mark = ",")
  ) +
  theme_minimal() +
  labs(
    x = NULL,
    y = "Pico de Jogadores Simultâneos",
    title = "Pico Diário de Jogadores no CS2 (Base de Treino)"
  )

# 3. Ajuste dos Modelos de Suavização Exponencial
SES <- ses(base_ts, h = h_teste)
summary(SES)

HOLT <- holt(base_ts, h = h_teste)
summary(HOLT)

HW_ad <- hw(base_ts, seasonal = "additive", h = h_teste)
summary(HW_ad)

HW_mult <- hw(base_ts, seasonal = "multiplicative", h = h_teste)
summary(HW_mult)

modelo_ets <- ets(base_ts)
summary(modelo_ets)

# 4. Grid Comparativo: Ajuste na Base de Treino (Últimos 180 dias)
df_ajustes <- treino %>%
  mutate(
    SES                 = as.numeric(fitted(SES)),
    Holt                = as.numeric(fitted(HOLT)),
    `HW Aditivo`        = as.numeric(fitted(HW_ad)),
    `HW Multiplicativo` = as.numeric(fitted(HW_mult)),
    `ETS (M,N,M)`       = as.numeric(fitted(modelo_ets))
  ) %>%
  tail(180) %>%
  pivot_longer(
    cols = c(SES, Holt, `HW Aditivo`, `HW Multiplicativo`, `ETS (M,N,M)`),
    names_to = "Modelo",
    values_to = "Ajustado"
  ) %>%
  mutate(Modelo = factor(Modelo, levels = c(
    "SES", "Holt", "HW Aditivo", "HW Multiplicativo", "ETS (M,N,M)"
  )))

ggplot(df_ajustes, aes(x = date)) +
  geom_line(aes(y = players_peak, color = "Real"), linewidth = 0.5, alpha = 0.75) +
  geom_line(aes(y = Ajustado, color = "Ajustado"), linewidth = 0.6) +
  facet_wrap(~ Modelo, ncol = 2) +
  scale_color_manual(name = NULL, values = c("Real" = "gray40", "Ajustado" = "#d62728")) +
  scale_y_continuous(labels = scales::label_number(big.mark = ".", decimal.mark = ",")) +
  theme_bw() +
  labs(
    title = "Ajuste na Base de Treino (Últimos 180 dias) – Suavização Exponencial",
    x = "Data",
    y = "Pico de Jogadores"
  ) +
  theme(
    legend.position = "bottom",
    plot.margin = margin(t = 5, r = 15, b = 5, l = 5)
  )

# 5. Previsões Fora da Amostra e Acurácia (EAM)
SES.predito    <- forecast(SES, h = h_teste)
HOLT.predito   <- forecast(HOLT, h = h_teste)
HWad.predito   <- forecast(HW_ad, h = h_teste)
HWmult.predito <- forecast(HW_mult, h = h_teste)
ETS.predito    <- forecast(modelo_ets, h = h_teste)

eam <- function(yreal, yprev) {
  mean(abs(yreal - yprev))
}

eam_ses     <- eam(teste$players_peak, as.numeric(SES.predito$mean))
eam_holt    <- eam(teste$players_peak, as.numeric(HOLT.predito$mean))
eam_hw_ad   <- eam(teste$players_peak, as.numeric(HWad.predito$mean))
eam_hw_mult <- eam(teste$players_peak, as.numeric(HWmult.predito$mean))
eam_ets     <- eam(teste$players_peak, as.numeric(ETS.predito$mean))

tabela_eam <- tibble(
  Modelo = c("SES", "Holt", "HW Aditivo", "HW Multiplicativo", "ETS"),
  EAM    = c(eam_ses, eam_holt, eam_hw_ad, eam_hw_mult, eam_ets)
) %>%
  arrange(EAM)

tabela_eam

# 6. Grid Comparativo: Previsão Fora da Amostra (30 dias) com IC 95%
fmt_eam <- function(x) {
  scales::number(x, accuracy = 1, big.mark = ".", decimal.mark = ",")
}

extrair_prev <- function(fc, nome, valor_eam) {
  tibble(
    date     = teste$date,
    Real     = teste$players_peak,
    Previsto = as.numeric(fc$mean),
    Lo95     = as.numeric(fc$lower[, 2]),
    Hi95     = as.numeric(fc$upper[, 2]),
    Modelo   = paste0(nome, " (EAM: ", fmt_eam(valor_eam), ")")
  )
}

df_prev_grid <- bind_rows(
  extrair_prev(SES.predito,    "SES",               eam_ses),
  extrair_prev(HOLT.predito,   "Holt",              eam_holt),
  extrair_prev(HWad.predito,   "HW Aditivo",        eam_hw_ad),
  extrair_prev(HWmult.predito, "HW Multiplicativo", eam_hw_mult),
  extrair_prev(ETS.predito,    "ETS Automático",    eam_ets)
) %>%
  mutate(Modelo = factor(Modelo, levels = unique(Modelo)))

ggplot(df_prev_grid, aes(x = date)) +
  geom_ribbon(aes(ymin = Lo95, ymax = Hi95), fill = "#1f77b4", alpha = 0.15) +
  geom_line(aes(y = Real, color = "Real"), linewidth = 0.7) +
  geom_line(aes(y = Previsto, color = "Previsto"), linewidth = 0.8, linetype = "dashed") +
  facet_wrap(~ Modelo, ncol = 2) +
  scale_color_manual(name = NULL, values = c("Real" = "black", "Previsto" = "#1f77b4")) +
  scale_y_continuous(labels = scales::label_number(big.mark = ".", decimal.mark = ",")) +
  theme_bw() +
  labs(
    title = "Previsão Fora da Amostra (30 dias) vs. Valores Reais – IC 95%",
    x = "Data",
    y = "Pico de Jogadores"
  ) +
  theme(
    legend.position = "bottom",
    plot.margin = margin(t = 5, r = 15, b = 5, l = 5)
  )

# 7. Diagnóstico de Resíduos do Melhor Modelo (Holt-Winters Multiplicativo)
checkresiduals(HW_mult)