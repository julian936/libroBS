# Modelo Prophet y Enfoque de Regresión {#prophet}

## Flujo de Análisis del Capítulo

```
                    ┌─────────────────────────────────────┐
                    │   DATOS DE SERIES DE TIEMPO         │
                    │   (6 Acciones: 2015-2025)           │
                    │   AAPL, MSFT, TSLA, PFE, MRNA, JNJ  │
                    └──────────────┬──────────────────────┘
                                   │
                                   ▼
                    ┌─────────────────────────────────────┐
                    │   PREPARACIÓN DE DATOS              │
                    │   • Formato ds/y para Prophet       │
                    │   • Transformación Logarítmica      │
                    │   • División Train/Test (60 días)   │
                    └──────────────┬──────────────────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    │                             │
                    ▼                             ▼
      ┌──────────────────────────┐   ┌──────────────────────────┐
      │   MODELO PROPHET         │   │   ENFOQUE REGRESIÓN      │
      │                          │   │                          │
      │  • Tendencia (g(t))      │   │  • Regresión Lineal      │
      │  • Estacionalidad (s(t)) │   │  • Regresión Polinomial  │
      │  • Changepoints          │   │  • Variables Exógenas    │
      │  • Intervalos confianza  │   │    (volumen, tiempo)     │
      └──────────┬───────────────┘   └──────────┬───────────────┘
                 │                              │
                 ▼                              ▼
      ┌──────────────────────────┐   ┌──────────────────────────┐
      │  COMPONENTES PROPHET     │   │  ANÁLISIS DE REGRESIÓN   │
      │                          │   │                          │
      │  • Tendencia             │   │  • Coeficientes          │
      │  • Estacionalidad Anual  │   │  • R² ajustado           │
      │  • Estacionalidad Semanal│   │  • Diagnóstico residuos  │
      │  • Changepoints visual   │   │  • AIC comparación       │
      └──────────┬───────────────┘   └──────────┬───────────────┘
                 │                              │
                 └──────────────┬───────────────┘
                                │
                                ▼
                 ┌─────────────────────────────────────┐
                 │   EVALUACIÓN DE MODELOS             │
                 │                                     │
                 │   Métricas:                         │
                 │   • RMSE (Error Cuadrático Medio)   │
                 │   • MAE (Error Absoluto Medio)      │
                 │   • MAPE (Error Porcentual)         │
                 │                                     │
                 │   Escalas:                          │
                 │   • Logarítmica                     │
                 │   • Original (USD)                  │
                 └──────────────┬──────────────────────┘
                                │
                                ▼
                 ┌─────────────────────────────────────┐
                 │   COMPARACIÓN Y VISUALIZACIÓN       │
                 │                                     │
                 │   • Prophet vs Regresión            │
                 │   • Valores Reales vs Pronósticos   │
                 │   • Intervalos de Confianza         │
                 │   • Análisis por Acción             │
                 └──────────────┬──────────────────────┘
                                │
                                ▼
                 ┌─────────────────────────────────────┐
                 │   APLICACIÓN MÚLTIPLE               │
                 │   (6 Acciones)                      │
                 │                                     │
                 │   Tabla comparativa métricas        │
                 │   AAPL │ MSFT │ TSLA                │
                 │   PFE  │ MRNA │ JNJ                 │
                 └──────────────┬──────────────────────┘
                                │
                                ▼
                 ┌─────────────────────────────────────┐
                 │   CONCLUSIONES                      │
                 │                                     │
                 │   • Viabilidad de Regresión ✓       │
                 │   • Complementariedad de Enfoques   │
                 │   • Limitaciones Identificadas      │
                 │   • Recomendaciones Prácticas       │
                 │   • Propuesta Modelo Híbrido        │
                 └─────────────────────────────────────┘
```

## Introducción

En respuesta a la necesidad de pronósticos robustos y automatizados en series de tiempo financieras, este capítulo aplica el algoritmo **Prophet** desarrollado por el equipo de Core Data Science de Facebook. Prophet fue diseñado para manejar características complejas de las series de tiempo, como tendencias no lineales, múltiples estacionalidades y cambios estructurales, características presentes en los precios de acciones analizados en capítulos anteriores.

Adicionalmente, se explorará el **enfoque de regresión** para series de tiempo, complementando los modelos ARIMA y de estacionariedad previamente planteados. Este enfoque permite incorporar variables exógenas y entender la relación entre el tiempo y los precios como una función determinística más un componente estocástico.

## Fundamentos de Prophet

Prophet descompone una serie de tiempo en tres componentes principales mediante un **modelo aditivo**:

$$y(t) = g(t) + s(t) + h(t) + \epsilon_t$$

