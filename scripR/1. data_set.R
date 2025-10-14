# ============================================
# DESCARGA DE DATOS YAHOO FINANCE + GRÁFICOS
# Series de tiempo para análisis
# ============================================

library(quantmod)
library(tidyverse)
library(writexl)
library(lubridate)
library(gridExtra)
library(scales)

# ============================================
# CONFIGURACIÓN
# ============================================

# Fecha de análisis
FECHA_ANALISIS <- Sys.Date()

# Carpetas
CARPETA_BASE <- "datos_yahoo"
CARPETA_GRAFICOS <- file.path(CARPETA_BASE, "graficos")
CARPETA_DATOS <- file.path(CARPETA_BASE, "datasets")

# Crear carpetas
dir.create(CARPETA_BASE, showWarnings = FALSE, recursive = TRUE)
dir.create(CARPETA_GRAFICOS, showWarnings = FALSE, recursive = TRUE)
dir.create(CARPETA_DATOS, showWarnings = FALSE, recursive = TRUE)

# Tickers a descargar
TICKERS_TECH <- c("AAPL", "MSFT", "TSLA")
TICKERS_PHARMA <- c("PFE", "MRNA", "JNJ")
TODOS_TICKERS <- c(TICKERS_TECH, TICKERS_PHARMA)

# Período (10 años)
ANOS_HISTORIA <- 10
FECHA_INICIO <- FECHA_ANALISIS - years(ANOS_HISTORIA)

cat("========================================\n")
cat("DESCARGA YAHOO FINANCE\n")
cat("========================================\n\n")
cat("Fecha análisis:", as.character(FECHA_ANALISIS), "\n")
cat("Período:", as.character(FECHA_INICIO), "a", as.character(FECHA_ANALISIS), "\n")
cat("Tickers:", paste(TODOS_TICKERS, collapse = ", "), "\n\n")

# Colores para gráficos
COLORES <- c(
  "AAPL" = "#007AFF", "MSFT" = "#34C759", "TSLA" = "#FF3B30",
  "PFE" = "#AF52DE", "MRNA" = "#FF9500", "JNJ" = "#FF2D55"
)

# ============================================
# FUNCIÓN DE DESCARGA
# ============================================

descargar_ticker <- function(ticker) {
  cat("\n[Descargando]", ticker, "...\n")

  tryCatch({
    # Descargar datos
    getSymbols(ticker,
               src = "yahoo",
               from = FECHA_INICIO,
               to = FECHA_ANALISIS,
               auto.assign = TRUE,
               warnings = FALSE)

    datos <- get(ticker)

    # Convertir a dataframe
    df <- data.frame(
      Fecha = index(datos),
      Ticker = ticker,
      Sector = ifelse(ticker %in% TICKERS_TECH, "Tecnología", "Farmacéutica"),
      Open = as.numeric(Op(datos)),
      High = as.numeric(Hi(datos)),
      Low = as.numeric(Lo(datos)),
      Close = as.numeric(Cl(datos)),
      Volume = as.numeric(Vo(datos)),
      Adjusted = as.numeric(Ad(datos))
    ) %>%
      mutate(
        # Retornos
        Return = (Close - lag(Close)) / lag(Close),
        Log_Return = log(Close / lag(Close)),

        # Variables adicionales
        Range = High - Low,
        Range_Pct = Range / Close * 100,

        # Temporales
        Year = year(Fecha),
        Month = month(Fecha, label = TRUE),
        Quarter = quarter(Fecha),
        Weekday = wday(Fecha, label = TRUE),

        # Períodos COVID
        Periodo = case_when(
          Fecha < as.Date("2020-01-01") ~ "Pre-COVID",
          Fecha >= as.Date("2020-01-01") & Fecha < as.Date("2020-03-01") ~ "Inicio COVID",
          Fecha >= as.Date("2020-03-01") & Fecha < as.Date("2020-12-01") ~ "Pandemia",
          Fecha >= as.Date("2020-12-01") & Fecha < as.Date("2022-01-01") ~ "Vacunas",
          TRUE ~ "Post-COVID"
        )
      )

    cat("  ✓ Descargado:", nrow(df), "observaciones\n")
    cat("  ✓ Rango:", min(df$Fecha), "a", max(df$Fecha), "\n")
    cat("  ✓ Precio inicial: $", round(df$Close[1], 2), "\n")
    cat("  ✓ Precio final: $", round(df$Close[nrow(df)], 2), "\n")

    return(df)

  }, error = function(e) {
    cat("  ✗ ERROR:", conditionMessage(e), "\n")
    return(NULL)
  })
}

