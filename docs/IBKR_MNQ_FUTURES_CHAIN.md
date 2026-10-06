# MNQ continuo sin coste externo: contratos IBKR

QuantLab v0.25.32 deja de depender del `CONTFUT` opaco para el histórico de
trabajo. Descarga los futuros trimestrales reales desde IBKR y construye una
serie continua auditable.

La búsqueda comienza por el contrato más reciente y retrocede trimestre a
trimestre. Cuando IBKR deja de resolver un vencimiento antiguo, QuantLab se
detiene en ese punto y continúa con todos los contratos consecutivos que sí
están disponibles. El tramo anterior se registra como cobertura parcial.

## Ejecución

1. Abre TWS o IB Gateway y espera a que esté conectado.
2. Comprueba que la API está habilitada.
3. Ejecuta `scripts\windows\01_instalar_dependencias.bat` si todavía no existe
   `Python\.venv`.
4. Ejecuta `scripts\windows\07_descargar_MNQ_IBKR_CONTRATOS_2Y_ALL.bat`.
5. Escribe `SI` cuando el script solicite confirmación.

No se usa Databento y QuantLab no compra histórico. El acceso efectivo depende
de los permisos de mercado que ya tenga la cuenta IBKR.

## Regla congelada de rollover

- Contratos trimestrales: H, M, U y Z.
- Ventana: 45 días naturales antes del vencimiento del contrato saliente.
- Gatillo: primer día de la ventana en el que el volumen diario del contrato
  entrante supera al del saliente.
- Efectividad: apertura Globex de la sesión siguiente, a las 18:00 de Nueva
  York del día natural anterior.
- Ajuste: ninguno. Se conservan precios reales y el tick de 0,25 puntos.
- Fallo seguro: si no existe cruce de volumen verificable, no se construye la
  cadena ni se sustituye el dataset activo.

## Reanudación

Cada bloque diario terminado de horario extendido se guarda en:

`data\MNQ\1_min\MNQ_FUT_CHAIN_1_min_ALL_v2.cache.sqlite`

La caché `ALL` está separada de `RTH`, de modo que una descarga anterior de
horario regular no puede bloquear la recuperación de las barras nocturnas.
Las respuestas vacías o parciales inesperadas se reintentan y nunca quedan
marcadas como completadas. Las cachés antiguas sin sufijo y `ALL` se ignoran
deliberadamente.

Si TWS se cierra, se pierde la conexión o Windows se reinicia, vuelve a
ejecutar el archivo `07`. QuantLab omite los bloques terminados y continúa.
El CSV activo solo se reemplaza después de completar y validar toda la cadena.

Después de terminar, abre MATLAB y ejecuta `audit_ibkr_session_data`. El
informe debe mostrar 180 barras de referencia y 120 de manipulación en las
sesiones ordinarias de Londres y Nueva York.

## Archivos finales

- `MNQ_CONTFUT_1_min_ALL.csv`: serie compatible con MATLAB.
- `MNQ_CONTFUT_1_min_ALL.sqlite`: misma serie en SQLite.
- `MNQ_CONTFUT_1_min_ALL.metadata.json`: parámetros y auditoría.
- `MNQ_CONTFUT_1_min_ALL.rolls.csv`: contrato y frontera de cada segmento.
- `MNQ_CONTFUT_1_min_ALL.contract_volume.csv`: volumen diario usado.
- `MNQ_CONTFUT_1_min_ALL.quality.csv`: control por contrato.

IBKR limita la disponibilidad de contratos vencidos. El periodo real puede ser
menor que dos años si la cuenta no tiene disponible alguno de los primeros
vencimientos.
