# Datos descargados de QuantLab v0.25.37

Este snapshot procede de QuantLab(3).zip. Conserva CSV, SQLite, cachés de
descarga, metadatos y auditorías de MES, MNQ y MYM en sus rutas originales.
Los CSV de MES y MYM pueden usarse directamente tras clonar el repositorio.

Los archivos de más de 25 MB se guardan como .gz, comprimidos sin pérdida:
MNQ_CONTFUT_1_min_ALL.csv, MNQ_CONTFUT_1_min_ALL.sqlite y
MNQ_FUT_CHAIN_1_min_ALL_v2.cache.sqlite. Para restaurarlos y
verificar los hashes del snapshot, desde la raíz del repositorio ejecuta:

```sh
python scripts/python/restore_downloaded_data.py
```

Requiere Python 3.11 o posterior. El script conserva cualquier archivo existente;
si sus datos difieren del snapshot, lo informa sin sustituirlos.

Las cachés del descargador de futuros permiten reanudar descargas. Sin embargo,
DatabaseWriter.write regenera los CSV y reemplaza la tabla bars de SQLite al
guardar el resultado. Los archivos finales no son exclusivamente acumulativos.
Git conserva este snapshot en el historial aunque una descarga local lo cambie.

No se incluyen entornos virtuales, paquetes instalados, logs ni configuración local.
