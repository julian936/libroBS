--- 
title: "Valoración de Opciones Financieras: Comparación del Modelo de Black-Scholes con Precios de Mercado"
author: "Julian Rojas y Natalia Tangarife"
date: "2025-10-08"
site: bookdown::bookdown_site
output: bookdown::gitbook
documentclass: book
bibliography: [book.bib, packages.bib]
biblio-style: apalike
link-citations: yes
github-repo: julian936/libroBS
description: "Análisis de series de tiempo aplicado a la valoración de opciones financieras mediante el modelo de Black-Scholes."
---

# Propuesta de Análisis {-}

## Tema Seleccionado

El presente trabajo se enfoca en el análisis de **series de tiempo de precios de opciones financieras** (calls y puts) sobre acciones cotizadas en mercados internacionales. Específicamente, se implementará el **modelo de Black-Scholes** para calcular el valor teórico de las opciones y se comparará con los precios reales observados en el mercado.

## Justificación



## Valor Agregado



## Fuentes de Datos y Permisos de Uso

### Fuentes de Datos Propuestas:

1. **Yahoo Finance** (https://finance.yahoo.com/)
   - Acceso: Gratuito mediante API o descarga directa
   - Datos: Precios históricos de acciones y opciones
   - Permisos: Uso personal y académico permitido bajo sus términos de servicio
   - Paquete R: `quantmod` o `yahoofinancer`



### Variables a Recopilar:

- Precio del activo subyacente (S): Serie temporal diaria
- Precio de ejercicio (K): Datos de contratos específicos
- Tiempo hasta vencimiento (T): Calculado desde fecha de observación
- Tasa libre de riesgo (r): US Treasury Bills (1-3 meses)
- Volatilidad histórica (σ): Calculada a partir de rendimientos del subyacente
- Precios de mercado de calls y puts: Datos históricos de opciones

### Consideraciones Legales:

Todos los datos utilizados provienen de fuentes públicas y gratuitas, destinadas explícitamente para uso académico y de investigación. Se citarán adecuadamente todas las fuentes de datos en el análisis final. No se utilizarán datos propietarios de empresas específicas que requieran licencias comerciales.

---

**Nota**: Este documento constituye la propuesta inicial del proyecto. A lo largo del curso se desarrollará el análisis completo incluyendo metodología, implementación en R, resultados y conclusiones.

