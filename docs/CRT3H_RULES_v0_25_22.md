# Reglas congeladas CRT 3H — v0.25.22

Zona horaria: `Europe/Madrid` (CET/CEST según la fecha de cada barra).

## Ventanas

| Sesión | Rango CRT | Ventana de manipulación y entrada |
|---|---|---|
| Londres | 06:00–09:00 | 09:00–11:00 |
| Nueva York | 12:00–15:00 | 15:00–17:00 |

Los intervalos son semiabiertos: incluyen la hora inicial y excluyen la hora
final. Por ejemplo, la última barra elegible de Londres comienza a las 10:59.
El primer sweep válido dentro de cada ventana fija la dirección; ningún sweep
anterior a la apertura de la ventana conserva estado.

## Entrada, stop y salidas

- Entrada: retorno al 50 % entre el extremo de manipulación y el extremo CRT
  opuesto, manteniendo las reglas de fill y ejecución de la v0.25.21.
- Stop: extremo barrido, ajustado al tick del instrumento.
- Break-even: se mantiene la configuración existente, activada en `+1R` y
  efectiva desde la vela siguiente.
- `FIXED_TARGET`: objetivo fijo en `+1R`.
- `SWING_TRAILING_STEP_TARGET`: alternativa independiente; activación en
  `+1,5R`, escalones virtuales de `0,5R` y trailing por swing 2/2 con offset de
  un tick.

Las dos salidas se ejecutan como backtests separados. El cambio de TP fijo no
modifica los niveles ni la lógica de la variante trailing.
