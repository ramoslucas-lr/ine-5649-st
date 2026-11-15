# INE5649 — Trabalho de Séries Temporais (CS2 / SteamDB)

Repositório do trabalho da disciplina **INE5649 — Técnicas Estatísticas de Predição** (UFSC), analisando as séries temporais (diária e horária) de jogadores simultâneos de Counter-Strike 2 / CS:GO (Steam AppID `730`, fonte SteamDB).

## Estrutura do Repositório

- [`data/processed/cs2_daily.csv`](data/processed/cs2_daily.csv): Série diária (**1 linha por dia**).
- [`data/processed/cs2_hourly.csv`](data/processed/cs2_hourly.csv): Série horária (**1 linha por hora** do último mês).
- [`R/trabalho.R`](R/trabalho.R): Script em R com as análises e modelos de séries temporais do trabalho.

## Descrição dos Datasets

### 1. Diário — [`data/processed/cs2_daily.csv`](data/processed/cs2_daily.csv)
- **5.465 linhas** (1 por dia, de `2011-11-30` a `2026-11-15`), cobrindo o histórico contínuo do AppID `730` (CS:GO até `2023-09-26` e CS2 a partir de `2023-09-27`).
- Colunas:
  - `date`: data (`YYYY-MM-DD`).
  - `players_peak`: pico diário de jogadores simultâneos (5.302 dias preenchidos; contínuo sem lacunas a partir de `2015-04-19`).

### 2. Horário — [`data/processed/cs2_hourly.csv`](data/processed/cs2_hourly.csv)
- **737 linhas** contínuas (1 por hora cheia `HH:00:00`, de `2026-10-16 00:00:00` a `2026-11-15 16:00:00` UTC).
- Colunas:
  - `datetime`: data e hora (`YYYY-MM-DD HH:00:00`, UTC).
  - `players`: jogadores simultâneos no instante `HH:00:00`.

## Execução

```bash
Rscript R/trabalho.R
```
