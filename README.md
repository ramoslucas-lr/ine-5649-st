# INE5649 — Trabalho de Séries Temporais (CS2 / SteamDB)

Repositório estruturado para o trabalho da disciplina **INE5649 — Técnicas Estatísticas de Predição** (UFSC), analisando as séries temporais (diária e horária) de jogadores simultâneos de Counter-Strike 2 / CS:GO (Steam AppID `730`, fonte SteamDB).

## Estrutura do Repositório

- `data/raw/daily/`: Fonte bruta para a série diária (`steamdb_chart_730.csv`).
- `data/raw/hourly/`: Fonte bruta para a série horária (`cs2-1m.csv`).
- `data/processed/cs2_daily.csv`: Dataset diário consolidado (**1 linha por dia**, colunas `date,players_peak`).
- `data/processed/cs2_hourly.csv`: Dataset horário consolidado (**1 linha por hora** do último mês, colunas `datetime,players`).
- `scripts/build_datasets.py`: Script Python reprodutível que gera ambos os datasets processados.
- `R/01_exploracao_inicial.R`: Script R inicial para leitura e inspeção das duas séries.
- `report/`: Espaço reservado para o resumo expandido final em PDF (máx. 12 páginas + anexo com sintaxe R).

## Nota sobre os Arquivos Originais e Dados Anteriores a 2022

Todos os 14 arquivos CSV presentes em `~/Downloads` (`cs2-1m.csv` e `steamdb_chart_730.csv` até `(12).csv`) eram **cópias idênticas byte a byte** (MD5 `e411b7b0d55a750b1e0b51e926bbcebf`, 7.014 registros), pois o SteamDB sempre exporta o histórico completo do AppID `730`:
- O AppID `730` reúne o histórico contínuo de **CS:GO** (beta em `2011-11-30`, lançamento em `2012-08-21`) e **CS2** (atualização in-place do mesmo AppID em `2023-09-27`). Por isso há registros desde `2011-11-30` (com `Players` contínuo sem falhas a partir de `2015-04-19`).
- A coluna `Average Players` no SteamDB só começa em `2022-09-23` (não incluída nos datasets finais, pois usamos apenas `players_peak` no diário e `players` no horário).
- De `2026-10-16` a `2026-11-15` (31 dias), o SteamDB exporta em granularidade horária (até `2026-11-08`) e de 10 em 10 minutos (até `2026-11-15 16:30:00`).

## Datasets Gerados

### 1. Diário — [`data/processed/cs2_daily.csv`](data/processed/cs2_daily.csv)
- **5.465 linhas** (1 por dia, de `2011-11-30` a `2026-11-15`).
- Colunas: `date`, `players_peak` (pico diário = `max(Players)` do dia).

### 2. Horário — [`data/processed/cs2_hourly.csv`](data/processed/cs2_hourly.csv)
- **737 linhas** (1 por hora cheia `HH:00:00`, de `2026-10-16 00:00:00` a `2026-11-15 16:00:00` UTC, sem horas faltantes).
- Colunas: `datetime`, `players` (jogadores simultâneos no instante `HH:00:00`).

## Execução

```bash
python3 scripts/build_datasets.py
Rscript R/01_exploracao_inicial.R
```

## Requisitos da Entrega (Resumo das Instruções)

- Formato: **Resumo expandido em PDF** (fonte Arial 11, espaçamento 1,5, margens 2,0 cm, máx. 12 páginas + anexo com sintaxe R).
- Seções obrigatórias: Título, Identificação dos membros do grupo, Introdução e objetivos, Materiais e métodos, Resultados e discussões, Considerações finais, Referências bibliográficas e Anexo com sintaxe do R.
- Modelos da disciplina: Regressão para Séries Temporais, Suavização Exponencial (`SES`, `Holt`, `Holt-Winters` / `ETS`) e Modelos Autorregressivos / `ARIMA` (estacionariedade, ACF/PACF, diferenciação e teste ADF).
