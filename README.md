# Caída amortiguada de un paracaidista: paradigma funcional

Proyecto programado 1 de **IC4700 Lenguajes de Programación** (II semestre 2026), resuelto en
el **paradigma funcional** con **Haskell** y **Scheme** (Guile).

Un paracaidista salta desde el reposo con el paracaídas abierto. El aire lo frena con una
fuerza proporcional a su velocidad (`R = β·v`). El programa resuelve la ecuación diferencial
del movimiento con el método de **Runge-Kutta de cuarto orden** y calcula:

1. la **velocidad** del paracaidista en el tiempo,
2. la **distancia** recorrida en el tiempo,
3. la **constante de resistencia β** del paracaídas que permite aterrizar a unos **8 km/h**.

## Resultado de la pregunta de investigación

> Una persona de 80 kg con 50 kg de equipo salta desde 1 500 m. ¿Qué β hace que llegue al
> suelo a unos 8 km/h?

| Resultado | Valor |
|---|---|
| **Constante β encontrada** | **573.885 kg/s** |
| Tiempo de caída | 675.25 s (≈ 11 min 15 s) |
| Velocidad de aterrizaje | 2.2222 m/s = 8.00 km/h |

β lo encuentra el programa **experimentalmente**: simula la caída completa con Runge-Kutta
para distintos valores de β y los ajusta por bisección hasta llegar a 8 km/h (41
simulaciones). El resultado coincide con la velocidad límite de la solución analítica,
`W/β = 8 km/h`. Tiene sentido: el paracaidista alcanza esa velocidad en menos de 2 segundos y
la mantiene el resto de la caída.

Las dos versiones (Haskell y Scheme) dan exactamente el mismo resultado.

## Requisitos

| Herramienta | Versión probada | Instalación en Arch Linux |
|---|---|---|
| GHC (Haskell) | 9.6.7 | `sudo pacman -S ghc` |
| Guile (Scheme) | 3.0.11 | `sudo pacman -S guile` |
| make | cualquiera | `sudo pacman -S make` |

No se usa ninguna biblioteca externa: solo lo que traen GHC y Guile.

> **Nota sobre GHC:** el paquete `ghc` de Arch trae solo bibliotecas dinámicas, por eso el
> `Makefile` compila con `-dynamic`. En otras distribuciones, si esa opción da problemas, se
> puede compilar sin ella: `make run-haskell GHC="ghc -O1 -Wall"`.

## Cómo ejecutarlo

```bash
make run-haskell     # compila y ejecuta la versión en Haskell
make run-scheme      # ejecuta la versión en Scheme
```

Sin `make`:

```bash
# Haskell
mkdir -p haskell/build
ghc -dynamic -ihaskell/src -outputdir haskell/build -o haskell/build/paracaidista haskell/src/Main.hs
./haskell/build/paracaidista

# Scheme
guile -L scheme scheme/main.scm
```

La primera vez que se ejecuta la versión en Scheme, Guile compila los módulos y muestra
mensajes `;;; compiling ...`. Es normal; en las siguientes ejecuciones ya no aparecen.

### Ejemplo de ejecución

El programa pide los tres datos (cualquier número mayor que 0; si se escribe algo inválido,
lo vuelve a pedir):

```
==================================================
  Caída amortiguada de un paracaidista (Haskell)
==================================================
Peso del paracaidista (kg): 80
Peso del equipo (kg): 50
Altura del salto (m): 1500

Buscando beta para aterrizar a 8 km/h...

RESULTADOS
  Peso total W .................. 1275.300 N
  Constante beta encontrada ..... 573.885 kg/s
  Tiempo de caída ............... 675.25 s
  Velocidad de aterrizaje ....... 2.2222 m/s (8.00 km/h)
  Velocidad límite W/beta ....... 2.2222 m/s

VELOCIDAD Y DISTANCIA EN EL TIEMPO (Runge-Kutta vs. solución exacta)
     t (s)   v RK4 (m/s) v exacta(m/s)    x RK4 (m) x exacta (m)
      0.00        0.0000        0.0000        0.000        0.000
      0.10        0.7931        0.7931        0.043        0.043
      0.20        1.3031        1.3032        0.149        0.149
      0.50        1.9778        1.9778        0.663        0.663
      1.00        2.1953        2.1953        1.725        1.725
      2.00        2.2219        2.2219        3.941        3.941
      5.00        2.2222        2.2222       10.608       10.608
     10.00        2.2222        2.2222       21.719       21.719
     20.00        2.2222        2.2222       43.941       43.941
     50.00        2.2222        2.2222      110.608      110.608
    100.00        2.2222        2.2222      221.719      221.719
    200.00        2.2222        2.2222      443.941      443.941
    500.00        2.2222        2.2222     1110.608     1110.608
    675.25        2.2222        2.2222     1500.052     1500.052  <- aterrizaje
```

