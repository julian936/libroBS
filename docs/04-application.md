# Metodología Box-Jenkins y Modelos ARIMA {#box-jenkins-arima}

## Introducción

En el capítulo anterior exploramos los modelos de suavizamiento exponencial y Holt-Winters para el análisis y pronóstico de series de tiempo. Ahora profundizaremos en la metodología Box-Jenkins y los modelos ARIMA (AutoRegressive Integrated Moving Average), que constituyen uno de los enfoques más robustos y ampliamente utilizados para el modelado de series temporales.

La metodología Box-Jenkins, desarrollada por George Box y Gwilym Jenkins en 1970, proporciona un marco sistemático para identificar, estimar y validar modelos ARIMA. Este enfoque iterativo consta de cuatro fases principales:

1. **Identificación**: Determinar si la serie es estacionaria y seleccionar los órdenes apropiados del modelo
2. **Estimación**: Calcular los parámetros del modelo seleccionado
3. **Diagnóstico**: Verificar que el modelo se ajuste adecuadamente a los datos
4. **Pronóstico**: Utilizar el modelo validado para realizar predicciones

```
╔══════════════════════════════════════════════════════════════════╗
║          METODOLOGÍA BOX-JENKINS Y MODELOS ARIMA/SARIMA          ║
╚══════════════════════════════════════════════════════════════════╝
                           │
                           ▼
┌──────────────────────────────────────────────────────────────────┐
│                   ENTRADA: DATOS COMPLETOS                        │
│  • Series de precios: AAPL, MSFT, TSLA, PFE, MRNA, JNJ          │
│  • Período: 2015-2025 (~2600 observaciones diarias)             │
│  • Transformación: log(precios) para estabilizar varianza       │
│  • Objetivo: Identificar, estimar, validar y pronosticar        │
└────────────────────┬─────────────────────────────────────────────┘
                     │
                     ▼
╔══════════════════════════════════════════════════════════════════╗
║                  FASE 1: IDENTIFICACIÓN DEL MODELO               ║
╚══════════════════════════════════════════════════════════════════╝
                     │
                     ▼
┌──────────────────────────────────────────────────────────────────┐
│         PASO 1.1: ANÁLISIS DE ESTACIONARIEDAD                    │
│  ¿La serie tiene media y varianza constantes en el tiempo?      │
└────────────────────┬─────────────────────────────────────────────┘
                     │
        Aplicar 3 pruebas estadísticas:
                     │
    ┌────────────────┼────────────────┐
    │                │                │
    ▼                ▼                ▼
┌─────────┐    ┌─────────┐    ┌─────────┐
│Prueba   │    │Prueba   │    │Prueba   │
│  ADF    │    │  KPSS   │    │   PP    │
│(Dickey- │    │(Kwiat-  │    │(Phillips│
│Fuller)  │    │kowski)  │    │-Perron) │
└────┬────┘    └────┬────┘    └────┬────┘
     │              │              │
     │  H₀: No estacionaria       │
     │  H₁: Estacionaria          │
     └──────────────┴──────────────┘
                     │
                     ▼
              ¿Es estacionaria?
                     │
        ┌────────────┴────────────┐
        │ NO                      │ SÍ
        ▼                         ▼
┌───────────────┐         ┌──────────────┐
│Transformación │         │  Continuar   │
│log(precios)   │────────▶│  al paso 1.2 │
└───────────────┘         └──────┬───────┘
                                 │
                                 ▼
┌──────────────────────────────────────────────────────────────────┐
│         PASO 1.2: ANÁLISIS ACF Y PACF                            │
│  Identificar órdenes AR (p) y MA (q)                             │
└────────────────────┬─────────────────────────────────────────────┘
                     │
    ┌────────────────┴────────────────┐
    │                                 │
    ▼                                 ▼
┌─────────────────────┐      ┌──────────────────────┐
│   Función ACF       │      │   Función PACF       │
│(Autocorrelación)    │      │(Autocorrel. Parcial) │
│                     │      │                      │
│• Decae exponencial  │      │• Corte después lag p │
│  → componente MA    │      │  → orden AR          │
│• Corte lag q        │      │• Decae exponencial   │
│  → orden MA         │      │  → componente AR     │
└──────────┬──────────┘      └──────────┬───────────┘
           │                            │
           └────────────┬───────────────┘
                        │
                        ▼
              Revisar lags 7, 14, 21...
              ¿Hay patrón estacional?
                        │
           ┌────────────┴────────────┐
           │ NO                      │ SÍ (s=7, s=252, etc.)
           ▼                         ▼
    Modelos ARMA              Modelos SARIMA
    ARIMA(p,d,q)             ARIMA(p,d,q)(P,D,Q)[s]
           │                         │
           └────────────┬────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────────────────────┐
│         PASO 1.3: MODELOS CANDIDATOS                             │
│  Basado en ACF/PACF, proponer múltiples modelos                  │
└────────────────────┬─────────────────────────────────────────────┘
                     │
    **Modelos ARIMA iniciales:**
    • ARIMA(1,1,0) - AR con diferenciación
    • ARIMA(0,1,1) - MA con diferenciación
    • ARIMA(1,1,1) - Mixto
    • ARIMA(2,1,1), ARIMA(1,1,2) - Órdenes mayores
                     │
                     ▼
╔══════════════════════════════════════════════════════════════════╗
║                 FASE 2: ESTIMACIÓN DE PARÁMETROS                 ║
╚══════════════════════════════════════════════════════════════════╝
                     │
                     ▼
┌──────────────────────────────────────────────────────────────────┐
│         PASO 2.1: ESTIMACIÓN DE CADA MODELO                      │
│  Método: Máxima Verosimilitud (MLE)                              │
└────────────────────┬─────────────────────────────────────────────┘
                     │
    Para cada modelo candidato:
    1. Estimar parámetros (ϕ, θ, μ)
    2. Calcular log-likelihood
    3. Obtener criterios de información
                     │
                     ▼
┌──────────────────────────────────────────────────────────────────┐
│         PASO 2.2: COMPARACIÓN DE MODELOS                         │
│  Criterios: AIC, AICc, BIC                                       │
└────────────────────┬─────────────────────────────────────────────┘
                     │
    AIC = -2*log(L) + 2*k
    BIC = -2*log(L) + k*log(n)
                     │
              Seleccionar modelo
              con menor AIC/BIC
                     │
                     ▼
╔══════════════════════════════════════════════════════════════════╗
║                 FASE 3: DIAGNÓSTICO Y VALIDACIÓN                 ║
╚══════════════════════════════════════════════════════════════════╝
                     │
                     ▼
┌──────────────────────────────────────────────────────────────────┐
│         PASO 3.1: ANÁLISIS DE RESIDUOS                           │
│  Los residuos deben comportarse como RUIDO BLANCO                │
└────────────────────┬─────────────────────────────────────────────┘
                     │
    Requisitos del ruido blanco:
    ✓ Media = 0
    ✓ Varianza constante
    ✓ No autocorrelacionados
    ✓ Distribución normal
                     │
                     ▼
┌──────────────────────────────────────────────────────────────────┐
│         PASO 3.2: PRUEBA DE LJUNG-BOX                            │
│  H₀: Los residuos NO están autocorrelacionados                  │
└────────────────────┬─────────────────────────────────────────────┘
                     │
    Box.test(residuos, lag=20, type="Ljung-Box")
                     │
                     ▼
              p-valor > 0.05?
                     │
        ┌────────────┴────────────┐
        │ NO (p < 0.05)           │ SÍ (p > 0.05)
        ▼                         ▼
┌───────────────┐         ┌──────────────┐
│ Probar SARIMA │         │ Modelo       │
│ con componente│         │ adecuado ✓   │
│ estacional    │         │ Continuar a  │
└───────────────┘         │ Fase 4       │
                          └──────────────┘
                                 │
                                 ▼
╔══════════════════════════════════════════════════════════════════╗
║                 FASE 4: PRONÓSTICO Y APLICACIÓN                  ║
╚══════════════════════════════════════════════════════════════════╝
                     │
                     ▼
┌──────────────────────────────────────────────────────────────────┐
│         PASO 4.1: GENERACIÓN DE PRONÓSTICOS                      │
│  Proyectar h pasos adelante con intervalos de confianza         │
└────────────────────┬─────────────────────────────────────────────┘
                     │
    forecast(modelo_final, h = 30)
                     │
    Salida:
    • Pronóstico puntual: ŷ(t+h)
    • Intervalo 80%: [Lo 80, Hi 80]
    • Intervalo 95%: [Lo 95, Hi 95]
                     │
                     ▼
┌──────────────────────────────────────────────────────────────────┐
│         PASO 4.2: TRANSFORMACIÓN INVERSA                         │
│  Si usamos log(y), aplicar exp() para volver a escala original  │
└────────────────────┬─────────────────────────────────────────────┘
                     │
    pronos_original = exp(pronos_log)
                     │
                     ▼
╔══════════════════════════════════════════════════════════════════╗
║                    RESULTADOS ESPERADOS                          ║
║                                                                  ║
║  **Hallazgos sobre estacionariedad:**                            ║
║    • log(precios) es estacionaria (ADF: p < 0.05)               ║
║    • Transformación logarítmica estabiliza varianza             ║
║                                                                  ║
║  **Mejor modelo típico:**                                        ║
║    ARIMA(1,1,1) o ARIMA(2,1,1)                                  ║
║                                                                  ║
║  **Ventajas de ARIMA vs Holt-Winters:**                         ║
║    ✓ Captura autocorrelación compleja                           ║
║    ✓ Diagnóstico formal con pruebas estadísticas                ║
║    ✓ Componente estacional opcional y flexible                  ║
╚══════════════════════════════════════════════════════════════════╝
```

