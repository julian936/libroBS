--- 
title: "Análisis de Series de Tiempo para la Predicción de Precios de Acciones"
author: "Julian Rojas y Natalia Tangarife"
date: "2025-10-13"
site: bookdown::bookdown_site
output: bookdown::gitbook
documentclass: book
bibliography: [book.bib, packages.bib]
biblio-style: apalike
link-citations: yes
github-repo: julian936/libroBS
description: "Análisis de series de tiempo aplicado a la predicción de precios de acciones y su integración con modelos de valoración de opciones financieras."
---

# Propuesta de Análisis {-}

## Descripción de la Información

Para este curso trabajaremos con **series de tiempo de precios diarios de acciones** de empresas tecnológicas cotizadas en mercados estadounidenses, específicamente de compañías como Apple (AAPL), Microsoft (MSFT) y Tesla (TSLA). Los datos incluyen precios de cierre, apertura, máximos, mínimos y volúmenes de negociación, capturados a través de la librería `quantmod` que accede a **Yahoo Finance**.

La serie temporal abarca el período **2015-2025 (últimos 10 años)**, proporcionando aproximadamente **2,500 observaciones por activo**. Este período es particularmente valioso porque incluye:

* **Pre-pandemia (2015-2019):** Período de crecimiento estable y expansión económica
* **Crisis COVID-19 (2020-2021):** Caída abrupta del mercado en marzo 2020 y posterior recuperación acelerada
* **Post-pandemia (2022-2025):** Nuevas dinámicas de mercado, inflación y ajustes de tasas de interés

Esta ventana temporal permite analizar cómo las series de tiempo se comportan ante choques externos extremos, cambios de volatilidad drásticos y diferentes regímenes de mercado.

## Justificación e Importancia del Pronóstico

### El Problema

Los mercados financieros son inherentemente volátiles y presentan comportamientos complejos que combinan tendencias, estacionalidad y componentes aleatorios. Esta complejidad se intensifica dramáticamente durante crisis globales, como lo evidenció el COVID-19 cuando:

* Los mercados experimentaron caídas del 30-40% en semanas (crash de marzo 2020)
* La volatilidad alcanzó niveles no vistos desde la crisis financiera de 2008
* Las empresas tecnológicas mostraron recuperaciones y crecimientos explosivos
* Los patrones históricos de comportamiento se vieron alterados abruptamente

Los inversionistas, analistas y gestores de riesgo necesitan herramientas que les permitan anticipar movimientos de precios incluso en contextos de alta incertidumbre para:

* Optimizar decisiones de compra y venta de activos durante crisis
* Gestionar carteras de inversión de manera proactiva ante cambios de régimen
* Evaluar estrategias de cobertura de riesgo en mercados turbulentos
* Valorar instrumentos derivados considerando volatilidades cambiantes

## Valor Agregado

Este proyecto utiliza **modelos ARIMA (AutoRegressive Integrated Moving Average)** para pronosticar precios de acciones en horizontes de corto plazo. El valor agregado es particularmente significativo dado el período analizado:

### 1. Análisis de Múltiples Regímenes de Mercado

Con datos de 2015-2025, podemos evaluar cómo los modelos ARIMA se desempeñan en tres contextos distintos:

* **Estabilidad (pre-COVID):** Tendencias predecibles y volatilidad moderada
* **Crisis (COVID-19):** Cambios estructurales abruptos y volatilidad extrema
* **Recuperación y ajuste:** Nuevas dinámicas post-pandemia

### 2. Robustez ante Choques Externos

La inclusión del período COVID-19 permite validar si los modelos pueden capturar o adaptarse a disrupciones mayores del mercado, un aspecto crítico que los análisis con datos "normales" no pueden evaluar.

### 3. Sector Tecnológico como Caso de Estudio

Las empresas seleccionadas (AAPL, MSFT, TSLA) tuvieron comportamientos diferenciados durante la pandemia:

