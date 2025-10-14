# ============================================
# REGENERAR GRÁFICOS DESDE ARCHIVOS EXCEL
# Lee datos descargados y crea visualizaciones
# ============================================

library(tidyverse)
library(readxl)
library(lubridate)
library(gridExtra)
library(scales)

# ============================================
# CONFIGURACIÓN
# ============================================

# Carpetas
CARPETA_DATOS <- "datos_yahoo/datasets"
CARPETA_GRAFICOS <- "datos_yahoo/graficos_nuevos"

# Crear carpeta para nuevos gráficos
dir.create(CARPETA_GRAFICOS, showWarnings = FALSE, recursive = TRUE)

# Verificar que existan los archivos
if (!file.exists(file.path(CARPETA_DATOS, "datos_completos.xlsx"))) {
  stop("ERROR: No se encuentra el archivo 'datos_completos.xlsx'\n",
       "Asegúrate de haber ejecutado primero el script de descarga.")
}

cat("========================================\n")
cat("REGENERACIÓN DE GRÁFICOS\n")
cat("========================================\n\n")

# Colores únicos para cada empresa
COLORES <- c(
  "AAPL" = "#007AFF",   # Azul
  "MSFT" = "#34C759",   # Verde
  "TSLA" = "#FF3B30",   # Rojo
  "PFE" = "#AF52DE",    # Morado
  "MRNA" = "#FF9500",   # Naranja
  "JNJ" = "#E91E63"     # Rosa/Magenta (diferente de TSLA)
)

TICKERS_TECH <- c("AAPL", "MSFT", "TSLA")
TICKERS_PHARMA <- c("PFE", "MRNA", "JNJ")

# ============================================
# CARGAR DATOS
# ============================================

cat("Cargando datos...\n")

datos_completos <- read_xlsx(file.path(CARPETA_DATOS, "datos_completos.xlsx"))

# Convertir tipos de datos
datos_completos <- datos_completos %>%
  mutate(
    Fecha = as.Date(Fecha),
    Ticker = as.character(Ticker),
    Sector = as.character(Sector),
    Close = as.numeric(Close),
    Open = as.numeric(Open),
    High = as.numeric(High),
    Low = as.numeric(Low),
    Volume = as.numeric(Volume),
    Return = as.numeric(Return),
    Periodo = as.character(Periodo)
  )

cat("  ✓ Datos cargados:", nrow(datos_completos), "observaciones\n")
cat("  ✓ Tickers:", paste(unique(datos_completos$Ticker), collapse = ", "), "\n")
cat("  ✓ Rango:", min(datos_completos$Fecha), "a", max(datos_completos$Fecha), "\n\n")

# Separar por ticker
lista_datos <- split(datos_completos, datos_completos$Ticker)

cat("Generando gráficos...\n\n")

# ============================================
# GRÁFICO 1: SERIES INDIVIDUALES
# ============================================

cat("[1/8] Series individuales por ticker\n")

for (ticker in names(lista_datos)) {
  df <- lista_datos[[ticker]]

  p <- ggplot(df, aes(x = Fecha, y = Close)) +
    geom_line(color = COLORES[ticker], linewidth = 0.8) +

    # Líneas verticales para marcar COVID (sin relleno)
    geom_vline(xintercept = as.Date("2020-01-01"),
               linetype = "dashed", color = "#E74C3C", linewidth = 0.8, alpha = 0.6) +
    geom_vline(xintercept = as.Date("2022-01-01"),
               linetype = "dashed", color = "#E74C3C", linewidth = 0.8, alpha = 0.6) +

    # Anotación del período
    annotate("text", x = as.Date("2021-01-01"),
             y = max(df$Close, na.rm = TRUE) * 0.95,
             label = "Período COVID-19", color = "#E74C3C", size = 3.5, alpha = 0.7) +

    labs(
      title = paste("Serie de Tiempo:", ticker, "-", unique(df$Sector)),
      subtitle = paste(nrow(df), "observaciones | Líneas verticales rojas = Inicio y fin COVID-19"),
      x = "Fecha",
      y = "Precio de Cierre ($)",
      caption = "Fuente: Yahoo Finance"
    ) +
    theme_minimal(base_size = 11) +
    theme(
      plot.title = element_text(face = "bold", size = 13),
      plot.subtitle = element_text(size = 9)
    ) +
    scale_y_continuous(labels = dollar_format()) +
    scale_x_date(date_breaks = "1 year", date_labels = "%Y")

  ggsave(file.path(CARPETA_GRAFICOS, paste0("01_", ticker, "_serie_completa.png")),
         p, width = 12, height = 6, dpi = 150)

  cat("  ✓", ticker, "\n")
}