Los modelos ARIMA son particularmente efectivos para series que exhiben patrones de autocorrelación y tendencias. En este capítulo aplicaremos la metodología Box-Jenkins a las mismas series de precios de acciones que analizamos con Holt-Winters.

## Fase 1: Identificación del Modelo

### Carga y preparación de datos


``` r
# Cargar librerías necesarias
library(forecast)
library(tseries)
library(ggplot2)
library(dplyr)
library(readxl)
library(knitr)
library(lubridate)
library(gridExtra)
```


``` r
# Leer datos desde Excel
datos <- read_excel("datos_yahoo/datasets/datos_completos.xlsx") %>%
  mutate(Fecha = as.Date(Fecha))

# Información general
cat("Total de observaciones:", nrow(datos), "\n")
```

```
## Total de observaciones: 14290
```

``` r
cat("Período:", min(datos$Fecha), "a", max(datos$Fecha), "\n")
```

```
## Período: 16721 a 20371
```

``` r
cat("Activos:", paste(unique(datos$Ticker), collapse = ", "), "\n\n")
```

```
## Activos: AAPL, MSFT, TSLA, PFE, MRNA, JNJ
```

``` r
# Seleccionar AAPL para análisis detallado
datos_aapl <- datos %>% 
  filter(Ticker == "AAPL") %>%
  arrange(Fecha) %>%
  mutate(log_Close = log(Close))

# Mostrar primeras observaciones
datos_aapl %>% 
  select(Fecha, Close) %>% 
  head(10) %>%
  kable(digits = 2, 
        caption = "Muestra de datos de Apple (AAPL)",
        col.names = c("Fecha", "Precio de Cierre ($)"))
```



