# ============================================================================
# GRÁFICAS DIARIAS - CORRECCIÓN
# ============================================================================

library(readxl)
library(dplyr)
library(ggplot2)
library(scales)

setwd("C:/Users/julia/OneDrive/Documentos/Series de tiempo/libro")

# Cargar datos diarios
datos_diarios_raw <- read_excel("q3export.xlsx")

# Ver nombres reales
cat("Nombres de columnas en q3export:\n")
print(names(datos_diarios_raw))

# Normalizar nombres
names(datos_diarios_raw) <- toupper(trimws(names(datos_diarios_raw)))

# Procesar con nombres correctos
datos_diarios <- datos_diarios_raw %>%
  mutate(
    FECHA = as.Date(.data[[names(datos_diarios_raw)[1]]]),
    REGISTROS_DIA = as.numeric(.data[[names(datos_diarios_raw)[2]]]),
    VALOR_DIA = as.numeric(.data[[names(datos_diarios_raw)[3]]])
  ) %>%
  # Filtrar outliers extremos (más de 1 millón parece anormal)
  filter(REGISTROS_DIA < 1000000)

cat("\nDatos diarios procesados:", nrow(datos_diarios), "registros\n")
cat("Rango de fechas:", format(min(datos_diarios$FECHA), "%d/%m/%Y"),
    "-", format(max(datos_diarios$FECHA), "%d/%m/%Y"), "\n")

# Calcular estadísticas
promedio_diario <- mean(datos_diarios$REGISTROS_DIA, na.rm = TRUE)
sd_diario <- sd(datos_diarios$REGISTROS_DIA, na.rm = TRUE)
mediana_diaria <- median(datos_diarios$REGISTROS_DIA, na.rm = TRUE)

cat("Promedio diario:", format(round(promedio_diario, 0), big.mark = ","), "\n")
cat("Mediana diaria:", format(round(mediana_diaria, 0), big.mark = ","), "\n")
cat("Desv. estándar:", format(round(sd_diario, 0), big.mark = ","), "\n\n")

# ============================================================================
# GRÁFICA 4: VOLUMEN DIARIO CON BARRAS
# ============================================================================

g4 <- ggplot(datos_diarios, aes(x = FECHA, y = REGISTROS_DIA)) +
  geom_col(
    aes(fill = REGISTROS_DIA > promedio_diario),
    width = 0.8
  ) +
  geom_hline(
    yintercept = promedio_diario,
    linetype = "dashed",
    color = "#2E86AB",
    size = 1.2
  ) +
  scale_fill_manual(
    values = c("TRUE" = "#06A77D", "FALSE" = "#C73E1D"),
    labels = c("TRUE" = "Sobre promedio", "FALSE" = "Bajo promedio")
  ) +
  scale_y_continuous(
    labels = comma,
    breaks = pretty_breaks(n = 8)
  ) +
  scale_x_date(
    date_breaks = "3 days",
    date_labels = "%d\n%b"
  ) +
  labs(
    title = "Volumen Diario de Transacciones - Octubre 2025",
    subtitle = paste0("Promedio diario: ",
                      format(round(promedio_diario, 0), big.mark = ","),
                      " registros | Mediana: ",
                      format(round(mediana_diaria, 0), big.mark = ",")),
    x = "Fecha",
    y = "Número de Registros",
    fill = "Comparación con promedio",
    caption = "Fuente: Base de datos SIR | Línea punteada = Promedio diario"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray40"),
    axis.text.x = element_text(angle = 0, hjust = 0.5, size = 11),
    legend.position = "bottom",
    legend.title = element_text(face = "bold"),
    panel.grid.minor = element_blank(),
    plot.caption = element_text(size = 9, color = "gray50", hjust = 1)
  )

ggsave(
  "imagenes_reportes/04_volumen_diario_octubre_2025.png",
  plot = g4,
  width = 14,
  height = 8,
  dpi = 300
)