La tabla compara los valores de Runge-Kutta con la solución exacta del enunciado: coinciden
hasta el tercer o cuarto decimal.

También se le pueden pasar los datos por tubería:

```bash
printf '80\n50\n1500\n' | ./haskell/build/paracaidista
printf '80\n50\n1500\n' | guile -L scheme scheme/main.scm
```

## Pruebas

```bash
make test            # las dos versiones
make test-haskell    # solo Haskell
make test-scheme     # solo Scheme (usa SRFI-64, incluida en Guile)
```

Cada versión tiene las mismas 25 pruebas, agrupadas en tres partes:

- **Física:** conversiones de unidades, ecuaciones y solución exacta.
- **Runge-Kutta:** un paso conocido (`y' = y`) y comparación con la solución exacta.
- **Simulación:** aterrizaje, búsqueda de β, el caso del enunciado y otros casos.

## Estructura del proyecto

```
.
├── README.md
├── Makefile                       atajos para compilar, ejecutar y probar
├── docs/
│   └── especificacion-tecnica.md  diseño funcional e implementación
├── haskell/
│   ├── src/
│   │   ├── Fisica.hs              constantes, ecuaciones y solución exacta
│   │   ├── RungeKutta.hs          un paso de RK4 para cualquier sistema
│   │   ├── Simulacion.hs          simular la caída y buscar β
│   │   └── Main.hs                entrada y salida
│   └── pruebas/
│       └── Pruebas.hs
└── scheme/
    ├── fisica.scm                 (mismos módulos que en Haskell)
    ├── runge-kutta.scm
    ├── simulacion.scm
    ├── main.scm
    └── pruebas.scm
```

Las dos versiones siguen el **mismo diseño**: los mismos módulos y las mismas funciones, con
los nombres adaptados a cada lenguaje (`pasoRK4` en Haskell, `paso-rk4` en Scheme).

## Cómo está hecho

- **Modelo:** el estado del paracaidista es el vector `[x, v]` (distancia y velocidad), y la
  ecuación se escribe como el sistema `dx/dt = v`, `dv/dt = g − (β·g/W)·v`.
- **Runge-Kutta:** la fórmula del enunciado aplicada a vectores, con paso `h = 0.05 s`. El
  módulo no conoce la física: recibe la ecuación como parámetro.
- **Simulación:** se avanza paso a paso desde el reposo hasta que la distancia recorrida
  alcanza la altura del salto.
- **Búsqueda de β:** se duplica β desde 1 hasta que el paracaidista aterrice a 8 km/h o más
  lento, y luego se ajusta por bisección hasta una precisión de 10⁻⁶ kg/s.

### Paradigma funcional

- **Funciones puras:** todos los cálculos son funciones sin efectos secundarios. Solo `Main`
  lee del teclado y escribe en pantalla.
- **Sin variables que cambian ni ciclos:** las repeticiones se hacen con recursión.
- **Funciones de orden superior:** Runge-Kutta recibe la ecuación como una función; se usan
  `map`, `zipWith`, `iterate`, `filter`.
- **Evaluación perezosa (Haskell):** la caída es una lista infinita de estados de la que solo
  se calculan los que se necesitan. En Scheme, que evalúa de forma estricta, se usa recursión
  de cola.

El detalle completo (modelo, diagrama de funciones, pseudocódigo y comparación entre los dos
lenguajes) está en [`docs/especificacion-tecnica.md`](docs/especificacion-tecnica.md).

## Referencias

- Spiegel, Murray. *Ecuaciones Diferenciales Aplicadas*. Prentice-Hall, 1983, pp. 76-78.
- Burden, Richard L.; Faires, J. Douglas. *Análisis Numérico*. Grupo Editorial
  Iberoamérica, 1985, p. 248.
