# MNQ de 1 minuto: cuatro años completos

> Flujo opcional de pago, desactivado en v0.25.29. Para el flujo sin compra de
> histórico usa `07_descargar_MNQ_IBKR_CONTRATOS_2Y_ALL.bat` y consulta
> `IBKR_MNQ_FUTURES_CHAIN.md`.

IBKR no permite pedir cuatro años de barras de un minuto en una sola llamada.
Además, un contrato continuo de IBKR (`CONTFUT`) exige `endDateTime` vacío, por
lo que no se puede paginar hacia atrás de forma reproducible.

QuantLab usa Databento para este histórico y conserva IBKR para la conexión a
TWS/IB Gateway, pruebas cortas y operativa.

## 1. Preparación

1. Crea una cuenta en Databento y copia tu API key.
2. En una consola de Windows ejecuta:

   ```bat
   setx DATABENTO_API_KEY "TU_API_KEY"
   ```

3. Cierra y abre de nuevo la consola. No guardes la clave en `settings.yaml`.
4. Ejecuta `scripts\windows\01_instalar_dependencias.bat` para instalar también
   el cliente oficial de Databento.

## 2. Descarga segura

Ejecuta `scripts\windows\06_descargar_MNQ_4Y_ALL_CRT3H.bat`.

El script primero solicita una estimación gratuita. Después debes escribir el
coste máximo en USD que autorizas. QuantLab vuelve a comprobar la estimación y
cancela antes de descargar si supera ese límite.

El resultado sustituye de forma intencional:

```text
data\MNQ\1_min\MNQ_CONTFUT_1_min_ALL.csv
data\MNQ\1_min\MNQ_CONTFUT_1_min_ALL.sqlite
data\MNQ\1_min\MNQ_CONTFUT_1_min_ALL.metadata.json
data\MNQ\1_min\MNQ_CONTFUT_1_min_ALL.rolls.csv
```

## Convención congelada

- Dataset: `GLBX.MDP3` (CME Globex).
- Esquema: `ohlcv-1m`.
- Símbolo: `MNQ.v.0`.
- Roll: contrato con mayor volumen del día anterior.
- Precios: originales del mercado, sin back-adjustment.
- Horario: extendido; `use_rth=0`.
- Fin del periodo: exclusivo; por defecto hoy a las 00:00 UTC, para evitar un
  día actual incompleto.

El CSV conserva `instrument_id`, `continuous_symbol` y `local_symbol`. Este
último identifica el contrato trimestral real cuando la resolución histórica
de símbolos está disponible. El archivo `rolls.csv` resume cada tramo continuo,
su contrato, primera/última barra y número de barras.

No mezcles el CSV nuevo con barras antiguas de IBKR. La descarga reemplaza el
dataset completo para mantener una sola fuente y una única regla de roll.
