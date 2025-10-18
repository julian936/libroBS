# Script para generar visualizaciones de Series de Tiempo
# Fecha: 2025-10-18

library(tidyverse)
library(readxl)
library(lubridate)
library(scales)
library(gridExtra)

# Configurar directorio de salida
dir_output <- "graficas_output"
if (!dir.exists(dir_output)) {
  dir.create(dir_output, recursive = TRUE)
}

# Cargar datos
datos_completos <- read_xlsx("datos_yahoo/datasets/datos_completos.xlsx")
datos_completos$Fecha <- as.Date(datos_completos$Fecha)

# Definir colores
colores_tickers <- c(
  AAPL = "#007AFF",
  MSFT = "#34C759",
  TSLA = "#FF3B30",
  PFE = "#AF52DE",
  MRNA = "#FF9500",
  JNJ = "#E91E63"
)

color_covid <- "#E74C3C"
color_vacuna <- "#27AE60"

# Definir fechas importantes
fecha_covid_inicio <- as.Date("2020-01-01")
fecha_covid_fin <- as.Date("2022-01-01")
fecha_vacuna_inicio <- as.Date("2020-12-01")

# ============================================================================
# 1. SECTOR TECNOLOGICO
# ============================================================================

cat("Generando grafica del sector tecnologico...\n")

# CAMBIO AQUI: Usar grepl en lugar de == para evitar problemas de encoding
datos_tech <- datos_completos %>%
  filter(grepl("Tecnolog", Sector))

p_tech <- ggplot(datos_tech, aes(x = Fecha, y = Close, color = Ticker))

p_tech <- p_tech +
  geom_rect(
    xmin = fecha_covid_inicio,
    xmax = fecha_covid_fin,
    ymin = -Inf,
    ymax = Inf,
    fill = color_covid,
    alpha = 0.05,
    inherit.aes = FALSE
  )

p_tech <- p_tech + geom_line(linewidth = 0.7)

p_tech <- p_tech + facet_wrap(
  ~Ticker,
  ncol = 1,
  scales = "free_y",
  labeller = labeller(Ticker = c(
    AAPL = "Apple (AAPL) - Tecnologia",
    MSFT = "Microsoft (MSFT) - Tecnologia",
    TSLA = "Tesla (TSLA) - Tecnologia"
  ))
)

p_tech <- p_tech + scale_color_manual(values = colores_tickers)

p_tech <- p_tech + labs(
  title = "Series de Tiempo del Sector Tecnologico (2015-2025)",
  subtitle = "Area sombreada indica periodo COVID-19 (2020-2022)",
  x = NULL,
  y = "Precio de Cierre ($)"
)

p_tech <- p_tech + theme_minimal(base_size = 12)

p_tech <- p_tech + theme(
  legend.position = "none",
  strip.text = element_text(face = "bold", hjust = 0),
  panel.spacing = unit(1, "lines")
)

p_tech <- p_tech + scale_y_continuous(labels = dollar_format())

ggsave(
  filename = file.path(dir_output, "01_sector_tecnologico.png"),
  plot = p_tech,
  width = 12,
  height = 10,
  dpi = 300,
  bg = "white"
)

cat("OK Grafica 1 guardada\n\n")

# ============================================================================
# 2. SECTOR FARMACEUTICO
# ============================================================================

cat("Generando grafica del sector farmaceutico...\n")

# CAMBIO AQUI: Usar grepl en lugar de == para evitar problemas de encoding
datos_pharma <- datos_completos %>%
  filter(grepl("Farmac", Sector))

p_pharma <- ggplot(datos_pharma, aes(x = Fecha, y = Close, color = Ticker))

p_pharma <- p_pharma +
  geom_rect(
    xmin = fecha_covid_inicio,
    xmax = fecha_covid_fin,
    ymin = -Inf,
    ymax = Inf,
    fill = color_covid,
    alpha = 0.05,
    inherit.aes = FALSE
  )

p_pharma <- p_pharma +
  geom_rect(
    xmin = fecha_vacuna_inicio,
    xmax = fecha_covid_fin,
    ymin = -Inf,
    ymax = Inf,
    fill = color_vacuna,
    alpha = 0.05,
    inherit.aes = FALSE
  )

p_pharma <- p_pharma + geom_line(linewidth = 0.7)

p_pharma <- p_pharma + facet_wrap(
  ~Ticker,
  ncol = 1,
  scales = "free_y",
  labeller = labeller(Ticker = c(
    PFE = "Pfizer (PFE) - Farmaceutica",
    MRNA = "Moderna (MRNA) - Farmaceutica",
    JNJ = "Johnson & Johnson (JNJ) - Farmaceutica"
  ))
)

