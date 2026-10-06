# CRT 3H — entrada 0,75 y target 0,5R

## Versión congelada

Identificador: `CRT3H_ENTRY_075_RR_050`.

Esta versión cambia dos parámetros respecto al baseline 0,50/1R y no altera
el resto de las reglas de sesión, sweep, dirección, stop, sizing o costes:

- `entryFraction = 0.75`;
- `rewardRisk = 0.5` para la gestión `FIXED_TARGET`.

El baseline anterior permanece en la v0.25.28 y puede reproducirse asignando
`entryFraction = 0.50` y `rewardRisk = 1.0`.

## Geometría

La fracción se mide desde el extremo de la manipulación hacia el extremo
opuesto del CRT.

Para un largo tras barrer el mínimo:

```text
Entrada = extremo + 0,75 × (máximo CRT − extremo)
Stop = extremo barrido
Target = fill + 0,5 × (fill − stop)
```

Para un corto tras barrer el máximo:

```text
Entrada = extremo − 0,75 × (extremo − mínimo CRT)
Stop = extremo barrido
Target = fill − 0,5 × (stop − fill)
```

Todos los niveles se redondean de forma conservadora al tick del activo. Si
no existe gap o slippage, el target queda aproximadamente un 12,5 % del
recorrido total más allá del extremo opuesto del CRT. Ese comportamiento es
deliberado: no debe reinterpretarse el target como el extremo opuesto.

## Ejemplo largo

Con extremo barrido en 98 y máximo CRT en 110:

- nivel 50 % anterior: 104;
- nueva entrada 75 %: 107;
- stop: 98;
- riesgo: 9 puntos;
- target 0,5R: 111,5;
- extensión sobre el máximo CRT: 1,5 puntos.

## Auditoría

Cada fila guarda:

- `rules_version`;
- `entry_fraction`;
- `entry_level`;
- `entry_level_50`, solo como referencia histórica;
- `reward_risk_planned`;
- stop, target, fill y resultado neto en R.

Los perfiles `IDEAL`, `REALISTIC` y `CONSERVATIVE` se mantienen separados.
La comparación multi-activo continúa recortando MNQ, MES y MYM al mismo
intervalo temporal.
