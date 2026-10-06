# Auditoría del calendario económico gratuito

Archivo recibido: `forex_factory_cache.csv`

Huella SHA-256:

```text
f4e92bca4168cfe6e4598d3d2a69ac933dfd6c7c94550e056498a418e3efaf5e
```

## Cobertura

- 83.427 eventos totales.
- 21.514 eventos USD.
- 5.910 eventos USD clasificados como `High Impact Expected`.
- Cobertura USD: 01/01/2007–07/04/2025.
- Cobertura del mercado MNQ incluido: 31/07/2025–31/07/2026.
- Solapamiento: ninguno.

Fuera de cobertura, QuantLab debe clasificar las noticias como `NO_EVALUABLE`,
nunca como ausencia de noticias.

## Calidad temporal

El timestamp conserva un offset de Teherán, pero parte de los eventos usa
`00:00:00` como hora de relleno. Entre 2023 y 2025:

- `Non-Farm Employment Change`: 28 de 28 publicaciones a las 00:00.
- `CPI m/m`: 27 de 27 publicaciones a las 00:00.
- `Retail Sales m/m`: 27 de 27 publicaciones a las 00:00.
- `PPI m/m`: 27 de 27 publicaciones a las 00:00.
- `FOMC Statement`: 18 de 18 publicaciones a las 00:00.

Estas horas no permiten distinguir de forma fiable `DURING_CRT`,
`POST_CRT_PRE_ENTRY` o `TRADE_OPEN`.

## Criterio de aceptación para sustituirlo

El próximo calendario debe:

1. Cubrir como mínimo 31/07/2025–31/07/2026.
2. Incluir fecha y hora exactas con zona u offset.
3. Conservar país/divisa, impacto y nombre del evento.
4. Validar muestras conocidas: NFP/CPI 08:30 New York, ISM 10:00 New York y
   FOMC 14:00 New York.
5. Mantener `actual`, `forecast` y `previous` cuando estén disponibles.

Hasta cumplir estos puntos, el baseline CRT 3H permanece sin filtro macro.
