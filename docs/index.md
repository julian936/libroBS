---
title: "Análisis de Series de Tiempo de Precios de Acciones"
author: "Julian Rojas y Natalia Tangarife"
date: "2025-10-18"
site: bookdown::bookdown_site
output: bookdown::gitbook
documentclass: book
bibliography: [book.bib, packages.bib]
biblio-style: apalike
link-citations: yes
github-repo: julian936/libroBS
description: "Análisis de series de tiempo de precios de acciones durante el período COVID-19 y su integración con modelos de valoración de opciones financieras."
---

# Propuesta de Análisis {-}

## Información a Utilizar

Para este curso trabajaremos con **series de tiempo de precios diarios de acciones** de seis empresas cotizadas en mercados estadounidenses, divididas en dos sectores:

* **Tecnología:** Apple (AAPL), Microsoft (MSFT), Tesla (TSLA)
* **Farmacéuticas:** Pfizer (PFE), Moderna (MRNA), Johnson & Johnson (JNJ)

Los datos abarcan el período **2015-2025 (10 años)**, proporcionando un total de **14,286 observaciones**. Las variables incluyen precios de cierre, apertura, máximos, mínimos y volúmenes de negociación diarios, obtenidos mediante la librería `quantmod` que accede a **Yahoo Finance**.

### Estadísticas Descriptivas del Dataset

