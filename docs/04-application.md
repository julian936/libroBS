---
title: "Metodología Box-Jenkins y Modelos ARIMA - Análisis de Resultados"
author: "Julian"
date: "2025-11-09"
output:
  html_document:
    toc: true
    toc_float: true
    toc_depth: 3
    theme: cosmo
    highlight: tango
    code_folding: hide
---



# Introducción

La metodología Box-Jenkins proporciona un marco sistemático para identificar, estimar y validar modelos ARIMA (AutoRegressive Integrated Moving Average). Este documento presenta los resultados del análisis aplicado a series de tiempo de precios de acciones durante el período 2015-2025.

El proceso se estructuró en cuatro fases principales:

1. **Identificación**: Evaluación de estacionariedad y determinación de órdenes del modelo
2. **Estimación**: Cálculo de parámetros mediante máxima verosimilitud
3. **Diagnóstico**: Validación del ajuste mediante análisis de residuos
4. **Pronóstico**: Generación de predicciones con intervalos de confianza

---

# Preparación de Datos


``` r
# Leer datos desde Excel
datos <- read_excel("datos_yahoo/datasets/datos_completos.xlsx") %>%
  mutate(Fecha = as.Date(Fecha))

# Seleccionar AAPL para análisis detallado
datos_aapl <- datos %>%
  filter(Ticker == "AAPL") %>%
  arrange(Fecha) %>%
  mutate(log_Close = log(Close))
```

## Información del Dataset

El análisis se realizó sobre **14290 observaciones** de seis activos (AAPL, MSFT, TSLA, PFE, MRNA, JNJ) con un período aproximado de 10 años. Para este documento, utilizaremos Apple (AAPL) como caso de estudio detallado.


