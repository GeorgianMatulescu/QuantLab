# Lanzador universal de QuantLab

## Uso visual

Desde la carpeta `MATLAB`, ejecuta:

```matlab
quantlab
```

El selector descubre los plugins instalados en `MATLAB/Strategies` y permite:

1. elegir una estrategia disponible y uno o varios instrumentos;
2. ejecutar el backtest, guardar la auditoría y abrir el dashboard;
3. abrir el último resultado guardado sin recalcular el histórico.

Por cada instrumento se ejecuta y guarda un backtest independiente. Si hay
varios seleccionados, se abre un dashboard completo por activo. Un error por
datos ausentes no elimina las ejecuciones correctas de los demás activos.

## Uso programático

El mismo flujo se puede automatizar sin abrir el selector:

```matlab
runQuantLabWorkflow("SESSION_RANGE_MADRID","MNQ")
```

Para varios instrumentos:

```matlab
runQuantLabBatch("SESSION_RANGE_MADRID",["MNQ","MES","MYM"])
```

Opciones disponibles:

```matlab
runQuantLabWorkflow("CRT_3H_MADRID","MNQ", ...
    RunBacktest=true, ...
    ExportResults=true, ...
    OpenDashboard=true)
```

Para abrir la última auditoría sin recalcular:

```matlab
runQuantLabWorkflow("SESSION_RANGE_MADRID","MNQ", ...
    RunBacktest=false, ...
    ExportResults=false, ...
    OpenDashboard=true)
```

## Compatibilidad

`main`, `launch_dashboard`, `run_session_range` y
`launch_session_range_dashboard` siguen disponibles, pero ahora sólo llaman al
flujo común. Las estrategias futuras no necesitan nuevos scripts: basta con
instalar correctamente su plugin.

Los resultados se separan en
`MATLAB/Reports/<ESTRATEGIA>/<INSTRUMENTO>` para evitar que un activo
sobrescriba la auditoría de otro.
