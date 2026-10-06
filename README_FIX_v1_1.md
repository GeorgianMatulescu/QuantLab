# Corrección v1.1

- El descargador ya no consulta `reqHeadTimeStamp` antes de cada descarga.
- El timeout histórico se reduce de 900 a 45 segundos.
- Una petición sin respuesta se cancela y termina con un error claro.
- Los BAT ejecutan directamente `.venv\Scripts\python.exe` y no dependen de `activate.bat`.
- Se añade `scripts/03_probar_MNQ_1dia_RTH.bat`.
- Se desactiva la petición única de 4 años hasta comprobar primero que HMDS funciona.