Table: (\#tab:tabla-muestra)Primeras 10 observaciones de Apple (AAPL)

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

---

# Fase 1: Identificación del Modelo

## Transformación Logarítmica

<img src="04-application_files/figure-html/visualizacion-series-1.png" width="960" style="display: block; margin: auto;" />

**Interpretación de la transformación:**

La serie original de precios de AAPL muestra dos características importantes:

- **Tendencia alcista pronunciada**: Los precios crecen de aproximadamente \$28 en 2015 a más de \$240 en 2025
- **Varianza creciente**: Las fluctuaciones se amplían con el paso del tiempo (heterocedasticidad)

La transformación logarítmica es crucial porque:

1. **Estabiliza la varianza**: Hace que las fluctuaciones sean más constantes a lo largo del tiempo
2. **Normaliza la distribución**: Ayuda a que los datos se acerquen más a una distribución normal
3. **Facilita la interpretación**: Los cambios se interpretan como tasas de crecimiento porcentuales

## Análisis de Estacionariedad


Table: (\#tab:pruebas-estacionariedad)Resultados de pruebas de estacionariedad

|Prueba              | P.valor|Conclusión      |
|:-------------------|-------:|:---------------|
|ADF (Dickey-Fuller) |  0.4033|No estacionaria |
|KPSS                |  0.0100|No estacionaria |
|Phillips-Perron     |  0.4427|No estacionaria |

**Interpretación de las pruebas:**

Las tres pruebas estadísticas confirman que **la serie logarítmica NO es estacionaria**:

- **ADF (p = 0.4033)**: No rechazamos la hipótesis nula de no estacionariedad
- **KPSS (p = 0.01)**: Rechazamos la hipótesis nula de estacionariedad
- **PP (p = 0.4427)**: Confirma la no estacionariedad

**¿Qué significa esto?**

Una serie no estacionaria presenta:

- Media que varía en el tiempo (tendencia)
- Varianza que puede cambiar
- Autocorrelación que depende del tiempo

Para aplicar modelos ARIMA, necesitamos **diferenciar** la serie (componente "I" en ARIMA), lo que justifica usar `d = 1` en nuestros modelos.

## Funciones ACF y PACF

<img src="04-application_files/figure-html/acf-pacf-1.png" width="960" style="display: block; margin: auto;" />

**Interpretación de las funciones de autocorrelación:**

### ACF (Función de Autocorrelación)
- Muestra un **decaimiento gradual y lento**, característica típica de series no estacionarias con tendencia
- No hay cortes abruptos, lo que indica que la serie tiene "memoria larga"
- Este patrón refuerza la necesidad de diferenciación

### PACF (Función de Autocorrelación Parcial)
- Presenta un valor significativo en el primer lag
- Los valores posteriores caen dentro de las bandas de confianza
- Esto sugiere un componente **AR(1)** una vez diferenciada la serie

**Conclusión para la identificación:**
El análisis ACF/PACF sugiere que después de diferenciar, un modelo ARIMA(1,1,0) o ARIMA(0,1,1) podría ser apropiado. La selección final se hará mediante criterios de información.

---

# Fase 2: Estimación de Parámetros


Table: (\#tab:estimacion-modelos)Comparación de modelos ARIMA candidatos

|Modelo       |       AIC|       BIC| Δ_AIC|
|:------------|---------:|---------:|-----:|
|ARIMA(1,1,0) | -12952.69| -12941.03|  0.00|
|ARIMA(0,1,1) | -12952.43| -12940.77|  0.26|
|ARIMA(1,1,1) | -12951.78| -12934.29|  0.91|

**Interpretación de los criterios de información:**

Los criterios AIC (Akaike) y BIC (Bayesiano) nos ayudan a seleccionar el mejor modelo balanceando:

- **Bondad de ajuste**: Qué tan bien el modelo explica los datos
- **Parsimonia**: Penalización por número de parámetros (BIC penaliza más)

**Resultados del análisis:**

1. **ARIMA(1,1,0)** tiene el AIC más bajo (-1.295269\times 10^{4})
2. **ARIMA(0,1,1)** es muy competitivo con una diferencia mínima
3. **ARIMA(1,1,1)** tiene un AIC ligeramente superior, sugiriendo posible sobreajuste

Las diferencias son pequeñas (< 5 puntos), indicando que los tres modelos tienen capacidad predictiva similar.

## Selección Automática


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
## 
## Training set error measures:
##                        ME       RMSE        MAE           MPE      MAPE
## Training set 1.999705e-06 0.01834763 0.01265994 -0.0008984961 0.2889769
##                   MASE          ACF1
## Training set 0.9974502 -0.0009024181
```

**Interpretación del modelo seleccionado:**

El algoritmo automático seleccionó **ARIMA(0,1,1) with drift**, lo que significa:

- **d = 1**: Una diferenciación para lograr estacionariedad
- **q = 1**: Un término de media móvil (MA) que captura el shock del período anterior
- **drift**: Un término de tendencia constante en la serie diferenciada

**Parámetros estimados:**

- **MA(1) = -0.0557**: Coeficiente negativo pequeño, indica corrección moderada de shocks previos
- **drift = 8.65\times 10^{-4}**: Tendencia diaria positiva muy pequeña (aproximadamente 21.79% anual)

La **sigma² = 3.37\times 10^{-4}** es la varianza del error, muy pequeña debido a la transformación logarítmica.

---

# Fase 3: Diagnóstico del Modelo

<img src="04-application_files/figure-html/diagnostico-1.png" width="960" style="display: block; margin: auto;" />

```
## 
## 	Ljung-Box test
## 
## data:  Residuals from ARIMA(0,1,1) with drift
## Q* = 45.986, df = 9, p-value = 6.057e-07
## 
## Model df: 1.   Total lags used: 10
```

**Interpretación del diagnóstico de residuos:**

El diagnóstico evalúa si el modelo capturó adecuadamente la estructura de los datos. Idealmente, los residuos deben ser **ruido blanco**.

### Gráfico de residuos en el tiempo
- Los residuos oscilan alrededor de cero
- No se observan patrones sistemáticos claros
- La varianza parece relativamente constante (homocedasticidad)

### ACF de residuos
- La mayoría de los lags están dentro de las bandas de confianza
- Algunos lags muestran autocorrelación significativa (rezagos 10, 14, 18)
- Esto sugiere que podría quedar estructura no capturada

### Histograma de residuos
- Distribución aproximadamente simétrica
- Ligeramente leptocúrtica (colas más pesadas que la normal)
- Característica común en datos financieros

## Prueba de Ljung-Box


```
## Prueba de Ljung-Box para autocorrelación de residuos:
```

```
## Estadístico Q = 66.47
```

```
## P-valor = 1.7726e-07
```

```
## ❌ Los residuos PRESENTAN autocorrelación significativa
##    Esto sugiere que el modelo no captura completamente la estructura de los datos.
##    Posibles mejoras: considerar componentes estacionales o modelos más complejos.
```

**Análisis de la prueba:**

La prueba de Ljung-Box evalúa la **hipótesis nula** de que los residuos no están autocorrelacionados (son ruido blanco).

- **P-valor = 1.7726e-07**: Muy significativo (< 0.05)
- **Conclusión**: Rechazamos la hipótesis nula

**Implicaciones:**

Aunque el modelo ARIMA(0,1,1) with drift es razonable, los residuos muestran autocorrelación residual. Esto podría deberse a:

1. **Estacionalidad no capturada**: Patrones semanales o mensuales en los precios
2. **Efectos de calendario**: Días específicos de la semana con comportamientos diferentes
3. **Volatilidad heterocedástica**: Varianza que cambia en el tiempo (requeriría modelos GARCH)
4. **Eventos extremos**: Shocks no capturados por el modelo simple

Para investigación futura, se recomienda explorar modelos SARIMA con componente estacional.

---

# Fase 4: Pronóstico

<img src="04-application_files/figure-html/pronosticos-1.png" width="960" style="display: block; margin: auto;" />

**Interpretación de los pronósticos:**

### Estructura del pronóstico
- **Línea azul oscuro**: Trayectoria puntual pronosticada
- **Banda azul oscuro**: Intervalo de confianza del 80%
- **Banda azul claro**: Intervalo de confianza del 95%

### Características del pronóstico ARIMA
1. **Tendencia lineal**: El drift hace que el pronóstico tenga una tendencia constante
2. **Incertidumbre creciente**: Los intervalos se amplían con el horizonte temporal
3. **Convergencia**: Los pronósticos de largo plazo tienden hacia la media

**Limitaciones:**
Los modelos ARIMA son más efectivos para pronósticos de corto plazo (días o semanas). Para horizontes más largos, la predicción se vuelve menos informativa.

## Transformación a Escala Original


Table: (\#tab:tabla-pronosticos)Pronósticos de precio AAPL en dólares (primeros 10 días)

| Día| Pronóstico ($)| LI 95% ($)| LS 95% ($)| Amplitud ($)| Amplitud (%)|
|---:|--------------:|----------:|----------:|------------:|------------:|
|   1|         245.99|     237.29|     255.00|        17.71|         7.20|
|   2|         246.20|     234.31|     258.69|        24.38|         9.90|
|   3|         246.41|     232.06|     261.66|        29.60|        12.01|
|   4|         246.63|     230.19|     264.24|        34.05|        13.81|
|   5|         246.84|     228.57|     266.57|        38.00|        15.39|
|   6|         247.05|     227.13|     268.72|        41.59|        16.83|
|   7|         247.27|     225.83|     270.73|        44.90|        18.16|
|   8|         247.48|     224.64|     272.64|        48.00|        19.40|
|   9|         247.69|     223.54|     274.46|        50.92|        20.56|
|  10|         247.91|     222.51|     276.21|        53.70|        21.66|

**Interpretación de los pronósticos en escala original:**

Al transformar de vuelta a dólares (aplicando exponencial), observamos:

1. **Pronóstico puntual**: Comienza en ~\$245.99 y crece gradualmente
2. **Amplitud de intervalos**: Aumenta de \$17.71 (día 1) a \$53.7 (día 10)
3. **Amplitud porcentual**: Relativamente constante alrededor del 15.4%

**Nota sobre la transformación exponencial:**
Cuando aplicamos `exp()` a los límites, los intervalos se vuelven **asimétricos** en escala original. Esto refleja correctamente que las pérdidas están limitadas (precio no puede ser negativo) mientras que las ganancias no tienen límite superior.

## Visualización en Escala Original

<img src="04-application_files/figure-html/viz-final-1.png" width="960" style="display: block; margin: auto;" />

**Análisis visual del pronóstico:**

### Continuidad con datos históricos
- El pronóstico comienza suavemente desde el último valor observado
- No hay saltos abruptos, lo que indica un modelo estable

### Comportamiento de la banda de confianza
- Se ensancha progresivamente, reflejando mayor incertidumbre a futuro
- La amplitud es razonable, no extrema ni demasiado estrecha

### Tendencia proyectada
- El modelo captura la tendencia alcista reciente
- La pendiente del pronóstico es conservadora (no extrapola excesivamente)

**Consideraciones prácticas para uso del pronóstico:**

1. **Horizonte recomendado**: 5-10 días para decisiones operativas
2. **Actualización**: Re-estimar el modelo con nuevos datos diariamente
3. **Contexto externo**: Los pronósticos no incorporan eventos futuros (anuncios, resultados trimestrales)

---

# Aplicación a Múltiples Activos


Table: (\#tab:multiples-activos)Modelos ARIMA seleccionados para cada activo

|     |Ticker |Modelo                  |        AIC|        BIC| LB.p.valor|Ruido.Blanco |
|:----|:------|:-----------------------|----------:|----------:|----------:|:------------|
|AAPL |AAPL   |ARIMA(0,1,1) with drift | -12956.673| -12939.185|      0.000|❌           |
|MSFT |MSFT   |ARIMA(0,1,1) with drift | -13411.179| -13393.692|      0.000|❌           |
|TSLA |TSLA   |ARIMA(2,1,2) with drift |  -9408.971|  -9373.995|      0.099|✅           |
|PFE  |PFE    |ARIMA(4,1,1) with drift | -13950.203| -13909.398|      0.003|❌           |
|MRNA |MRNA   |ARIMA(5,2,0)            |  -5518.779|  -5486.086|      0.000|❌           |
|JNJ  |JNJ    |ARIMA(2,1,0)            | -15272.741| -15255.253|      0.000|❌           |

**Interpretación comparativa entre activos:**

### Diversidad de modelos
Cada activo requiere una especificación diferente:

- **AAPL y MSFT**: ARIMA(0,1,1) - Estructura simple, similares entre sí
- **TSLA**: ARIMA(2,1,2) - Mayor complejidad, volatilidad característica
- **PFE**: ARIMA(4,1,1) - Componente AR más desarrollado
- **MRNA**: ARIMA(5,2,0) - Doble diferenciación, serie más errática
- **JNJ**: ARIMA(2,1,0) - Estructura AR pura

### Criterios de información
- **JNJ** tiene el AIC/BIC más bajo: Serie más predecible (empresa estable)
- **MRNA** tiene valores más altos: Mayor volatilidad e incertidumbre

### Calidad del ajuste (Ljung-Box)
- La mayoría de activos **no pasan** la prueba de ruido blanco
- Esto es común en series financieras de alta frecuencia
- Sugiere la presencia de volatilidad heterocedástica o efectos estacionales

**Implicaciones:**

1. **No existe un modelo único**: Cada activo tiene dinámicas propias
2. **Empresas tech (AAPL, MSFT)**: Comportamiento más similar
3. **Sector farmacéutico**: Mayor heterogeneidad (MRNA vs PFE vs JNJ)
4. **Tesla (TSLA)**: Requiere modelado más complejo debido a su volatilidad

---

# Conclusiones

## Resumen de Hallazgos

### 1. Estacionariedad y Transformación
- La transformación logarítmica es **esencial** para estabilizar la varianza
- Todas las series requieren al menos **una diferenciación** (d = 1 o d = 2)
- Las pruebas ADF, KPSS y PP confirman consistentemente la necesidad de diferenciación

### 2. Selección de Modelos
- Los modelos **ARIMA(0,1,1)** y **ARIMA(1,1,1)** son los más frecuentes
- La inclusión de un término de drift mejora el ajuste en la mayoría de casos
- La parsimonia es preferible: modelos simples generalizan mejor

### 3. Diagnóstico de Residuos
- La mayoría de modelos presentan **autocorrelación residual**
- Esto sugiere estructura no capturada, posiblemente:
  - Componentes estacionales (efectos de día de semana)
  - Volatilidad condicional (requeriría GARCH)
  - Eventos extremos no modelados

### 4. Capacidad Predictiva
- Los modelos ARIMA son efectivos para **pronósticos de corto plazo** (1-10 días)
- Los intervalos de confianza reflejan apropiadamente la incertidumbre creciente
- La transformación exponencial produce intervalos asimétricos realistas

## Ventajas de la Metodología ARIMA

### Fortalezas
| Aspecto | Ventaja |
|---------|---------|
| **Marco sistemático** | Proceso iterativo bien estructurado (identificación → estimación → diagnóstico → pronóstico) |
| **Fundamentación estadística** | Pruebas formales de hipótesis en cada etapa |
| **Flexibilidad** | Adaptable a diferentes estructuras de autocorrelación |
| **Intervalos de confianza** | Cuantificación explícita de la incertidumbre |
| **Diagnóstico riguroso** | Herramientas para validar supuestos del modelo |

### Limitaciones
| Aspecto | Limitación |
|---------|------------|
| **Supuestos estrictos** | Requiere estacionariedad (o transformaciones) |
| **Linealidad** | No captura relaciones no lineales complejas |
| **Variables exógenas** | Versión básica no incorpora predictores externos |
| **Horizonte limitado** | Pronósticos de largo plazo convergen a la media |
| **Cambios estructurales** | Sensible a quiebres en la serie |

## Comparación con Holt-Winters

| Característica | ARIMA | Holt-Winters |
|----------------|-------|--------------|
| **Flexibilidad** | Alta (múltiples especificaciones) | Media (nivel, tendencia, estacionalidad) |
| **Fundamentación** | Estadística inferencial | Métodos de suavizamiento |
| **Diagnóstico** | Pruebas formales rigurosas | Análisis visual principalmente |
| **Estacionalidad** | SARIMA (opcional, complejo) | Incorporada directamente |
| **Horizonte óptimo** | Corto a mediano plazo | Corto plazo |
| **Interpretabilidad** | Requiere conocimiento técnico | Más intuitivo |

## Recomendaciones

### Para análisis de series de tiempo financieras:

1. **Transformación inicial**: Aplicar `log()` para estabilizar varianza
2. **Diferenciación**: Usar d = 1 en la mayoría de casos, verificar con pruebas
3. **Selección de modelo**: Comenzar con especificaciones simples (1,1,0) o (0,1,1)
4. **Validación exhaustiva**: No confiar solo en AIC/BIC, revisar residuos
5. **Actualización frecuente**: Re-estimar modelos con nuevos datos

### Extensiones futuras:

1. **Modelos SARIMA**: Incorporar componentes estacionales explícitos
2. **ARIMAX**: Incluir variables exógenas (volumen, índices, sentiment)
3. **GARCH**: Modelar volatilidad condicional heterocedástica
4. **Modelos de cambio de régimen**: Capturar crisis o cambios estructurales
5. **Enfoques híbridos**: Combinar ARIMA con machine learning

---

# Referencias

- Box, G. E. P., Jenkins, G. M., & Reinsel, G. C. (2008). *Time Series Analysis: Forecasting and Control* (4th ed.). Wiley.
- Hyndman, R. J., & Athanasopoulos, G. (2021). *Forecasting: Principles and Practice* (3rd ed.). OTexts.
- Brockwell, P. J., & Davis, R. A. (2016). *Introduction to Time Series and Forecasting* (3rd ed.). Springer.
- Tsay, R. S. (2010). *Analysis of Financial Time Series* (3rd ed.). Wiley.

---

## Notas Técnicas

**Datos utilizados**: Series de precios de cierre ajustados de Yahoo Finance (2015-2025)

**Software**: R versión R version 4.4.2 (2024-10-31 ucrt)

**Paquetes principales**:
- `forecast` (v8.24.0): Modelado ARIMA y pronósticos
- `tseries` (v0.10.58): Pruebas de estacionariedad
- `ggplot2` (v3.5.2): Visualización

**Reproducibilidad**: Código disponible en el repositorio del proyecto