* **AAPL y MSFT:** Beneficiadas por digitalización acelerada
* **TSLA:** Crecimiento explosivo a pesar de disrupciones en manufactura

Esto permite comparar cómo las series de tiempo reflejan fundamentos empresariales diferentes.

### 4. Aplicación Práctica Dual

* Pronóstico directo de precios para decisiones de trading en contextos de alta/baja volatilidad
* Insumo para valoración mejorada de opciones financieras mediante la combinación ARIMA + Black-Scholes

### 5. Cuantificación de Incertidumbre Dinámica

Los intervalos de confianza generados reflejan cómo la incertidumbre varía según el contexto (ampliándose en crisis, estrechándose en estabilidad).

### 6. Innovación Metodológica

Integrar predicciones ARIMA calibradas con datos que incluyen eventos extremos con modelos de valoración financiera (Black-Scholes) mejora significativamente la estimación de precios de derivados en mercados reales y complejos.

### Relevancia del Período COVID-19

El análisis del período 2020-2021 es especialmente valioso porque representa un **experimento natural** en finanzas:

* Permite estudiar quiebres estructurales en series de tiempo
* Evalúa la capacidad predictiva de modelos ante eventos de baja probabilidad pero alto impacto ("cisnes negros")
* Proporciona lecciones sobre adaptación de estrategias de inversión en tiempo real
* Genera insights sobre sectores resilientes vs. vulnerables en crisis globales

## Fuentes de Datos y Permisos de Uso

La información es de carácter público y no requiere permisos especiales, proveniente de Yahoo Finance, una fuente reconocida y confiable en el sector financiero.

### Especificaciones Técnicas:

* **Fuente principal:** Yahoo Finance a través de la librería `quantmod` en R
* **Período de análisis:** 2015-2025 (10 años)
* **Observaciones:** Aproximadamente 2,500 datos por activo
* **Frecuencia:** Datos diarios de mercado (252 días por año aproximadamente)
* **Acceso:** API pública sin restricciones para uso académico y de investigación
* **Empresas seleccionadas:** Apple (AAPL), Microsoft (MSFT), Tesla (TSLA)

### Variables a Recopilar:

* **Precio de cierre (Close):** Principal variable para modelado de series de tiempo
* **Precio de apertura (Open):** Para análisis de gaps y volatilidad intradiaria
* **Precio máximo y mínimo (High/Low):** Para cálculo de rangos y volatilidad
* **Volumen de negociación:** Indicador de liquidez y confirmación de tendencias
* **Fechas:** Para construcción de la serie temporal con frecuencia diaria

### Datos Complementarios:

* **Tasa libre de riesgo:** US Treasury Bills (para modelos de valoración)
* **Volatilidad implícita:** De mercado de opciones (comparación con volatilidad histórica)

### Consideraciones Legales:

Todos los datos utilizados provienen de fuentes públicas y gratuitas, destinadas explícitamente para uso académico y de investigación. Yahoo Finance permite el acceso a datos históricos sin restricciones para propósitos educativos. Se citarán adecuadamente todas las fuentes de datos en el análisis final.

## Impacto Esperado

El pronóstico preciso de precios mediante series de tiempo que abarcan crisis globales beneficia directamente a:

* **Inversionistas:** Estrategias informadas sobre cómo activos tecnológicos responden a choques sistémicos
* **Gestores de riesgo:** Herramientas calibradas con eventos extremos reales, no solo simulaciones
* **Analistas financieros:** Comprensión profunda de resiliencia sectorial y patrones de recuperación
* **Académicos e investigadores:** Evidencia empírica sobre comportamiento de series financieras en crisis
* **Traders de opciones:** Valoración más precisa de instrumentos derivados mediante precios predichos más confiables

---

**Nota**: Este documento constituye la propuesta inicial del proyecto de series de tiempo. A lo largo del curso se desarrollará el análisis completo incluyendo metodología ARIMA, implementación en R, validación de modelos, análisis de residuos, pronósticos y su integración con modelos de valoración de opciones financieras.