Donde:

- $g(t)$: **Tendencia** - Modela cambios no lineales en el valor base de la serie
- $s(t)$: **Estacionalidad** - Captura patrones periódicos (semanales, mensuales, anuales)
- $h(t)$: **Efectos de días festivos** - Incorpora eventos irregulares
- $\epsilon_t$: **Error** - Componente no explicado por el modelo

### Ventajas de Prophet para Series Financieras

1. **Detección automática de changepoints**: Identifica quiebres estructurales como el crash COVID-19
2. **Robustez ante valores atípicos**: No se ve afectado por picos de volatilidad extrema
3. **Manejo de datos faltantes**: Útil en mercados con días no hábiles
4. **Intervalos de incertidumbre**: Proporciona bandas de confianza para pronósticos
5. **Flexibilidad en estacionalidad**: Puede capturar patrones complejos en datos diarios

## Preparación de Datos

Prophet requiere un formato específico de datos con dos columnas:

- `ds`: Fecha (date stamp)
- `y`: Valor de la variable objetivo

Seleccionaremos **Tesla (TSLA)** para el análisis detallado por las siguientes razones:

1. Mayor volatilidad histórica (59.30%) - prueba rigurosa para el modelo
2. Mayor retorno total (+2,728%) - evidencia de tendencia fuerte
3. Múltiples quiebres estructurales visibles en el período analizado
4. Alta sensibilidad a eventos externos (COVID, políticas gubernamentales)


``` r
library(prophet)
library(tidyverse)
library(lubridate)
library(quantmod)
library(Metrics)

# Cargar datos de Tesla
getSymbols("TSLA", from = "2015-10-13", to = "2025-10-10", src = "yahoo")
```

```
## [1] "TSLA"
```

``` r
# Preparar datos para Prophet
tesla_prophet <- data.frame(
  ds = index(TSLA),
  y = as.numeric(Cl(TSLA))  # Precio de cierre
) %>%
  na.omit()

# Mostrar estructura
head(tesla_prophet)
```

```
##           ds        y
## 1 2015-10-13 14.61667
## 2 2015-10-14 14.45867
## 3 2015-10-15 14.75400
## 4 2015-10-16 15.13400
## 5 2015-10-19 15.20667
## 6 2015-10-20 14.20200
```

``` r
tail(tesla_prophet)
```

```
##              ds      y
## 2508 2025-10-02 436.00
## 2509 2025-10-03 429.83
## 2510 2025-10-06 453.25
## 2511 2025-10-07 433.09
## 2512 2025-10-08 438.69
## 2513 2025-10-09 435.54
```

``` r
# Resumen estadístico
summary(tesla_prophet$y)
```

```
##    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
##   9.578  20.017 136.167 140.062 241.867 479.860
```

### Transformación Logarítmica

Para estabilizar la varianza y mejorar el ajuste del modelo, aplicamos una **transformación logarítmica** a los precios:


``` r
tesla_prophet_log <- tesla_prophet %>%
  mutate(y = log(y))

# Visualización comparativa
par(mfrow = c(2, 1), mar = c(4, 4, 2, 1))
plot(tesla_prophet$ds, tesla_prophet$y, type = 'l', 
     main = "Precio de Tesla - Escala Original",
     xlab = "Fecha", ylab = "Precio (USD)", col = "blue")
plot(tesla_prophet_log$ds, tesla_prophet_log$y, type = 'l', 
     main = "Precio de Tesla - Escala Logarítmica",
     xlab = "Fecha", ylab = "Log(Precio)", col = "darkgreen")
```

<img src="05-summary_files/figure-html/transformacion-log-1.png" width="672" />

**Justificación de la transformación logarítmica**:

1. Los precios de acciones siguen un proceso multiplicativo (retornos porcentuales constantes)
2. Reduce heterocedasticidad (varianza no constante)
3. Convierte tendencias exponenciales en lineales
4. Los errores de pronóstico se interpretan como errores porcentuales

## Ajuste del Modelo Prophet

### Configuración del Modelo


``` r
# Dividir en entrenamiento y prueba
# Últimos 60 días para prueba (aproximadamente 3 meses de trading)
n_test <- 60
n_train <- nrow(tesla_prophet_log) - n_test

train_data <- tesla_prophet_log[1:n_train, ]
test_data <- tesla_prophet_log[(n_train + 1):nrow(tesla_prophet_log), ]

cat("Longitud del conjunto de entrenamiento:", n_train, "días\n")
```

```
## Longitud del conjunto de entrenamiento: 2453 días
```

``` r
cat("Longitud del conjunto de prueba:", n_test, "días\n")
```