<table>
<caption>(\#tab:tabla-resumen)Estadísticas descriptivas de las series de tiempo analizadas</caption>
 <thead>
  <tr>
   <th style="text-align:left;"> Ticker </th>
   <th style="text-align:left;"> Sector </th>
   <th style="text-align:right;"> Obs. </th>
   <th style="text-align:center;"> Inicio </th>
   <th style="text-align:center;"> Fin </th>
   <th style="text-align:right;"> Precio.Mín.... </th>
   <th style="text-align:right;"> Precio.Máx.... </th>
   <th style="text-align:right;"> Volatilidad.... </th>
   <th style="text-align:right;"> Retorno.Total.... </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> AAPL </td>
   <td style="text-align:left;"> Tecnología </td>
   <td style="text-align:right;"> 2514 </td>
   <td style="text-align:center;"> 2015-10-13 </td>
   <td style="text-align:center;"> 2025-10-10 </td>
   <td style="text-align:right;"> 22.58 </td>
   <td style="text-align:right;"> 259.02 </td>
   <td style="text-align:right;"> 29.21 </td>
   <td style="text-align:right;"> 777.61 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> MSFT </td>
   <td style="text-align:left;"> Tecnología </td>
   <td style="text-align:right;"> 2514 </td>
   <td style="text-align:center;"> 2015-10-13 </td>
   <td style="text-align:center;"> 2025-10-10 </td>
   <td style="text-align:right;"> 46.68 </td>
   <td style="text-align:right;"> 535.64 </td>
   <td style="text-align:right;"> 26.96 </td>
   <td style="text-align:right;"> 989.70 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> TSLA </td>
   <td style="text-align:left;"> Tecnología </td>
   <td style="text-align:right;"> 2514 </td>
   <td style="text-align:center;"> 2015-10-13 </td>
   <td style="text-align:center;"> 2025-10-10 </td>
   <td style="text-align:right;"> 9.58 </td>
   <td style="text-align:right;"> 479.86 </td>
   <td style="text-align:right;"> 59.30 </td>
   <td style="text-align:right;"> 2728.89 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> PFE </td>
   <td style="text-align:left;"> Farmacéutica </td>
   <td style="text-align:right;"> 2514 </td>
   <td style="text-align:center;"> 2015-10-13 </td>
   <td style="text-align:center;"> 2025-10-10 </td>
   <td style="text-align:right;"> 21.59 </td>
   <td style="text-align:right;"> 61.25 </td>
   <td style="text-align:right;"> 24.00 </td>
   <td style="text-align:right;"> -20.81 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> MRNA </td>
   <td style="text-align:left;"> Farmacéutica </td>
   <td style="text-align:right;"> 1720 </td>
   <td style="text-align:center;"> 2018-12-07 </td>
   <td style="text-align:center;"> 2025-10-10 </td>
   <td style="text-align:right;"> 12.26 </td>
   <td style="text-align:right;"> 484.47 </td>
   <td style="text-align:right;"> 72.08 </td>
   <td style="text-align:right;"> 44.25 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> JNJ </td>
   <td style="text-align:left;"> Farmacéutica </td>
   <td style="text-align:right;"> 2514 </td>
   <td style="text-align:center;"> 2015-10-13 </td>
   <td style="text-align:center;"> 2025-10-10 </td>
   <td style="text-align:right;"> 94.53 </td>
   <td style="text-align:right;"> 191.08 </td>
   <td style="text-align:right;"> 18.40 </td>
   <td style="text-align:right;"> 99.81 </td>
  </tr>
</tbody>
</table>

**Tabla 1.** Resumen estadístico del dataset con 6 activos y 14,286 observaciones totales. Tesla presenta el mayor retorno (+2,728%) y Moderna la mayor volatilidad (72%).

Este período incluye cuatro fases claramente diferenciadas:

* **Pre-COVID (2015-2019):** Período de crecimiento estable y expansión económica
* **Crisis COVID-19 (2020):** Caída abrupta del mercado y alta volatilidad
* **Período de Vacunas (2021):** Desarrollo y distribución de vacunas COVID-19
* **Post-pandemia (2022-2025):** Nuevas dinámicas de mercado

### Comparación por Sector

<div class="figure">
<img src="graficos/03_comparacion_sector.png" alt="Comparación de desempeño normalizado por sector. Panel superior: Farmacéuticas con Moderna mostrando crecimiento explosivo durante vacunas. Panel inferior: Tecnología con Tesla liderando los retornos. Líneas rojas verticales marcan el período COVID-19." width="100%" />
<p class="caption">(\#fig:figura-sectores)Comparación de desempeño normalizado por sector. Panel superior: Farmacéuticas con Moderna mostrando crecimiento explosivo durante vacunas. Panel inferior: Tecnología con Tesla liderando los retornos. Líneas rojas verticales marcan el período COVID-19.</p>
</div>

La Figura 1 muestra el comportamiento diferenciado entre sectores. El sector tecnológico presenta crecimiento sostenido con Tesla liderando (+2,728%), mientras que el farmacéutico muestra un pico en Moderna durante vacunas seguido de corrección. Este contraste será analizado en capítulos posteriores.

## Importancia del Pronóstico y Valor Agregado

### El Problema

Los mercados financieros presentan comportamientos complejos que se intensifican durante crisis globales. El COVID-19 evidenció esto cuando los mercados experimentaron caídas abruptas, alta volatilidad y recuperaciones diferenciadas por sector. Los inversionistas y gestores de riesgo necesitan herramientas para anticipar movimientos de precios incluso en contextos de alta incertidumbre.

### El Valor Agregado

Este proyecto analiza **series de tiempo de precios de acciones** durante un período de 10 años que incluye eventos extremos. El valor agregado reside en:

**1. Análisis con Datos Reales Abundantes:** Con 14,286 observaciones totales (2,514 por activo principal y 1,720 para MRNA), los análisis tienen suficiente poder estadístico para identificar patrones robustos, tendencias de largo plazo y quiebres estructurales.

**2. Múltiples Regímenes de Mercado:** El período analizado captura diferentes contextos de mercado, desde estabilidad pre-COVID hasta volatilidad extrema durante la pandemia (hasta 72% anual en MRNA) y posterior normalización.

**3. Eventos Extremos Documentados:** El dataset incluye el crash de marzo 2020, el desarrollo de vacunas y la recuperación post-pandemia, permitiendo estudiar quiebres estructurales en series de tiempo y evaluar capacidad predictiva ante eventos de baja probabilidad pero alto impacto.

**4. Comparación Intersectorial Cuantificada:** Los datos revelan contrastes marcados:

- **Tecnología:** Retornos totales entre +777% (AAPL) y +2,728% (TSLA)
- **Farmacéuticas:** Comportamiento heterogéneo desde -20% (PFE) hasta +44% (MRNA)
- **Volatilidad:** Rango de 18% (JNJ) hasta 72% (MRNA)

**5. Caracterización Estadística:** Los datos permiten identificar propiedades como estacionariedad, autocorrelación, heterocedasticidad y cambios de régimen en volatilidad, aspectos que serán desarrollados en capítulos posteriores.

**6. Aplicación a Valoración de Opciones:** Los análisis de volatilidad histórica y comportamiento de precios se integran con el modelo Black-Scholes para mejorar la valoración de opciones financieras.

## Fuentes de Datos y Permisos de Uso

**Fuente:** Yahoo Finance a través de la librería `quantmod` en R. Es una fuente pública reconocida en el sector financiero que permite acceso a datos históricos sin restricciones para uso académico y de investigación.

**Especificaciones técnicas:**

- **Período:** 2015-2025 (10 años, excepto MRNA que inicia en 2018)
- **Observaciones totales:** 14,286 datos distribuidos en 6 activos
- **Frecuencia:** Diaria (aproximadamente 252 días de trading por año)
- **Acceso:** API pública sin permisos especiales requeridos
- **Rango de precios:** Desde $9.58 (TSLA mínimo) hasta $535.64 (MSFT máximo)

**Variables recopiladas:**

- Precios: Cierre, apertura, máximo, mínimo (valores diarios en USD)
- Volumen de negociación diario
- Variables derivadas: Retornos diarios, retornos logarítmicos, volatilidad histórica
- Clasificación temporal: Períodos COVID (Pre, Pandemia, Vacunas, Post)

## Impacto Esperado

El análisis de series de tiempo con más de 14,000 observaciones reales beneficia a:

**Inversionistas:** Comprensión documentada de cómo diferentes sectores responden a choques sistémicos, con evidencia cuantitativa de retornos y volatilidades observados durante crisis.

**Gestores de riesgo:** Identificación de patrones de volatilidad durante eventos extremos, con datos reales que muestran variaciones desde 18% hasta 72% de volatilidad anualizada según el activo y el período.

**Analistas financieros:** Caracterización cuantitativa de resiliencia sectorial respaldada por datos históricos de una década, incluyendo el evento más disruptivo de los mercados financieros en la última generación.

**Traders de opciones:** Estimación mejorada de volatilidad para valoración de derivados, con datos históricos que documentan cambios de régimen en volatilidad durante diferentes fases del mercado.

**Académicos:** Evidencia empírica robusta sobre comportamiento de series financieras durante crisis globales, con suficientes observaciones para análisis estadísticamente significativos y validación de modelos de series de tiempo.

---

**Nota:** Este documento constituye la propuesta inicial del proyecto. Los capítulos posteriores desarrollarán en detalle el análisis exploratorio de las series, pruebas de estacionariedad, modelado de volatilidad, identificación de quiebres estructurales y su integración con modelos de valoración de opciones financieras.


