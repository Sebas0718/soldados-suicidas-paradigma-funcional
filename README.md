# Caída amortiguada de un paracaidista: paradigma funcional

Proyecto programado 1 de IC4700 Lenguajes de Programación (II semestre 2026), resuelto en el
**paradigma funcional** con **Haskell** y **Scheme** (Guile).

Se modela la caída de un paracaidista con resistencia del aire proporcional a la velocidad y
se resuelve con el método de **Runge-Kutta de cuarto orden**. El programa calcula:

1. la velocidad del paracaidista en el tiempo,
2. la distancia recorrida en el tiempo,
3. la constante de resistencia β del paracaídas que permite aterrizar a unos 8 km/h.

> 🚧 Proyecto en construcción. Este README se completa en la última etapa.

## Estructura

```
haskell/   versión en Haskell
scheme/    versión en Scheme (Guile)
docs/      especificación técnica y diseño funcional
Makefile   atajos para compilar, ejecutar y probar
```

## Requisitos

- **GHC** (Haskell): `sudo pacman -S ghc`
- **Guile 3** (Scheme): `sudo pacman -S guile`