# ============================================
# DESCARGAR TODOS LOS DATOS
# ============================================

cat("\n========================================\n")
cat("DESCARGANDO DATOS\n")
cat("========================================\n")

lista_datos <- list()
datos_completos <- data.frame()

for (ticker in TODOS_TICKERS) {
  datos_ticker <- descargar_ticker(ticker)

  if (!is.null(datos_ticker)) {
    lista_datos[[ticker]] <- datos_ticker
    datos_completos <- rbind(datos_completos, datos_ticker)
  }

  Sys.sleep(1)  # Pausa entre descargas
}

cat("\n========================================\n")
cat("DESCARGA COMPLETADA\n")
cat("========================================\n")
cat("Total observaciones:", nrow(datos_completos), "\n")
cat("Tickers descargados:", length(lista_datos), "\n\n")

# ============================================
# GUARDAR DATOS
# ============================================

cat("Guardando datasets...\n")

# Dataset completo
write_xlsx(datos_completos,
           file.path(CARPETA_DATOS, "datos_completos.xlsx"))
cat("  ✓ datos_completos.xlsx\n")

# Datasets individuales
for (ticker in names(lista_datos)) {
  write_xlsx(lista_datos[[ticker]],
             file.path(CARPETA_DATOS, paste0(ticker, "_datos.xlsx")))
  cat("  ✓", ticker, "_datos.xlsx\n")
}

# Resumen estadístico
resumen <- datos_completos %>%
  group_by(Ticker, Sector) %>%
  summarise(
    Observaciones = n(),
    Fecha_Inicio = min(Fecha),
    Fecha_Fin = max(Fecha),
    Precio_Min = min(Close),
    Precio_Max = max(Close),
    Precio_Promedio = mean(Close),
    Volatilidad_Anual = sd(Return, na.rm = TRUE) * sqrt(252) * 100,
    Retorno_Total = ((last(Close) / first(Close)) - 1) * 100,
    .groups = "drop"
  )

write_xlsx(resumen, file.path(CARPETA_DATOS, "resumen_estadistico.xlsx"))
cat("  ✓ resumen_estadistico.xlsx\n\n")

# ============================================
# GRÁFICO 1: SERIES INDIVIDUALES
# ============================================

cat("Generando gráficos...\n\n")
cat("[1] Series individuales completas\n")

for (ticker in names(lista_datos)) {
  df <- lista_datos[[ticker]]

  p <- ggplot(df, aes(x = Fecha, y = Close)) +
    geom_line(color = COLORES[ticker], linewidth = 0.8) +

    # Marcar COVID
    geom_rect(aes(xmin = as.Date("2020-01-01"),
                  xmax = as.Date("2022-01-01"),
                  ymin = -Inf, ymax = Inf),
              fill = "#E74C3C", alpha = 0.1) +

    labs(
      title = paste("Serie de Tiempo:", ticker, "-", unique(df$Sector)),
      subtitle = paste(nrow(df), "observaciones | Área roja = Período COVID-19"),
      x = "Fecha",
      y = "Precio de Cierre ($)",
      caption = "Fuente: Yahoo Finance"
    ) +
    theme_minimal(base_size = 11) +
    theme(plot.title = element_text(face = "bold")) +
    scale_y_continuous(labels = dollar_format()) +
    scale_x_date(date_breaks = "1 year", date_labels = "%Y")

  ggsave(file.path(CARPETA_GRAFICOS, paste0("01_", ticker, "_serie_completa.png")),
         p, width = 12, height = 6, dpi = 150)

  cat("  ✓", ticker, "\n")
}

# ============================================
# GRÁFICO 2: COMPARACIÓN NORMALIZADA
# ============================================

cat("\n[2] Comparación normalizada (todas las series)\n")

datos_norm <- datos_completos %>%
  group_by(Ticker) %>%
  mutate(Precio_Normalizado = Close / first(Close) * 100) %>%
  ungroup()