p_pharma <- p_pharma + scale_color_manual(values = colores_tickers)

p_pharma <- p_pharma + labs(
  title = "Series de Tiempo del Sector Farmaceutico (2015-2025)",
  subtitle = "Area roja: COVID-19 (2020-2022) | Area verde: Periodo de vacunas (dic 2020 - ene 2022)",
  x = NULL,
  y = "Precio de Cierre ($)"
)

p_pharma <- p_pharma + theme_minimal(base_size = 12)

p_pharma <- p_pharma + theme(
  legend.position = "none",
  strip.text = element_text(face = "bold", hjust = 0),
  panel.spacing = unit(1, "lines")
)

p_pharma <- p_pharma + scale_y_continuous(labels = dollar_format())

ggsave(
  filename = file.path(dir_output, "02_sector_farmaceutico.png"),
  plot = p_pharma,
  width = 12,
  height = 10,
  dpi = 300,
  bg = "white"
)

cat("OK Grafica 2 guardada\n\n")

# ============================================================================
# 3. PROMEDIOS MOVILES - TECNOLOGIA
# ============================================================================

cat("Generando promedios moviles - Tecnologia...\n")

calcular_sma <- function(datos, ventana) {
  datos %>%
    group_by(Ticker) %>%
    arrange(Fecha) %>%
    mutate(SMA = zoo::rollmean(Close, k = ventana, fill = NA, align = "right")) %>%
    ungroup()
}

datos_sma_tech <- datos_tech
for(ventana in c(7, 30, 90)) {
  datos_sma_tech <- calcular_sma(datos_sma_tech, ventana)
  nombres_cols <- names(datos_sma_tech)
  nombres_cols[nombres_cols == "SMA"] <- paste0("SMA_", ventana)
  names(datos_sma_tech) <- nombres_cols
}

for(ticker in c("AAPL", "MSFT", "TSLA")) {
  df <- datos_sma_tech %>% filter(Ticker == ticker)

  color_7 <- "#E74C3C"
  color_30 <- "#F39C12"
  color_90 <- "#27AE60"

  p <- ggplot(df, aes(x = Fecha))
  p <- p + geom_line(aes(y = Close), color = "gray70", alpha = 0.5, linewidth = 0.3)
  p <- p + geom_line(aes(y = SMA_7, color = "7 dias"), linewidth = 0.8)
  p <- p + geom_line(aes(y = SMA_30, color = "30 dias"), linewidth = 0.8)
  p <- p + geom_line(aes(y = SMA_90, color = "90 dias"), linewidth = 0.8)
  p <- p + scale_color_manual(values = c("7 dias" = color_7, "30 dias" = color_30, "90 dias" = color_90))
  p <- p + labs(
    title = paste(ticker, "- Promedios Moviles (7, 30 y 90 dias)"),
    subtitle = "Linea gris: precio diario",
    x = NULL,
    y = "Precio ($)",
    color = "Promedio Movil"
  )
  p <- p + theme_minimal(base_size = 12)
  p <- p + theme(legend.position = "bottom")
  p <- p + scale_y_continuous(labels = dollar_format())

  filename <- paste0("03_sma_tech_", ticker, ".png")
  ggsave(
    filename = file.path(dir_output, filename),
    plot = p,
    width = 12,
    height = 6,
    dpi = 300,
    bg = "white"
  )

  cat(paste0("OK ", filename, "\n"))
}

cat("\n")

# ============================================================================
# 4. PROMEDIOS MOVILES - FARMACEUTICAS
# ============================================================================

cat("Generando promedios moviles - Farmaceuticas...\n")

datos_sma_pharma <- datos_pharma
for(ventana in c(7, 30, 90)) {
  datos_sma_pharma <- calcular_sma(datos_sma_pharma, ventana)
  nombres_cols <- names(datos_sma_pharma)
  nombres_cols[nombres_cols == "SMA"] <- paste0("SMA_", ventana)
  names(datos_sma_pharma) <- nombres_cols
}