cat("✓ Gráfica 4 guardada\n")

# ============================================================================
# GRÁFICA 5: TENDENCIA DIARIA CON BANDAS DE VARIABILIDAD
# ============================================================================

g5 <- ggplot(datos_diarios, aes(x = FECHA, y = REGISTROS_DIA)) +
  # Banda de desviación estándar (fondo)
  geom_ribbon(
    aes(
      ymin = promedio_diario - sd_diario,
      ymax = promedio_diario + sd_diario
    ),
    alpha = 0.15,
    fill = "#F18F01"
  ) +
  # Línea de datos reales
  geom_line(color = "#2E86AB", size = 1.3) +
  geom_point(color = "#2E86AB", size = 3.5, alpha = 0.7) +
  # Tendencia suavizada
  geom_smooth(
    method = "loess",
    se = TRUE,
    color = "#A23B72",
    fill = "#A23B72",
    alpha = 0.2,
    size = 1.1
  ) +
  # Línea de promedio
  geom_hline(
    yintercept = promedio_diario,
    linetype = "dashed",
    color = "#F18F01",
    size = 1
  ) +
  scale_y_continuous(
    labels = comma,
    breaks = pretty_breaks(n = 8)
  ) +
  scale_x_date(
    date_breaks = "3 days",
    date_labels = "%d\n%b"
  ) +
  labs(
    title = "Tendencia y Variabilidad del Volumen Diario",
    subtitle = "Octubre 2025 - Análisis con bandas de desviación estándar",
    x = "Fecha",
    y = "Número de Registros",
    caption = paste0(
      "Fuente: Base de datos SIR | ",
      "Banda amarilla = ± 1 desviación estándar (",
      format(round(sd_diario, 0), big.mark = ","),
      ") | Banda morada = Tendencia LOESS"
    )
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray40"),
    axis.text.x = element_text(angle = 0, hjust = 0.5, size = 11),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "gray90"),
    plot.caption = element_text(size = 9, color = "gray50", hjust = 1)
  )

ggsave(
  "imagenes_reportes/05_tendencia_diaria_octubre.png",
  plot = g5,
  width = 14,
  height = 8,
  dpi = 300
)

cat("✓ Gráfica 5 guardada\n")

# ============================================================================
# GRÁFICA 6: BOX PLOT SEMANAL
# ============================================================================

datos_diarios <- datos_diarios %>%
  mutate(
    SEMANA = week(FECHA),
    SEMANA_LABEL = paste("Semana", SEMANA)
  )

g6 <- ggplot(datos_diarios, aes(x = as.factor(SEMANA), y = REGISTROS_DIA)) +
  geom_boxplot(
    fill = "#2E86AB",
    alpha = 0.7,
    outlier.color = "#C73E1D",
    outlier.size = 3
  ) +
  geom_jitter(
    width = 0.2,
    alpha = 0.5,
    color = "#A23B72",
    size = 2
  ) +
  geom_hline(
    yintercept = promedio_diario,
    linetype = "dashed",
    color = "#F18F01",
    size = 1
  ) +
  scale_y_continuous(
    labels = comma,
    breaks = pretty_breaks(n = 8)
  ) +
  labs(
    title = "Distribución del Volumen Diario por Semana",
    subtitle = "Octubre 2025 - Box plots con dispersión de puntos",
    x = "Semana del Año",
    y = "Número de Registros",
    caption = "Fuente: Base de datos SIR | Puntos rojos = Outliers | Línea naranja = Promedio general"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray40"),
    axis.text.x = element_text(size = 11),
    panel.grid.minor = element_blank(),
    plot.caption = element_text(size = 9, color = "gray50", hjust = 1)
  )

ggsave(
  "imagenes_reportes/06_boxplot_semanal_octubre.png",
  plot = g6,
  width = 12,
  height = 8,
  dpi = 300
)

cat("✓ Gráfica 6 guardada\n")