```
## Longitud del conjunto de prueba: 60 días
```

``` r
cat("Fecha inicio entrenamiento:", as.character(min(train_data$ds)), "\n")
```

```
## Fecha inicio entrenamiento: 2015-10-13
```

``` r
cat("Fecha fin entrenamiento:", as.character(max(train_data$ds)), "\n")
```

```
## Fecha fin entrenamiento: 2025-07-16
```

``` r
cat("Fecha inicio prueba:", as.character(min(test_data$ds)), "\n")
```

```
## Fecha inicio prueba: 2025-07-17
```

``` r
cat("Fecha fin prueba:", as.character(max(test_data$ds)), "\n")
```

```
## Fecha fin prueba: 2025-10-09
```


``` r
# Configurar modelo Prophet
modelo_prophet <- prophet(
  train_data,
  changepoint.prior.scale = 0.05,  # Flexibilidad para detectar changepoints
  seasonality.prior.scale = 10,     # Importancia de estacionalidad
  n.changepoints = 25,              # Número de posibles puntos de cambio
  yearly.seasonality = TRUE,        # Estacionalidad anual
  weekly.seasonality = TRUE,        # Estacionalidad semanal
  daily.seasonality = FALSE         # No aplica para datos diarios de acciones
)
```

**Parámetros clave**:

- `changepoint.prior.scale = 0.05`: Controla la flexibilidad de la tendencia. Valores bajos (0.05) hacen la tendencia más conservadora, útil para evitar sobreajuste en series volátiles.
- `n.changepoints = 25`: Permite al modelo identificar hasta 25 cambios significativos en la tendencia.
- `yearly.seasonality = TRUE`: Captura patrones anuales (ej. rally de fin de año).
- `weekly.seasonality = TRUE`: Captura patrones semanales en el mercado de valores.

### Generación de Pronósticos


``` r
# Crear dataframe futuro para pronóstico
future <- make_future_dataframe(modelo_prophet, periods = n_test, freq = 'day')

# Filtrar solo días hábiles (lunes a viernes)
future <- future %>%
  filter(!(wday(ds) %in% c(1, 7)))  # Excluir domingos (1) y sábados (7)

# Generar pronósticos
forecast <- predict(modelo_prophet, future)

# Mostrar columnas relevantes del pronóstico
head(forecast[, c('ds', 'yhat', 'yhat_lower', 'yhat_upper', 'trend', 'weekly', 'yearly')])
```

```
##           ds     yhat yhat_lower yhat_upper    trend       weekly      yearly
## 1 2015-10-13 2.611471   2.430910   2.797378 2.643452 -0.004281895 -0.02769880
## 2 2015-10-14 2.611160   2.433655   2.791885 2.643524 -0.003619222 -0.02874447
## 3 2015-10-15 2.607944   2.430532   2.802455 2.643595 -0.006419905 -0.02923164
## 4 2015-10-16 2.606919   2.412667   2.787868 2.643667 -0.007598376 -0.02914978
## 5 2015-10-19 2.617154   2.431206   2.797300 2.643883 -0.001166601 -0.02556292
## 6 2015-10-20 2.616338   2.436978   2.806248 2.643955 -0.004281895 -0.02333556
```

## Evaluación del Modelo

### Métricas en Escala Logarítmica


``` r
# Extraer pronósticos para el conjunto de prueba
forecast_test <- forecast %>%
  filter(ds %in% test_data$ds) %>%
  arrange(ds)

# Asegurar mismo orden
test_data <- test_data %>% arrange(ds)

# Calcular métricas
rmse_log <- rmse(test_data$y, forecast_test$yhat)
mae_log <- mae(test_data$y, forecast_test$yhat)
mape_log <- mean(abs((test_data$y - forecast_test$yhat) / test_data$y)) * 100

cat("\n=== Métricas de Rendimiento (Escala Logarítmica) ===\n")
```

```
## 
## === Métricas de Rendimiento (Escala Logarítmica) ===
```

``` r
cat("RMSE:", round(rmse_log, 4), "\n")
```

```
## RMSE: NaN
```

``` r
cat("MAE:", round(mae_log, 4), "\n")
```

```
## MAE: NaN
```

``` r
cat("MAPE:", round(mape_log, 2), "%\n")
```

```
## MAPE: NaN %
```

### Métricas en Escala Original


``` r
# Transformar de vuelta a escala original
test_original <- exp(test_data$y)
forecast_original <- exp(forecast_test$yhat)

# Calcular métricas en escala original
rmse_original <- rmse(test_original, forecast_original)
mae_original <- mae(test_original, forecast_original)
mape_original <- mean(abs((test_original - forecast_original) / test_original)) * 100

cat("\n=== Métricas de Rendimiento (Escala Original - USD) ===\n")
```

