# SESSION_RANGE_MADRID — reglas congeladas

Todos los horarios están expresados en `Europe/Madrid`, incluyendo los
cambios CET/CEST. La estrategia reutiliza el mismo motor de sweep, retorno,
ejecución, riesgo y salida de `CRT_3H_MADRID`; sólo cambia el rango de
referencia.

## Londres

- Rango Asia: 00:00–09:00.
- Ventana de setup y entrada: 09:00–11:00.
- Máximo una operación.
- El setup queda etiquetado con `reference_range = ASIA`.

## Nueva York

- Rango Asia: 00:00–09:00.
- Rango Londres: 09:00–15:00.
- Ambos rangos se evalúan por separado entre 15:00 y 17:00.
- Máximo una operación: se conserva el primer fill válido.
- Si ambos fills se producen en el mismo minuto, prevalece el orden estable
  `ASIA`, `LONDRES`.
- El trade queda etiquetado como `ASIA` o `LONDRES` para compararlos.

## Reglas heredadas sin cambios

- Sweep mínimo: un tick más allá del máximo o mínimo del rango.
- La dirección la fija el primer lado barrido de cada rango.
- Entrada: 60 % del recorrido desde el extremo de manipulación hacia el
  extremo opuesto del rango.
- Stop: extremo de manipulación, redondeado al tick.
- Objetivo fijo predeterminado: 0,66R desde el fill real.
- Perfil intrabar conservador `STOP_FIRST` cuando stop y target coinciden en
  una misma vela.
- Se conservan los perfiles `IDEAL`, `REALISTIC` y `CONSERVATIVE`, las cuatro
  políticas Londres/NY y la opción de bloquear NY tras TP de Londres.

## Ejecución

Desde la carpeta `MATLAB`:

```matlab
quantlab
```

Selecciona `SESSION_RANGE_MADRID`, el instrumento y pulsa **Ejecutar y abrir
dashboard**. Los scripts específicos anteriores permanecen como wrappers de
compatibilidad.

Los informes se guardan bajo `MATLAB/Reports/SESSION_RANGE_MADRID` y no
sobrescriben los de `CRT_3H_MADRID`.