p2 <- ggplot(datos_norm, aes(x = Fecha, y = Precio_Normalizado, color = Ticker)) +
  geom_line(linewidth = 1) +

  geom_rect(aes(xmin = as.Date("2020-01-01"),
                xmax = as.Date("2022-01-01"),
                ymin = -Inf, ymax = Inf),
            fill = "#E74C3C", alpha = 0.05, inherit.aes = FALSE) +

  geom_hline(yintercept = 100, linetype = "dashed", color = "gray30") +

  scale_color_manual(values = COLORES) +

  labs(
    title = "Comparación: Tecnología vs Farmacéuticas (Precios Normalizados)",
    subtitle = "Base 100 = Precio Inicial | Área roja = COVID-19",
    x = "Fecha",
    y = "Precio Normalizado (Base 100)",
    color = "Ticker",
    caption = "Fuente: Yahoo Finance"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom"
  ) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y")

ggsave(file.path(CARPETA_GRAFICOS, "02_comparacion_normalizada.png"),
       p2, width = 14, height = 8, dpi = 150)

cat("  ✓ Comparación normalizada\n")

# ============================================
# GRÁFICO 3: POR SECTOR
# ============================================

cat("\n[3] Comparación por sector\n")

p3 <- ggplot(datos_norm, aes(x = Fecha, y = Precio_Normalizado, color = Ticker)) +
  geom_line(linewidth = 1) +

  facet_wrap(~Sector, ncol = 1, scales = "free_y") +

  geom_rect(aes(xmin = as.Date("2020-01-01"),
                xmax = as.Date("2022-01-01"),
                ymin = -Inf, ymax = Inf),
            fill = "#E74C3C", alpha = 0.05, inherit.aes = FALSE) +

  geom_hline(yintercept = 100, linetype = "dashed", color = "gray30") +

  scale_color_manual(values = COLORES) +

  labs(
    title = "Comparación por Sector: Tecnología vs Farmacéuticas",
    subtitle = "Base 100 = Precio Inicial",
    x = "Fecha",
    y = "Precio Normalizado",
    color = "Ticker"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom",
    strip.text = element_text(face = "bold")
  ) +
  scale_x_date(date_breaks = "2 years", date_labels = "%Y")

ggsave(file.path(CARPETA_GRAFICOS, "03_comparacion_sector.png"),
       p3, width = 14, height = 10, dpi = 150)

cat("  ✓ Por sector\n")

# ============================================
# GRÁFICO 4: VOLATILIDAD POR PERÍODO
# ============================================

cat("\n[4] Volatilidad por período\n")

volatilidad <- datos_completos %>%
  filter(Periodo != "Inicio COVID") %>%
  group_by(Ticker, Sector, Periodo) %>%
  summarise(
    Volatilidad = sd(Return, na.rm = TRUE) * sqrt(252) * 100,
    .groups = "drop"
  )

p4 <- ggplot(volatilidad, aes(x = Periodo, y = Volatilidad, fill = Ticker)) +
  geom_bar(stat = "identity", position = "dodge", width = 0.7) +
  geom_text(aes(label = paste0(round(Volatilidad, 1), "%")),
            position = position_dodge(0.7), vjust = -0.3, size = 3) +

  facet_wrap(~Sector, ncol = 1) +

  scale_fill_manual(values = COLORES) +

  labs(
    title = "Volatilidad Anualizada por Período",
    subtitle = "Comparación entre períodos COVID",
    x = NULL,
    y = "Volatilidad Anualizada (%)",
    fill = "Ticker"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom",
    strip.text = element_text(face = "bold"),
    axis.text.x = element_text(angle = 15, hjust = 1)
  )

ggsave(file.path(CARPETA_GRAFICOS, "04_volatilidad_periodo.png"),
       p4, width = 12, height = 10, dpi = 150)

cat("  ✓ Volatilidad\n")

# ============================================
# GRÁFICO 5: RETORNOS ACUMULADOS
# ============================================

cat("\n[5] Retornos acumulados\n")

retornos_acum <- datos_completos %>%
  group_by(Ticker) %>%
  arrange(Fecha) %>%
  mutate(Retorno_Acumulado = cumprod(1 + ifelse(is.na(Return), 0, Return)) - 1) %>%
  ungroup()