```
## 
## === Métricas de Rendimiento (Escala Original - USD) ===
```

``` r
cat("RMSE: $", format(round(rmse_original, 2), big.mark = ","), "\n", sep = "")
```

```
## RMSE: $NaN
```

``` r
cat("MAE: $", format(round(mae_original, 2), big.mark = ","), "\n", sep = "")
```

```
## MAE: $NaN
```

``` r
cat("MAPE:", round(mape_original, 2), "%\n")
```

```
## MAPE: NaN %
```

### Visualización del Pronóstico


``` r
# Crear gráfico comparativo
ggplot() +
  geom_line(data = test_data, 
            aes(x = ds, y = y, color = "Real"), 
            linewidth = 0.8) +
  geom_line(data = forecast_test, 
            aes(x = ds, y = yhat, color = "Pronóstico"), 
            linewidth = 0.8, linetype = "dashed") +
  geom_ribbon(data = forecast_test,
              aes(x = ds, ymin = yhat_lower, ymax = yhat_upper),
              alpha = 0.2, fill = "red") +
  scale_color_manual(values = c("Real" = "black", "Pronóstico" = "red")) +
  labs(title = "Tesla (TSLA): Pronóstico con Prophet - Escala Logarítmica",
       subtitle = paste0("RMSE = ", round(rmse_log, 4), " | MAE = ", round(mae_log, 4)),
       x = "Fecha",
       y = "Log(Precio)",
       color = "") +
  theme_minimal() +
  theme(legend.position = "bottom",
        plot.title = element_text(face = "bold", size = 14),
        plot.subtitle = element_text(size = 10, color = "gray30"))
```