# ============================================================================
# ESTADÍSTICAS ADICIONALES
# ============================================================================

cat("\n============================================================\n")
cat("ESTADÍSTICAS DETALLADAS - VOLUMEN DIARIO OCTUBRE 2025\n")
cat("============================================================\n\n")

cat("Días analizados:", nrow(datos_diarios), "\n")
cat("Rango de fechas:", format(min(datos_diarios$FECHA), "%d/%m/%Y"),
    "al", format(max(datos_diarios$FECHA), "%d/%m/%Y"), "\n\n")

cat("--- MEDIDAS DE TENDENCIA CENTRAL ---\n")
cat("Media:", format(round(promedio_diario, 0), big.mark = ","), "registros\n")
cat("Mediana:", format(round(mediana_diaria, 0), big.mark = ","), "registros\n")
cat("Moda aproximada:", format(round(as.numeric(names(sort(table(round(datos_diarios$REGISTROS_DIA, -3)), decreasing = TRUE)[1])), 0), big.mark = ","), "\n\n")

cat("--- MEDIDAS DE DISPERSIÓN ---\n")
cat("Desviación estándar:", format(round(sd_diario, 0), big.mark = ","), "\n")
cat("Varianza:", format(round(var(datos_diarios$REGISTROS_DIA), 0), big.mark = ","), "\n")
cat("Coeficiente de variación:", round((sd_diario/promedio_diario)*100, 2), "%\n")
cat("Rango:", format(round(max(datos_diarios$REGISTROS_DIA) - min(datos_diarios$REGISTROS_DIA), 0), big.mark = ","), "\n")
cat("IQR (Rango intercuartílico):",
    format(round(IQR(datos_diarios$REGISTROS_DIA), 0), big.mark = ","), "\n\n")

cat("--- VALORES EXTREMOS ---\n")
cat("Máximo:", format(max(datos_diarios$REGISTROS_DIA), big.mark = ","),
    "el", format(datos_diarios$FECHA[which.max(datos_diarios$REGISTROS_DIA)], "%d/%m/%Y"), "\n")
cat("Mínimo:", format(min(datos_diarios$REGISTROS_DIA), big.mark = ","),
    "el", format(datos_diarios$FECHA[which.min(datos_diarios$REGISTROS_DIA)], "%d/%m/%Y"), "\n")
cat("Q1 (Percentil 25):", format(round(quantile(datos_diarios$REGISTROS_DIA, 0.25), 0), big.mark = ","), "\n")
cat("Q3 (Percentil 75):", format(round(quantile(datos_diarios$REGISTROS_DIA, 0.75), 0), big.mark = ","), "\n\n")

cat("--- DÍAS SOBRE/BAJO PROMEDIO ---\n")
dias_sobre <- sum(datos_diarios$REGISTROS_DIA > promedio_diario)
dias_bajo <- sum(datos_diarios$REGISTROS_DIA <= promedio_diario)
cat("Días sobre promedio:", dias_sobre,
    paste0("(", round(dias_sobre/nrow(datos_diarios)*100, 1), "%)"), "\n")
cat("Días bajo promedio:", dias_bajo,
    paste0("(", round(dias_bajo/nrow(datos_diarios)*100, 1), "%)"), "\n\n")

cat("============================================================\n")
cat("✓ ANÁLISIS COMPLETO - 6 GRÁFICAS GENERADAS\n")
cat("============================================================\n\n")

cat("📊 GRÁFICAS DISPONIBLES EN: imagenes_reportes/\n\n")
cat("MENSUALES:\n")
cat("  1. Evolución mensual completa (2024-2025)\n")
cat("  2. Volumen rango normal (sin outliers)\n")
cat("  3. Comparación 2024 vs 2025\n\n")
cat("DIARIAS (Octubre 2025):\n")
cat("  4. Volumen diario (barras comparativas)\n")
cat("  5. Tendencia con bandas de variabilidad\n")
cat("  6. Box plot semanal con dispersión\n\n")