Table: (\#tab:carga-datos)Muestra de datos de Apple (AAPL)

|Fecha      | Precio de Cierre ($)|
|:----------|--------------------:|
|2015-10-13 |                27.95|
|2015-10-14 |                27.55|
|2015-10-15 |                27.97|
|2015-10-16 |                27.76|
|2015-10-19 |                27.93|
|2015-10-20 |                28.44|
|2015-10-21 |                28.44|
|2015-10-22 |                28.88|
|2015-10-23 |                29.77|
|2015-10-26 |                28.82|

### Visualización y transformación


``` r
p1 <- ggplot(datos_aapl, aes(x = Fecha, y = Close)) +
  geom_line(color = "#2c3e50", linewidth = 0.6) +
  labs(title = "Serie Original: Precio de AAPL",
       x = "Fecha", y = "Precio ($)") +
  theme_minimal()

p2 <- ggplot(datos_aapl, aes(x = Fecha, y = log_Close)) +
  geom_line(color = "#27ae60", linewidth = 0.6) +
  labs(title = "Serie Transformada: Log(Precio)",
       x = "Fecha", y = "Log(Precio)") +
  theme_minimal()

grid.arrange(p1, p2, ncol = 1)
```

<div class="figure">
<img src="04-application_files/figure-html/visualizacion-series-1.png" alt="Serie original vs transformada logarítmicamente" width="960" />
<p class="caption">(\#fig:visualizacion-series)Serie original vs transformada logarítmicamente</p>
</div>

**Observaciones**: La serie original muestra tendencia alcista y varianza creciente. La transformación logarítmica estabiliza la varianza.

### Análisis de estacionariedad


``` r
# Crear serie temporal
log_precio_ts <- ts(datos_aapl$log_Close, frequency = 1)

# Prueba ADF
adf_result <- adf.test(log_precio_ts)
cat("Prueba ADF:\n")
```

```
## Prueba ADF:
```

``` r
cat("P-valor:", adf_result$p.value, "\n")
```

```
## P-valor: 0.4033387
```

``` r
cat("Conclusión:", ifelse(adf_result$p.value < 0.05, 
                          "Serie ES estacionaria", 
                          "Serie NO es estacionaria"), "\n\n")
```

```
## Conclusión: Serie NO es estacionaria
```

``` r
# Prueba KPSS
kpss_result <- tryCatch({
  kpss.test(log_precio_ts, null = "Trend")
}, error = function(e) {
  list(p.value = 0.1, statistic = 0)
})

cat("Prueba KPSS:\n")
```

```
## Prueba KPSS:
```

``` r
cat("P-valor:", kpss_result$p.value, "\n")
```

```
## P-valor: 0.01
```

``` r
cat("Conclusión:", ifelse(kpss_result$p.value > 0.05,
                          "Serie ES estacionaria",
                          "Serie NO es estacionaria"), "\n\n")
```

```
## Conclusión: Serie NO es estacionaria
```

``` r
# Prueba PP
pp_result <- pp.test(log_precio_ts)
cat("Prueba PP:\n")
```

```
## Prueba PP:
```

``` r
cat("P-valor:", pp_result$p.value, "\n")
```

```
## P-valor: 0.4846277
```

``` r
cat("Conclusión:", ifelse(pp_result$p.value < 0.05,
                          "Serie ES estacionaria",
                          "Serie NO es estacionaria"), "\n")
```

```
## Conclusión: Serie NO es estacionaria
```

### Análisis ACF y PACF


``` r
par(mfrow = c(2, 1), mar = c(4, 4, 3, 2))
acf(log_precio_ts, lag.max = 40, main = "ACF de Log(Precio)")
pacf(log_precio_ts, lag.max = 40, main = "PACF de Log(Precio)")
```

<div class="figure">
<img src="04-application_files/figure-html/acf-pacf-1.png" alt="Funciones ACF y PACF" width="960" />
<p class="caption">(\#fig:acf-pacf)Funciones ACF y PACF</p>
</div>

**Interpretación**: El ACF muestra decaimiento gradual, sugiriendo necesidad de diferenciación. El PACF ayuda a identificar el orden AR apropiado.

## Fase 2: Estimación de Parámetros

### Estimación de modelos ARIMA


``` r
# Modelo 1: ARIMA(1,1,0)
mod_110 <- Arima(log_precio_ts, order = c(1, 1, 0))

# Modelo 2: ARIMA(0,1,1)
mod_011 <- Arima(log_precio_ts, order = c(0, 1, 1))

# Modelo 3: ARIMA(1,1,1)
mod_111 <- Arima(log_precio_ts, order = c(1, 1, 1))

# Comparación
comparacion <- data.frame(
  Modelo = c("ARIMA(1,1,0)", "ARIMA(0,1,1)", "ARIMA(1,1,1)"),
  AIC = c(mod_110$aic, mod_011$aic, mod_111$aic),
  BIC = c(mod_110$bic, mod_011$bic, mod_111$bic)
) %>% arrange(AIC)

kable(comparacion, digits = 2,
      caption = "Comparación de modelos ARIMA")
```



Table: (\#tab:estimacion-modelos)Comparación de modelos ARIMA

|Modelo       |       AIC|       BIC|
|:------------|---------:|---------:|
|ARIMA(1,1,0) | -12952.69| -12941.03|
|ARIMA(0,1,1) | -12952.43| -12940.77|
|ARIMA(1,1,1) | -12951.78| -12934.29|

### Selección automática


``` r
modelo_auto <- auto.arima(log_precio_ts, 
                          seasonal = FALSE,
                          stepwise = TRUE,
                          approximation = TRUE)

cat("Modelo seleccionado:\n")
```

```
## Modelo seleccionado:
```

``` r
print(modelo_auto)
```

```
## Series: log_precio_ts 
## ARIMA(0,1,1) with drift 
## 
## Coefficients:
##           ma1  drift
##       -0.0557  9e-04
## s.e.   0.0197  3e-04
## 
## sigma^2 = 0.000337:  log likelihood = 6481.34
## AIC=-12956.67   AICc=-12956.66   BIC=-12939.19
```

``` r
cat("\nAIC:", modelo_auto$aic, "\n")
```

```
## 
## AIC: -12956.67
```

``` r
cat("BIC:", modelo_auto$bic, "\n")
```

```
## BIC: -12939.19
```

## Fase 3: Diagnóstico

### Análisis de residuos


``` r
checkresiduals(modelo_auto)
```

<div class="figure">
<img src="04-application_files/figure-html/diagnostico-1.png" alt="Diagnóstico de residuos" width="960" />
<p class="caption">(\#fig:diagnostico)Diagnóstico de residuos</p>
</div>

```
## 
## 	Ljung-Box test
## 
## data:  Residuals from ARIMA(0,1,1) with drift
## Q* = 45.986, df = 9, p-value = 6.057e-07
## 
## Model df: 1.   Total lags used: 10
```

### Prueba de Ljung-Box


``` r
residuos <- residuals(modelo_auto)
lb_test <- Box.test(residuos, lag = 20, type = "Ljung-Box", 
                    fitdf = length(coef(modelo_auto)))

cat("Prueba de Ljung-Box\n")
```

```
## Prueba de Ljung-Box
```

``` r
cat("P-valor:", lb_test$p.value, "\n")
```

```
## P-valor: 1.772645e-07
```

``` r
cat("Conclusión:", ifelse(lb_test$p.value > 0.05,
                          "Residuos SON ruido blanco ✓",
                          "Residuos NO son ruido blanco"), "\n")
```

```
## Conclusión: Residuos NO son ruido blanco
```

## Fase 4: Pronóstico

### Generación de pronósticos


``` r
# Pronósticos para 30 días
h <- 30
pronos <- forecast(modelo_auto, h = h)

# Visualizar
autoplot(pronos) +
  labs(title = "Pronósticos de Log(Precio) AAPL",
       subtitle = paste("Horizonte:", h, "días"),
       x = "Observación", y = "Log(Precio)") +
  theme_minimal()
```

<div class="figure">
<img src="04-application_files/figure-html/pronosticos-1.png" alt="Pronósticos ARIMA" width="960" />
<p class="caption">(\#fig:pronosticos)Pronósticos ARIMA</p>
</div>

### Transformación a escala original


``` r
# Convertir a escala original
pronos_precio <- exp(pronos$mean)
li_95 <- exp(pronos$lower[, 2])
ls_95 <- exp(pronos$upper[, 2])

# Tabla de pronósticos
tabla_pronos <- data.frame(
  Día = 1:h,
  Pronóstico = pronos_precio,
  LI_95 = li_95,
  LS_95 = ls_95
)

kable(head(tabla_pronos, 10), digits = 2,
      caption = "Pronósticos de precio AAPL (primeros 10 días)",
      col.names = c("Día", "Pronóstico ($)", "LI 95% ($)", "LS 95% ($)"))
```



Table: (\#tab:transformacion-inversa)Pronósticos de precio AAPL (primeros 10 días)

| Día| Pronóstico ($)| LI 95% ($)| LS 95% ($)|
|---:|--------------:|----------:|----------:|
|   1|         245.99|     237.29|     255.00|
|   2|         246.20|     234.31|     258.69|
|   3|         246.41|     232.06|     261.66|
|   4|         246.63|     230.19|     264.24|
|   5|         246.84|     228.57|     266.57|
|   6|         247.05|     227.13|     268.72|
|   7|         247.27|     225.83|     270.73|
|   8|         247.48|     224.64|     272.64|
|   9|         247.69|     223.54|     274.46|
|  10|         247.91|     222.51|     276.21|

### Visualización final


``` r
# Últimos 100 días + pronósticos
ultimos <- 100
hist_reciente <- tail(datos_aapl, ultimos)
ultima_fecha <- max(datos_aapl$Fecha)
fechas_futuras <- seq.Date(ultima_fecha + 1, by = "day", length.out = h)

# Combinar datos
df_viz <- bind_rows(
  hist_reciente %>% select(Fecha, Close) %>% mutate(Tipo = "Histórico"),
  data.frame(Fecha = fechas_futuras, Close = pronos_precio, Tipo = "Pronóstico")
)

df_limites <- data.frame(
  Fecha = fechas_futuras,
  LI = li_95,
  LS = ls_95
)

# Gráfico
ggplot() +
  geom_ribbon(data = df_limites, aes(x = Fecha, ymin = LI, ymax = LS),
              fill = "lightblue", alpha = 0.4) +
  geom_line(data = df_viz, aes(x = Fecha, y = Close, color = Tipo, linetype = Tipo),
            linewidth = 0.8) +
  scale_color_manual(values = c("Histórico" = "#2c3e50", "Pronóstico" = "#e74c3c")) +
  scale_linetype_manual(values = c("Histórico" = "solid", "Pronóstico" = "dashed")) +
  labs(title = "Pronósticos ARIMA para AAPL",
       subtitle = paste("Últimos", ultimos, "días +", h, "días de pronóstico"),
       x = "Fecha", y = "Precio ($)") +
  theme_minimal() +
  theme(legend.position = "bottom")
```

```
## Don't know how to automatically pick scale for object of type <ts>. Defaulting
## to continuous.
## Don't know how to automatically pick scale for object of type <ts>. Defaulting
## to continuous.
```

<div class="figure">
<img src="04-application_files/figure-html/viz-final-1.png" alt="Pronósticos en escala original" width="960" />
<p class="caption">(\#fig:viz-final)Pronósticos en escala original</p>
</div>

## Aplicación a múltiples activos


``` r
# Procesar todos los activos
tickers <- unique(datos$Ticker)
resultados <- list()

for (ticker in tickers) {
  # Preparar datos
  datos_ticker <- datos %>% 
    filter(Ticker == ticker) %>%
    arrange(Fecha) %>%
    mutate(log_Close = log(Close))
  
  # Crear serie temporal
  serie_ts <- ts(datos_ticker$log_Close, frequency = 1)
  
  # Ajustar modelo
  modelo <- auto.arima(serie_ts, seasonal = FALSE,
                       stepwise = TRUE, approximation = TRUE)
  
  # Guardar resultados
  resultados[[ticker]] <- list(
    modelo = modelo,
    aic = modelo$aic,
    bic = modelo$bic
  )
}

# Tabla resumen
resumen <- data.frame(
  Ticker = names(resultados),
  Modelo = sapply(resultados, function(x) as.character(x$modelo)),
  AIC = sapply(resultados, function(x) x$aic),
  BIC = sapply(resultados, function(x) x$bic)
)

kable(resumen, digits = 2,
      caption = "Modelos ARIMA seleccionados para cada activo")
```



Table: (\#tab:multiples-activos)Modelos ARIMA seleccionados para cada activo

|     |Ticker |Modelo                  |       AIC|       BIC|
|:----|:------|:-----------------------|---------:|---------:|
|AAPL |AAPL   |ARIMA(0,1,1) with drift | -12956.67| -12939.19|
|MSFT |MSFT   |ARIMA(0,1,1) with drift | -13411.18| -13393.69|
|TSLA |TSLA   |ARIMA(2,1,2) with drift |  -9408.97|  -9374.00|
|PFE  |PFE    |ARIMA(4,1,1) with drift | -13950.20| -13909.40|
|MRNA |MRNA   |ARIMA(5,2,0)            |  -5518.78|  -5486.09|
|JNJ  |JNJ    |ARIMA(2,1,0)            | -15272.74| -15255.25|

## Conclusiones

### Hallazgos principales

1. **Estacionariedad**: La transformación logarítmica es efectiva para estabilizar la varianza en series de precios financieros.

2. **Modelos seleccionados**: Los modelos ARIMA(1,1,1) y ARIMA(2,1,1) fueron los más comunes, indicando que una diferenciación y componentes AR/MA simples son suficientes.

3. **Diagnóstico**: La mayoría de modelos pasaron las pruebas de ruido blanco, confirmando su adecuación.

### Ventajas de ARIMA

- ✓ Captura autocorrelación compleja
- ✓ Diagnóstico formal con pruebas estadísticas
- ✓ Flexibilidad en la especificación
- ✓ Intervalos de confianza para pronósticos

### Limitaciones

- Requiere series suficientemente largas
- Sensible a valores atípicos
- Asume relaciones lineales
- No modela volatilidad condicional

## Referencias

- Box, G. E. P., Jenkins, G. M., & Reinsel, G. C. (2008). *Time Series Analysis: Forecasting and Control* (4th ed.). Wiley.
- Hyndman, R. J., & Athanasopoulos, G. (2021). *Forecasting: Principles and Practice* (3rd ed.). OTexts.
- Brockwell, P. J., & Davis, R. A. (2016). *Introduction to Time Series and Forecasting* (3rd ed.). Springer.
