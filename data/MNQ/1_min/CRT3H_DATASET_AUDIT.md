# Auditoría del dataset CRT 3H

Archivo analizado: `MNQ_CONTFUT_1_min_ALL.csv`

## Identidad

- Proveedor: IBKR
- Símbolo: MNQ
- Tipo: CONTFUT
- Exchange: CME
- Resolución: 1 minuto
- Horario: extendido (`use_rth=0`)
- Filas: 354.805

## Cobertura

- Primer timestamp UTC: 2025-07-31 22:20:52+00:00
- Último timestamp UTC: 2026-07-31 20:59:00+00:00
- Primer timestamp Madrid: 2025-08-01 00:20:52+02:00
- Último timestamp Madrid: 2026-07-31 22:59:00+02:00

El primer registro es una barra parcial iniciada a las 00:20:52 de Madrid. No
afecta a ninguna ventana CRT y las barras posteriores están alineadas al minuto.

## Calidad

- Timestamps UTC duplicados: 0
- Filas con OHLC inválido: 0
- Filas con volumen negativo: 0
- Filas con `use_rth` distinto de 0: 0
- Filas con resolución distinta de `1 min`: 0

## Ventanas CRT en Europe/Madrid

- Londres 06:00-09:00: 259 rangos completos
- Londres 09:00-11:00: 259 ventanas completas
- Nueva York 12:00-15:00: 259 rangos completos
- Nueva York 15:00-17:00: 258 ventanas completas
- Fechas con Londres y Nueva York completos: 258

La ventana NY del 2026-04-03 contiene 15 barras entre 15:00 y 17:00. QuantLab
la marca como incompleta y no genera una operación NY con datos parciales.

## Nota de cobertura

El archivo contiene aproximadamente un año, aunque el nombre del script de
descarga haga referencia a cuatro años. Las pruebas y resultados deben
interpretarse utilizando las fechas efectivas anteriores.