# ============================================
# GRÁFICO 2: COMPARACIÓN NORMALIZADA
# ============================================

cat("\n[2/8] Comparación normalizada\n")

datos_norm <- datos_completos %>%
  group_by(Ticker) %>%
  mutate(Precio_Normalizado = Close / first(Close) * 100) %>%
  ungroup()

p2 <- ggplot(datos_norm, aes(x = Fecha, y = Precio_Normalizado, color = Ticker)) +
  geom_line(linewidth = 1) +

  # Líneas verticales para COVID (sin relleno)
  geom_vline(xintercept = as.Date("2020-01-01"),
             linetype = "dashed", color = "#E74C3C", linewidth = 0.8, alpha = 0.6) +
  geom_vline(xintercept = as.Date("2022-01-01"),
             linetype = "dashed", color = "#E74C3C", linewidth = 0.8, alpha = 0.6) +

  geom_hline(yintercept = 100, linetype = "dashed", color = "gray30") +

  scale_color_manual(values = COLORES) +

  labs(
    title = "Comparación: Tecnología vs Farmacéuticas (Precios Normalizados)",
    subtitle = "Base 100 = Precio Inicial | Líneas verticales rojas = Período COVID-19",
    x = "Fecha",
    y = "Precio Normalizado (Base 100)",
    color = "Ticker",
    caption = "Fuente: Yahoo Finance"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "bottom"
  ) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y")

ggsave(file.path(CARPETA_GRAFICOS, "02_comparacion_normalizada.png"),
       p2, width = 14, height = 8, dpi = 150)

cat("  ✓ Gráfico generado\n")

# ============================================
# GRÁFICO 3: POR SECTOR
# ============================================

cat("\n[3/8] Comparación por sector\n")

p3 <- ggplot(datos_norm, aes(x = Fecha, y = Precio_Normalizado, color = Ticker)) +
  geom_line(linewidth = 1) +

  facet_wrap(~Sector, ncol = 1, scales = "free_y") +

  # Líneas verticales para COVID
  geom_vline(xintercept = as.Date("2020-01-01"),
             linetype = "dashed", color = "#E74C3C", linewidth = 0.8, alpha = 0.6) +
  geom_vline(xintercept = as.Date("2022-01-01"),
             linetype = "dashed", color = "#E74C3C", linewidth = 0.8, alpha = 0.6) +

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
    plot.title = element_text(face = "bold", size = 13),
    legend.position = "bottom",
    strip.text = element_text(face = "bold", size = 11)
  ) +
  scale_x_date(date_breaks = "2 years", date_labels = "%Y")

ggsave(file.path(CARPETA_GRAFICOS, "03_comparacion_sector.png"),
       p3, width = 14, height = 10, dpi = 150)

cat("  ✓ Gráfico generado\n")

# ============================================
# GRÁFICO 4: VOLATILIDAD POR PERÍODO
# ============================================

cat("\n[4/8] Volatilidad por período\n")

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
    plot.title = element_text(face = "bold", size = 13),
    legend.position = "bottom",
    strip.text = element_text(face = "bold", size = 11),
    axis.text.x = element_text(angle = 15, hjust = 1)
  )