for(ticker in c("PFE", "MRNA", "JNJ")) {
  df <- datos_sma_pharma %>% filter(Ticker == ticker)

  color_7 <- "#E74C3C"
  color_30 <- "#F39C12"
  color_90 <- "#27AE60"

  p <- ggplot(df, aes(x = Fecha))
  p <- p + geom_line(aes(y = Close), color = "gray70", alpha = 0.5, linewidth = 0.3)
  p <- p + geom_line(aes(y = SMA_7, color = "7 dias"), linewidth = 0.8)
  p <- p + geom_line(aes(y = SMA_30, color = "30 dias"), linewidth = 0.8)
  p <- p + geom_line(aes(y = SMA_90, color = "90 dias"), linewidth = 0.8)
  p <- p + scale_color_manual(values = c("7 dias" = color_7, "30 dias" = color_30, "90 dias" = color_90))
  p <- p + labs(
    title = paste(ticker, "- Promedios Moviles (7, 30 y 90 dias)"),
    subtitle = "Linea gris: precio diario",
    x = NULL,
    y = "Precio ($)",
    color = "Promedio Movil"
  )
  p <- p + theme_minimal(base_size = 12)
  p <- p + theme(legend.position = "bottom")
  p <- p + scale_y_continuous(labels = dollar_format())

  filename <- paste0("04_sma_pharma_", ticker, ".png")
  ggsave(
    filename = file.path(dir_output, filename),
    plot = p,
    width = 12,
    height = 6,
    dpi = 300,
    bg = "white"
  )

  cat(paste0("OK ", filename, "\n"))
}

cat("\n")

# ============================================================================
# 5. ANALISIS DE REZAGOS
# ============================================================================

cat("Generando analisis de rezagos...\n")

crear_lag_plot <- function(datos, lag_days, ticker_sel) {
  df <- datos %>%
    filter(Ticker == ticker_sel) %>%
    arrange(Fecha) %>%
    mutate(Close_Lag = lag(Close, lag_days))

  p <- ggplot(df, aes(x = Close_Lag, y = Close))
  p <- p + geom_point(color = colores_tickers[ticker_sel], alpha = 0.5, size = 1.5)
  p <- p + geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "red")
  p <- p + labs(
    title = paste(ticker_sel, "- Rezago", lag_days, "dia(s)"),
    x = paste("Precio (t -", lag_days, ")"),
    y = "Precio (t)"
  )
  p <- p + theme_minimal(base_size = 12)
  p <- p + scale_x_continuous(labels = dollar_format())
  p <- p + scale_y_continuous(labels = dollar_format())

  return(p)
}

lag_plots <- list()
for(ticker in c("AAPL", "TSLA", "MRNA")) {
  lag_plots[[paste0(ticker, "_lag1")]] <- crear_lag_plot(datos_completos, 1, ticker)
  lag_plots[[paste0(ticker, "_lag7")]] <- crear_lag_plot(datos_completos, 7, ticker)
}

p_lag <- do.call(grid.arrange, c(lag_plots, ncol = 2))

ggsave(
  filename = file.path(dir_output, "05_analisis_rezagos.png"),
  plot = p_lag,
  width = 14,
  height = 10,
  dpi = 300,
  bg = "white"
)

cat("OK Grafica 5 guardada\n\n")

# ============================================================================
# 6. ESTACIONALIDAD ANUAL
# ============================================================================

cat("Generando estacionalidad anual...\n")

datos_mensuales <- datos_completos %>%
  mutate(Anio = year(Fecha), Mes = month(Fecha, label = TRUE)) %>%
  group_by(Ticker, Sector, Anio, Mes) %>%
  summarise(Precio_Promedio = mean(Close, na.rm = TRUE), .groups = "drop") %>%
  filter(Anio >= 2019 & Anio <= 2021)

color_2019 <- "#3498DB"
color_2020 <- "#E74C3C"
color_2021 <- "#27AE60"

p_estacional <- ggplot(datos_mensuales, aes(x = Mes, y = Precio_Promedio, color = as.factor(Anio), group = interaction(Ticker, Anio)))
p_estacional <- p_estacional + geom_line(linewidth = 1)
p_estacional <- p_estacional + geom_point(size = 2)
p_estacional <- p_estacional + facet_wrap(~Sector, scales = "free_y", ncol = 1)
p_estacional <- p_estacional + scale_color_manual(values = c("2019" = color_2019, "2020" = color_2020, "2021" = color_2021))
p_estacional <- p_estacional + labs(
  title = "Patron Estacional por Sector (2019-2021)",
  subtitle = "Analisis del comportamiento mensual durante COVID-19",
  x = "Mes",
  y = "Precio Promedio ($)",
  color = "Anio"
)
p_estacional <- p_estacional + theme_minimal(base_size = 12)
p_estacional <- p_estacional + theme(
  legend.position = "bottom",
  axis.text.x = element_text(angle = 45, hjust = 1),
  strip.text = element_text(face = "bold")
)

ggsave(
  filename = file.path(dir_output, "06_estacionalidad_anual.png"),
  plot = p_estacional,
  width = 12,
  height = 10,
  dpi = 300,
  bg = "white"
)

cat("OK Grafica 6 guardada\n\n")

# ============================================================================
# RESUMEN
# ============================================================================

cat("======================================================================\n")
cat("PROCESO COMPLETADO\n")
cat("======================================================================\n\n")
cat("10 graficas guardadas en:", dir_output, "\n\n")
