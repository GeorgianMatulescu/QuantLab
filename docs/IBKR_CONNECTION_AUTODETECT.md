# Detección automática de IB Gateway y TWS

QuantLab v0.25.32 conserva el puerto configurado en
`Python/Config/settings.yaml` como primera opción. Si no responde, prueba las
conexiones locales estándar:

| Aplicación | Entorno | Puerto |
|---|---|---:|
| IB Gateway | LIVE | 4001 |
| IB Gateway | PAPER | 4002 |
| TWS | LIVE | 7496 |
| TWS | PAPER | 7497 |

La selección ocurre únicamente en memoria: QuantLab no reescribe
`settings.yaml`. Cada puerto se prueba directamente con el protocolo de la API
de IBKR y solo se acepta después de completar su saludo. No se realiza una
conexión TCP preliminar, porque podría activar una solicitud de autorización en
Gateway antes de que exista un cliente API válido.

Si hay más de una aplicación disponible, tiene prioridad el puerto declarado
en `settings.yaml`. Esto evita cambiar silenciosamente entre LIVE y PAPER.

Configuración recomendada:

```yaml
ibkr:
  host: 127.0.0.1
  port: 4001
  client_id: 12
  auto_detect: true
  auto_detect_ports: [4001, 4002, 7496, 7497]
  connect_timeout_seconds: 20
```

Para volver al comportamiento rígido anterior:

```yaml
ibkr:
  auto_detect: false
```

El log indica la selección antes de resolver o descargar el contrato, por
ejemplo:

```text
API detectada: IB Gateway LIVE en 127.0.0.1:4001 (clientId=12).
```