ggsave(file.path(CARPETA_GRAFICOS, "04_volatilidad_periodo.png"),
       p4, width = 12, height = 10, dpi = 150)

cat("  ✓ Gráfico generado\n")

# ============================================
# GRÁFICO 5: RETORNOS ACUMULADOS
# ============================================

cat("\n[5/8] Retornos acumulados\n")

retornos_acum <- datos_completos %>%
  group_by(Ticker) %>%
  arrange(Fecha) %>%
  mutate(Retorno_Acumulado = cumprod(1 + ifelse(is.na(Return), 0, Return)) - 1) %>%
  ungroup()

p5 <- ggplot(retornos_acum, aes(x = Fecha, y = Retorno_Acumulado * 100, color = Ticker)) +
  geom_line(linewidth = 1) +

  facet_wrap(~Sector, ncol = 1, scales = "free_y") +

  # Líneas verticales para COVID
  geom_vline(xintercept = as.Date("2020-01-01"),
             linetype = "dashed", color = "#E74C3C", linewidth = 0.8, alpha = 0.6) +
  geom_vline(xintercept = as.Date("2022-01-01"),
             linetype = "dashed", color = "#E74C3C", linewidth = 0.8, alpha = 0.6) +

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
    plot.title = element_text(face = "bold", size = 13),
    legend.position = "bottom",
    strip.text = element_text(face = "bold", size = 11)
  ) +
  scale_x_date(date_breaks = "2 years", date_labels = "%Y")

ggsave(file.path(CARPETA_GRAFICOS, "05_retornos_acumulados.png"),
       p5, width = 14, height = 10, dpi = 150)

cat("  ✓ Gráfico generado\n")

# ============================================
# GRÁFICO 6: CRASH COVID
# ============================================

cat("\n[6/8] Zoom en crash COVID-19\n")

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

  annotate("text", x = as.Date("2020-03-11"), y = max(datos_crash$Precio_Normalizado) * 0.95,
           label = "OMS\nPandemia", size = 3, hjust = -0.1) +
  annotate("text", x = as.Date("2020-03-16"), y = max(datos_crash$Precio_Normalizado) * 0.90,
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
    plot.title = element_text(face = "bold", size = 13),
    legend.position = "bottom"
  ) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b")

ggsave(file.path(CARPETA_GRAFICOS, "06_crash_covid.png"),
       p6, width = 12, height = 7, dpi = 150)

cat("  ✓ Gráfico generado\n")

# ============================================
# GRÁFICO 7: PERÍODO DE VACUNAS
# ============================================

cat("\n[7/8] Período de vacunas\n")

datos_vacunas <- datos_completos %>%
  filter(Fecha >= as.Date("2020-12-01") & Fecha <= as.Date("2022-01-31")) %>%
  group_by(Ticker) %>%
  mutate(Precio_Normalizado = Close / first(Close) * 100) %>%
  ungroup()

p7 <- ggplot(datos_vacunas, aes(x = Fecha, y = Precio_Normalizado, color = Ticker)) +
  geom_line(linewidth = 1.2) +

  # Eventos importantes
  geom_vline(xintercept = as.Date("2020-12-14"),
             linetype = "dashed", color = "#27AE60", linewidth = 0.8) +

  annotate("text", x = as.Date("2020-12-14"), y = max(datos_vacunas$Precio_Normalizado) * 0.95,
           label = "Primera\nvacunación US", size = 3, hjust = -0.1, color = "#27AE60") +

  geom_hline(yintercept = 100, linetype = "dotted", color = "gray40") +

  scale_color_manual(values = COLORES) +

  labs(
    title = "Período de Vacunas: Diciembre 2020 - Enero 2022",
    subtitle = "Base 100 = 1 de diciembre 2020 | Comportamiento diferenciado por sector",
    x = "Fecha",
    y = "Precio Normalizado (Base 100)",
    color = "Ticker",
    caption = "Las farmacéuticas muestran mayor volatilidad durante este período"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    legend.position = "bottom"
  ) +
  scale_x_date(date_breaks = "2 months", date_labels = "%b %Y")