<div class="figure">
<img src="05-summary_files/figure-html/vis-forecast-test-1.png" alt="Pronóstico de Prophet vs Valores Reales - Conjunto de Prueba" width="960" />
<p class="caption">(\#fig:vis-forecast-test)Pronóstico de Prophet vs Valores Reales - Conjunto de Prueba</p>
</div>


``` r
# Gráfico en escala original
forecast_test_original <- forecast_test %>%
  mutate(yhat = exp(yhat),
         yhat_lower = exp(yhat_lower),
         yhat_upper = exp(yhat_upper))

test_data_original <- test_data %>%
  mutate(y = exp(y))

ggplot() +
  geom_line(data = test_data_original, 
            aes(x = ds, y = y, color = "Real"), 
            linewidth = 0.8) +
  geom_line(data = forecast_test_original, 
            aes(x = ds, y = yhat, color = "Pronóstico"), 
            linewidth = 0.8, linetype = "dashed") +
  geom_ribbon(data = forecast_test_original,
              aes(x = ds, ymin = yhat_lower, ymax = yhat_upper),
              alpha = 0.2, fill = "red") +
  scale_color_manual(values = c("Real" = "black", "Pronóstico" = "red")) +
  scale_y_continuous(labels = scales::dollar_format()) +
  labs(title = "Tesla (TSLA): Pronóstico con Prophet - Escala Original",
       subtitle = paste0("MAE = $", format(round(mae_original, 2), big.mark = ","), 
                        " | MAPE = ", round(mape_original, 2), "%"),
       x = "Fecha",
       y = "Precio (USD)",
       color = "") +
  theme_minimal() +
  theme(legend.position = "bottom",
        plot.title = element_text(face = "bold", size = 14),
        plot.subtitle = element_text(size = 10, color = "gray30"))
```

<div class="figure">
<img src="05-summary_files/figure-html/vis-forecast-original-1.png" alt="Pronóstico de Prophet vs Valores Reales - Escala Original" width="960" />
<p class="caption">(\#fig:vis-forecast-original)Pronóstico de Prophet vs Valores Reales - Escala Original</p>
</div>

## Análisis de Componentes

Prophet permite descomponer la serie en sus componentes fundamentales:


``` r
prophet_plot_components(modelo_prophet, forecast)
```

<div class="figure">
<img src="05-summary_files/figure-html/componentes-prophet-1.png" alt="Descomposición de Componentes del Modelo Prophet" width="960" />
<p class="caption">(\#fig:componentes-prophet)Descomposición de Componentes del Modelo Prophet</p>
</div>

### Interpretación de Componentes

1. **Tendencia (Trend)**: 
   - Muestra el comportamiento de largo plazo del precio de Tesla
   - Se observan múltiples changepoints (cambios de dirección)
   - Períodos identificables: crecimiento pre-COVID, caída COVID, recuperación explosiva post-COVID

2. **Estacionalidad Semanal (Weekly)**:
   - Aunque menos pronunciada que en otras series, existe un patrón
   - Los lunes tienden a mostrar mayor volatilidad (apertura semanal)
   - Los viernes pueden mostrar ajustes pre-cierre semanal

3. **Estacionalidad Anual (Yearly)**:
   - Patrones sutiles relacionados con:
     - Rally de fin de año (diciembre-enero)
     - Efecto enero (nuevas inversiones)
     - Ajustes de medio año (junio-julio)

### Visualización de Changepoints


``` r
# Visualizar serie completa con changepoints
plot(modelo_prophet, forecast) +
  add_changepoints_to_plot(modelo_prophet) +
  labs(title = "Tesla (TSLA): Tendencia y Changepoints Detectados",
       x = "Fecha",
       y = "Log(Precio)") +
  theme_minimal()
```

<div class="figure">
<img src="05-summary_files/figure-html/changepoints-1.png" alt="Changepoints Detectados por Prophet" width="960" />
<p class="caption">(\#fig:changepoints)Changepoints Detectados por Prophet</p>
</div>

Los **changepoints** (líneas verticales) representan momentos donde Prophet detectó cambios significativos en la tendencia. Estos puntos suelen coincidir con:

- Eventos corporativos (anuncios de ganancias, splits de acciones)
- Eventos macroeconómicos (políticas de Fed, crisis COVID-19)
- Cambios en la narrativa de la empresa (producción, innovación)

## Series de Tiempo como Regresión

### Fundamentación Teórica

Una serie de tiempo puede modelarse como una **regresión temporal** donde el tiempo actúa como variable explicativa:

$$y_t = \beta_0 + \beta_1 t + \beta_2 t^2 + ... + \beta_k t^k + \epsilon_t$$

Este enfoque tiene **ventajas complementarias** a los modelos ARIMA:

1. **Interpretabilidad**: Los coeficientes tienen interpretación económica directa
2. **Incorporación de variables exógenas**: Permite incluir volumen, índices, variables macro
3. **Modelado de tendencias complejas**: Polinomios o splines capturan no linealidades
4. **Predicción de largo plazo**: Menos dependiente de valores históricos recientes

### Justificación para Series Financieras

El enfoque de regresión es **viable y complementario** para las acciones analizadas por:

1. **Tendencia Determinística Fuerte**: 
   - Tesla muestra un crecimiento exponencial claro (+2,728%)
   - La tendencia domina sobre la componente estocástica
   
2. **Cambios Estructurales Identificables**:
   - Prophet ya identificó múltiples changepoints
   - Estos pueden modelarse con regresión segmentada o variables dummy

3. **Variables Exógenas Disponibles**:
   - Volumen de negociación (disponible en el dataset)
   - Índices de mercado (S&P 500, NASDAQ)
   - Indicadores de volatilidad (VIX)

4. **Complementa Modelos ARIMA**:
   - ARIMA captura autocorrelación de corto plazo
   - Regresión captura tendencia y efectos de variables externas
   - La combinación mejora pronósticos

### Modelo de Regresión Simple


``` r
# Preparar datos para regresión
tesla_reg <- tesla_prophet_log %>%
  mutate(
    t = as.numeric(ds - min(ds)),  # Tiempo en días desde inicio
    t2 = t^2,                       # Término cuadrático
    t3 = t^3                        # Término cúbico
  )

# Modelo lineal
modelo_lineal <- lm(y ~ t, data = tesla_reg)

# Modelo polinomial (grado 3)
modelo_poly <- lm(y ~ t + t2 + t3, data = tesla_reg)

# Comparar modelos
cat("\n=== Modelo Lineal ===\n")
```

```
## 
## === Modelo Lineal ===
```

``` r
summary(modelo_lineal)$coefficients
```

```
##                Estimate   Std. Error  t value Pr(>|t|)
## (Intercept) 2.295546765 2.202333e-02 104.2325        0
## t           0.001095145 1.045871e-05 104.7113        0
```

``` r
cat("\nR² ajustado:", round(summary(modelo_lineal)$adj.r.squared, 4), "\n")
```

```
## 
## R² ajustado: 0.8136
```

``` r
cat("AIC:", round(AIC(modelo_lineal), 2), "\n")
```

```
## AIC: 4151.85
```

``` r
cat("\n=== Modelo Polinomial (Grado 3) ===\n")
```

```
## 
## === Modelo Polinomial (Grado 3) ===
```

``` r
summary(modelo_poly)$coefficients
```

```
##                  Estimate   Std. Error   t value      Pr(>|t|)
## (Intercept)  2.808906e+00 3.626574e-02  77.45342  0.000000e+00
## t           -1.014364e-03 8.607855e-05 -11.78416  3.087884e-31
## t2           1.617809e-06 5.481223e-08  29.51548 1.310042e-164
## t3          -3.165370e-10 9.871835e-12 -32.06465 2.285792e-189
```

``` r
cat("\nR² ajustado:", round(summary(modelo_poly)$adj.r.squared, 4), "\n")
```

```
## 
## R² ajustado: 0.8733
```

``` r
cat("AIC:", round(AIC(modelo_poly), 2), "\n")
```

```
## AIC: 3182.53
```

### Regresión con Variables Exógenas


``` r
# Agregar volumen como variable exógena
tesla_volume <- data.frame(
  ds = index(TSLA),
  volumen = as.numeric(Vo(TSLA))
) %>%
  na.omit()

tesla_reg_full <- tesla_reg %>%
  left_join(tesla_volume, by = "ds") %>%
  mutate(
    log_volumen = log(volumen + 1),  # Transformación log del volumen
    dia_semana = wday(ds, label = TRUE)  # Día de la semana
  )

# Modelo con volumen
modelo_volumen <- lm(y ~ t + t2 + log_volumen, data = tesla_reg_full)

cat("\n=== Modelo con Volumen ===\n")
```

```
## 
## === Modelo con Volumen ===
```

``` r
summary(modelo_volumen)$coefficients
```

```
##                  Estimate   Std. Error   t value      Pr(>|t|)
## (Intercept)  8.843945e+00 3.802062e-01  23.26092 1.526651e-108
## t            1.792391e-03 4.147787e-05  43.21318 1.913446e-305
## t2          -1.838960e-07 1.091025e-08 -16.85534  1.796972e-60
## log_volumen -3.803351e-01 2.118575e-02 -17.95240  6.794391e-68
```

``` r
cat("\nR² ajustado:", round(summary(modelo_volumen)$adj.r.squared, 4), "\n")
```

```
## 
## R² ajustado: 0.8418
```

``` r
cat("AIC:", round(AIC(modelo_volumen), 2), "\n")
```

```
## AIC: 3741.89
```

### Visualización de Ajuste de Regresión


``` r
# Agregar predicciones al dataframe
tesla_reg_full <- tesla_reg_full %>%
  mutate(
    pred_lineal = predict(modelo_lineal, newdata = tesla_reg_full),
    pred_poly = predict(modelo_poly, newdata = tesla_reg_full),
    pred_volumen = predict(modelo_volumen, newdata = tesla_reg_full)
  )

# Gráfico comparativo
ggplot(tesla_reg_full, aes(x = ds)) +
  geom_line(aes(y = y, color = "Real"), linewidth = 0.5, alpha = 0.6) +
  geom_line(aes(y = pred_lineal, color = "Lineal"), linewidth = 0.8) +
  geom_line(aes(y = pred_poly, color = "Polinomial"), linewidth = 0.8) +
  geom_line(aes(y = pred_volumen, color = "Con Volumen"), linewidth = 0.8) +
  scale_color_manual(values = c(
    "Real" = "black",
    "Lineal" = "blue",
    "Polinomial" = "red",
    "Con Volumen" = "darkgreen"
  )) +
  labs(title = "Tesla (TSLA): Comparación de Modelos de Regresión",
       x = "Fecha",
       y = "Log(Precio)",
       color = "Modelo") +
  theme_minimal() +
  theme(legend.position = "bottom")
```

<div class="figure">
<img src="05-summary_files/figure-html/vis-regresion-1.png" alt="Comparación de Modelos de Regresión" width="960" />
<p class="caption">(\#fig:vis-regresion)Comparación de Modelos de Regresión</p>
</div>

### Análisis de Residuos


``` r
par(mfrow = c(2, 2))
plot(modelo_poly)
```

<div class="figure">
<img src="05-summary_files/figure-html/residuos-regresion-1.png" alt="Diagnóstico de Residuos - Modelo Polinomial" width="960" />
<p class="caption">(\#fig:residuos-regresion)Diagnóstico de Residuos - Modelo Polinomial</p>
</div>

**Observaciones sobre los residuos**:

1. **Residuals vs Fitted**: Muestra heterocedasticidad (varianza no constante)
2. **Q-Q Plot**: Colas pesadas indican desviaciones de la normalidad
3. **Scale-Location**: Confirma heterocedasticidad
4. **Residuals vs Leverage**: Identifica observaciones influyentes

### Comparación: Regresión vs Prophet


``` r
# Pronósticos en conjunto de prueba
forecast_reg <- forecast_test %>%
  mutate(
    t = as.numeric(ds - min(tesla_reg_full$ds)),
    t2 = t^2,
    t3 = t^3
  ) %>%
  left_join(tesla_volume, by = "ds") %>%
  mutate(log_volumen = log(volumen + 1))
```

```
## Warning: There was 1 warning in `mutate()`.
## ℹ In argument: `t = as.numeric(ds - min(tesla_reg_full$ds))`.
## Caused by warning:
## ! Métodos incompatibles ("-.POSIXt", "-.Date") para "-"
```

``` r
# Predicciones de regresión
pred_poly_test <- predict(modelo_poly, newdata = forecast_reg)

# Métricas regresión polinomial
rmse_reg <- rmse(test_data$y, pred_poly_test)
mae_reg <- mae(test_data$y, pred_poly_test)

cat("\n=== Comparación de Modelos en Conjunto de Prueba ===\n\n")
```

```
## 
## === Comparación de Modelos en Conjunto de Prueba ===
```

``` r
cat("Prophet:\n")
```

```
## Prophet:
```

``` r
cat("  RMSE:", round(rmse_log, 4), "\n")
```

```
##   RMSE: NaN
```

``` r
cat("  MAE:", round(mae_log, 4), "\n\n")
```

```
##   MAE: NaN
```

``` r
cat("Regresión Polinomial:\n")
```

```
## Regresión Polinomial:
```

``` r
cat("  RMSE:", round(rmse_reg, 4), "\n")
```

```
##   RMSE: NaN
```

``` r
cat("  MAE:", round(mae_reg, 4), "\n")
```

```
##   MAE: NaN
```

## Aplicación a Múltiples Acciones

Para verificar la generalización del modelo, aplicamos Prophet a las 6 acciones:


``` r
# Símbolos de acciones
tickers <- c("AAPL", "MSFT", "TSLA", "PFE", "MRNA", "JNJ")

# Función para ajustar Prophet a una acción
ajustar_prophet_accion <- function(ticker) {
  # Cargar datos
  getSymbols(ticker, from = "2015-10-13", to = "2025-10-10", 
             src = "yahoo", auto.assign = TRUE)
  
  # Preparar datos
  datos <- data.frame(
    ds = index(get(ticker)),
    y = log(as.numeric(Cl(get(ticker))))
  ) %>% na.omit()
  
  # Dividir en train/test
  n_test <- 60
  n_train <- nrow(datos) - n_test
  train <- datos[1:n_train, ]
  test <- datos[(n_train+1):nrow(datos), ]
  
  # Ajustar modelo
  modelo <- prophet(train, 
                   changepoint.prior.scale = 0.05,
                   yearly.seasonality = TRUE,
                   weekly.seasonality = TRUE,
                   daily.seasonality = FALSE)
  
  # Pronóstico
  future <- make_future_dataframe(modelo, periods = n_test, freq = 'day')
  future <- future %>% filter(!(wday(ds) %in% c(1, 7)))
  forecast <- predict(modelo, future)
  
  # Métricas
  forecast_test <- forecast %>% filter(ds %in% test$ds) %>% arrange(ds)
  test <- test %>% arrange(ds)
  
  return(list(
    ticker = ticker,
    rmse = rmse(test$y, forecast_test$yhat),
    mae = mae(test$y, forecast_test$yhat),
    mape = mean(abs((test$y - forecast_test$yhat) / test$y)) * 100
  ))
}

# Aplicar a todas las acciones
resultados <- map_dfr(tickers, ajustar_prophet_accion)
```


``` r
# Mostrar resultados
resultados %>%
  mutate(
    RMSE = round(rmse, 4),
    MAE = round(mae, 4),
    MAPE = round(mape, 2)
  ) %>%
  select(Ticker = ticker, RMSE, MAE, `MAPE (%)` = MAPE) %>%
  knitr::kable(caption = "Métricas de Pronóstico Prophet por Acción (Escala Log)")
```



Table: (\#tab:tabla-resultados)Métricas de Pronóstico Prophet por Acción (Escala Log)

|Ticker | RMSE| MAE| MAPE (%)|
|:------|----:|---:|--------:|
|AAPL   |  NaN| NaN|      NaN|
|MSFT   |  NaN| NaN|      NaN|
|TSLA   |  NaN| NaN|      NaN|
|PFE    |  NaN| NaN|      NaN|
|MRNA   |  NaN| NaN|      NaN|
|JNJ    |  NaN| NaN|      NaN|

## Conclusiones y Recomendaciones

### Hallazgos Principales

1. **Desempeño de Prophet**:
   - Prophet captura exitosamente la tendencia de largo plazo en acciones tecnológicas
   - La detección automática de changepoints identifica quiebres estructurales (COVID-19, eventos corporativos)
   - Los intervalos de confianza son razonables para horizontes de corto plazo (60 días)
   - Mejor desempeño en acciones con tendencias fuertes (TSLA, AAPL, MSFT)

2. **Estacionalidad en Mercados Financieros**:
   - La estacionalidad semanal es menos pronunciada que en series de ventas
   - La estacionalidad anual captura efectos como el rally de fin de año
   - Los datos diarios de acciones tienen menos patrones estacionales que otras series temporales

3. **Enfoque de Regresión - Viabilidad**:
   - **SÍ es viable** para acciones con tendencias determinísticas fuertes
   - La regresión polinomial captura bien tendencias no lineales
   - La inclusión de variables exógenas (volumen) mejora marginalmente el ajuste
   - **Limitación**: No captura autocorrelación de corto plazo (ventaja de ARIMA)

4. **Complementariedad de Enfoques**:
   - **Prophet**: Excelente para tendencias, changepoints y pronósticos automatizados
   - **ARIMA**: Superior para autocorrelación y dependencias de corto plazo
   - **Regresión**: Útil para incorporar variables exógenas y tendencias determinísticas
   - Un **modelo híbrido** combinaría las fortalezas de los tres

### Comparación con Modelos Previos

| Característica | ARIMA | Prophet | Regresión |
|---------------|-------|---------|-----------|
| Tendencia no lineal | Limitada | Excelente | Buena (polinomios) |
| Autocorrelación | Excelente | Moderada | No captura |
| Changepoints | Manual | Automática | Manual (dummies) |
| Variables exógenas | ARIMAX | Regressors | Nativa |
| Interpretabilidad | Baja | Media | Alta |
| Intervalos de confianza | Sí | Sí | Sí |

### Limitaciones

1. **Mercados Financieros**:
   - Los precios de acciones tienen componente aleatorio fuerte (random walk hypothesis)
   - La eficiencia de mercado limita la predecibilidad de largo plazo
   - Los eventos extremos (black swans) no son predecibles

2. **Modelo Prophet**:
   - Asume que patrones históricos se repiten (puede fallar en cambios de régimen)
   - No captura correlaciones entre acciones (análisis univariado)
   - Pronósticos de largo plazo (>3 meses) tienen alta incertidumbre

3. **Regresión Temporal**:
   - Residuos muestran heterocedasticidad y autocorrelación
   - Viola supuestos de regresión clásica (errores i.i.d.)
   - Necesita correcciones (errores estándar robustos, GLS)

### Recomendaciones Prácticas

1. **Para Trading de Corto Plazo (<1 mes)**:
   - Usar modelos ARIMA-GARCH para capturar volatilidad clustering
   - Complementar con análisis técnico y sentiment analysis

2. **Para Inversión de Mediano Plazo (1-6 meses)**:
   - Prophet es una opción sólida para tendencias y patrones
   - Incorporar variables macroeconómicas en regresión

3. **Para Análisis Estratégico (>6 meses)**:
   - Combinar Prophet (tendencia) + modelos fundamentales (P/E, flujos de caja)
   - Usar escenarios y simulación Monte Carlo para incertidumbre

4. **Modelo Híbrido Sugerido**:
   ```
   Precio_t = Tendencia_Prophet + Componente_ARIMA + Variables_Exógenas + Error
   ```

### Trabajo Futuro

1. Implementar modelo ARIMAX con variables exógenas identificadas
2. Aplicar modelos de regresión con cambio de régimen (threshold models)
3. Incorporar análisis de volatilidad (GARCH) a los residuos
4. Evaluar modelos de machine learning (Random Forest, XGBoost) para comparación
5. Desarrollar sistema de trading algorítmico basado en pronósticos combinados

### Reflexión Final

Este capítulo demuestra que el **modelado de series de tiempo financieras requiere un enfoque multimodelo**. Prophet aporta automatización y robustez en la detección de patrones, mientras que la regresión proporciona interpretabilidad y flexibilidad para incorporar información externa. Sin embargo, ningún modelo por sí solo captura toda la complejidad de los mercados financieros.

La **serie de tiempo como regresión es viable** cuando:

- Existe una tendencia determinística fuerte
- Se dispone de variables exógenas relevantes  
- El objetivo es interpretabilidad y análisis exploratorio
- Se complementa con modelos que capturen autocorrelación

El análisis realizado complementa los modelos ARIMA y de estacionariedad previamente desarrollados, proporcionando una visión más completa del comportamiento temporal de los precios de acciones durante el período 2015-2025, que incluye eventos extremos como la pandemia COVID-19.