p5 <- ggplot(retornos_acum, aes(x = Fecha, y = Retorno_Acumulado * 100, color = Ticker)) +
  geom_line(linewidth = 1) +

  facet_wrap(~Sector, ncol = 1, scales = "free_y") +

  geom_rect(aes(xmin = as.Date("2020-01-01"),
                xmax = as.Date("2022-01-01"),
                ymin = -Inf, ymax = Inf),
            fill = "#E74C3C", alpha = 0.05, inherit.aes = FALSE) +

  geom_hline(yintercept = 0, linetype = "dashed", color = "gray30") +

  scale_color_manual(values = COLORES) +

  labs(
    title = "Retornos Acumulados por Sector",
    subtitle = "Rentabilidad total del período",
    x = "Fecha",
    y = "Retorno Acumulado (%)",
    color = "Ticker"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom",
    strip.text = element_text(face = "bold")
  ) +
  scale_x_date(date_breaks = "2 years", date_labels = "%Y")

ggsave(file.path(CARPETA_GRAFICOS, "05_retornos_acumulados.png"),
       p5, width = 14, height = 10, dpi = 150)

cat("  ✓ Retornos acumulados\n")

# ============================================
# GRÁFICO 6: ZOOM CRASH COVID
# ============================================

cat("\n[6] Zoom en crash COVID-19\n")

datos_crash <- datos_completos %>%
  filter(Fecha >= as.Date("2020-01-01") & Fecha <= as.Date("2020-07-31")) %>%
  group_by(Ticker) %>%
  mutate(Precio_Normalizado = Close / first(Close) * 100) %>%
  ungroup()

p6 <- ggplot(datos_crash, aes(x = Fecha, y = Precio_Normalizado, color = Ticker)) +
  geom_line(linewidth = 1.2) +

  geom_vline(xintercept = as.Date("2020-03-11"),
             linetype = "dashed", color = "#E74C3C") +
  geom_vline(xintercept = as.Date("2020-03-16"),
             linetype = "dashed", color = "#C0392B") +

  annotate("text", x = as.Date("2020-03-11"), y = 115,
           label = "OMS\nPandemia", size = 3, hjust = -0.1) +
  annotate("text", x = as.Date("2020-03-16"), y = 110,
           label = "Crash", size = 3, hjust = -0.1) +

  geom_hline(yintercept = 100, linetype = "dotted", color = "gray40") +

  scale_color_manual(values = COLORES) +

  labs(
    title = "Crash del COVID-19: Enero - Julio 2020",
    subtitle = "Base 100 = 1 de enero 2020",
    x = "Fecha",
    y = "Precio Normalizado",
    color = "Ticker"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom"
  ) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b")

ggsave(file.path(CARPETA_GRAFICOS, "06_crash_covid.png"),
       p6, width = 12, height = 7, dpi = 150)

cat("  ✓ Crash COVID\n")

# ============================================
# RESUMEN FINAL
# ============================================

cat("\n========================================\n")
cat("PROCESO COMPLETADO\n")
cat("========================================\n\n")

cat("DATOS GUARDADOS EN:", CARPETA_DATOS, "\n")
cat("  • datos_completos.xlsx\n")
cat("  • [TICKER]_datos.xlsx (6 archivos)\n")
cat("  • resumen_estadistico.xlsx\n\n")

cat("GRÁFICOS GUARDADOS EN:", CARPETA_GRAFICOS, "\n")
cat("  • 01_[TICKER]_serie_completa.png (6 gráficos)\n")
cat("  • 02_comparacion_normalizada.png\n")
cat("  • 03_comparacion_sector.png\n")
cat("  • 04_volatilidad_periodo.png\n")
cat("  • 05_retornos_acumulados.png\n")
cat("  • 06_crash_covid.png\n\n")

cat("Total observaciones:", nrow(datos_completos), "\n")
cat("Período:", as.character(min(datos_completos$Fecha)), "a",
    as.character(max(datos_completos$Fecha)), "\n\n")

cat("========================================\n")
cat("¡LISTO! Revisa las carpetas:\n")
cat("  -", CARPETA_DATOS, "\n")
cat("  -", CARPETA_GRAFICOS, "\n")
cat("========================================\n")