ggsave(file.path(CARPETA_GRAFICOS, "07_periodo_vacunas.png"),
       p7, width = 14, height = 8, dpi = 150)

cat("  ✓ Gráfico generado\n")

# ============================================
# GRÁFICO 8: RESUMEN DE IMPACTO COVID
# ============================================

cat("\n[8/8] Resumen de impacto COVID\n")

# Calcular métricas de impacto
impacto_covid <- datos_completos %>%
  group_by(Ticker, Sector) %>%
  summarise(
    # Pre-COVID
    Precio_PreCOVID = Close[Fecha == max(Fecha[Fecha < as.Date("2020-03-01")])],

    # Mínimo durante crash
    Precio_Min_Crash = min(Close[Fecha >= as.Date("2020-03-01") &
                                   Fecha <= as.Date("2020-06-01")]),
    Fecha_Min = Fecha[which.min(Close[Fecha >= as.Date("2020-03-01") &
                                        Fecha <= as.Date("2020-06-01")])][1],

    # Actual
    Precio_Actual = last(Close),

    .groups = "drop"
  ) %>%
  mutate(
    Caida_Pct = ((Precio_Min_Crash - Precio_PreCOVID) / Precio_PreCOVID) * 100,
    Recuperacion_Pct = ((Precio_Actual - Precio_Min_Crash) / Precio_Min_Crash) * 100,
    Total_desde_PreCOVID = ((Precio_Actual - Precio_PreCOVID) / Precio_PreCOVID) * 100
  )

# Gráfico de barras
p8 <- ggplot(impacto_covid, aes(x = reorder(Ticker, Caida_Pct), y = Caida_Pct, fill = Sector)) +
  geom_bar(stat = "identity", width = 0.7) +
  geom_text(aes(label = paste0(round(Caida_Pct, 1), "%")),
            hjust = 1.2, size = 3.5, color = "white", fontface = "bold") +
  coord_flip() +

  scale_fill_manual(values = c("Tecnología" = "#3498DB", "Farmacéutica" = "#9B59B6")) +

  labs(
    title = "Caída Máxima Durante Crash de Marzo 2020",
    subtitle = "Porcentaje de caída desde pre-COVID hasta mínimo",
    x = NULL,
    y = "Caída Máxima (%)",
    fill = "Sector",
    caption = "Todas las empresas experimentaron caídas significativas"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    legend.position = "bottom"
  )

ggsave(file.path(CARPETA_GRAFICOS, "08_impacto_covid_tabla.png"),
       p8, width = 10, height = 6, dpi = 150)

cat("  ✓ Gráfico generado\n")

# Guardar tabla de impacto
library(writexl)
write_xlsx(impacto_covid,
           file.path(CARPETA_GRAFICOS, "impacto_covid_metricas.xlsx"))
cat("  ✓ Tabla guardada: impacto_covid_metricas.xlsx\n")

# ============================================
# RESUMEN FINAL
# ============================================

cat("\n========================================\n")
cat("PROCESO COMPLETADO\n")
cat("========================================\n\n")

cat("Gráficos generados en:", CARPETA_GRAFICOS, "\n\n")

cat("ARCHIVOS CREADOS:\n")
cat("  • 01_[TICKER]_serie_completa.png (6 gráficos)\n")
cat("  • 02_comparacion_normalizada.png\n")
cat("  • 03_comparacion_sector.png\n")
cat("  • 04_volatilidad_periodo.png\n")
cat("  • 05_retornos_acumulados.png\n")
cat("  • 06_crash_covid.png\n")
cat("  • 07_periodo_vacunas.png\n")
cat("  • 08_impacto_covid_tabla.png\n")
cat("  • impacto_covid_metricas.xlsx\n\n")

cat("Total de gráficos:", 6 + 7, "\n\n")

cat("========================================\n")
cat("¡Listo para análisis!\n")
cat("========================================\n")
