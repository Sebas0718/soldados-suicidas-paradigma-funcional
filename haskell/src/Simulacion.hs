-- | Simulación de la caída con Runge-Kutta y búsqueda de la constante beta.
--
-- Une el modelo físico (Fisica) con el método numérico (RungeKutta).
-- Todas son funciones puras.
module Simulacion
  ( pasoTiempo
  , toleranciaBeta
  , estadoInicial
  , tiempo
  , distancia
  , velocidad
  , trayectoria
  , aterrizaje
  , velocidadAterrizaje
  , estadoEnTiempo
  , acotarBeta
  , biseccion
  , buscarBeta
  ) where

import Fisica (derivadas)
import RungeKutta (Estado, pasoRK4)

-- | Paso de tiempo h de Runge-Kutta (s).
pasoTiempo :: Double
pasoTiempo = 0.05

-- | La búsqueda de beta termina cuando el intervalo mide menos que esto (kg/s).
toleranciaBeta :: Double
toleranciaBeta = 1e-6

-- | Al inicio (t = 0) el paracaidista está en reposo: x = 0, v = 0.
estadoInicial :: Estado
estadoInicial = (0, [0, 0])

-- | Tiempo de un estado (s).
tiempo :: Estado -> Double
tiempo (t, _) = t

-- | Distancia recorrida en un estado (m).
distancia :: Estado -> Double
distancia (_, w) = head w

-- | Velocidad en un estado (m/s).
velocidad :: Estado -> Double
velocidad (_, w) = w !! 1

-- | Todos los estados de la caída, uno por cada paso de tiempo.
-- Es una lista infinita: Haskell solo calcula los estados que se usan.
trayectoria :: Double -> Double -> [Estado]
trayectoria beta peso =
  iterate (pasoRK4 (derivadas beta peso) pasoTiempo) estadoInicial

-- | Primer estado en que la distancia recorrida alcanza la altura del salto.
aterrizaje :: Double -> Double -> Double -> Estado
aterrizaje beta peso altura =
  head (dropWhile noHaLlegado (trayectoria beta peso))
  where
    noHaLlegado estado = distancia estado < altura

-- | Velocidad con la que el paracaidista llega al suelo (m/s).
velocidadAterrizaje :: Double -> Double -> Double -> Double
velocidadAterrizaje beta peso altura = velocidad (aterrizaje beta peso altura)

-- | Estado de la caída en el tiempo t (el paso más cercano a t).
estadoEnTiempo :: Double -> Double -> Double -> Estado
estadoEnTiempo beta peso t =
  trayectoria beta peso !! round (t / pasoTiempo)

-- | Fase 1 de la búsqueda: duplica beta hasta que el paracaidista aterrice
-- a la velocidad objetivo o más lento. Devuelve ese beta (un límite superior).
acotarBeta :: Double -> Double -> Double -> Double -> Double
acotarBeta peso altura vObjetivo beta
  | velocidadAterrizaje beta peso altura <= vObjetivo = beta
  | otherwise = acotarBeta peso altura vObjetivo (2 * beta)

-- | Fase 2 de la búsqueda: parte el intervalo [betaMin, betaMax] a la mitad
-- hasta que mida menos que la tolerancia.
--
-- Devuelve betaMax porque siempre cumple: aterriza a vObjetivo o más lento.
biseccion :: Double -> Double -> Double -> Double -> Double -> Double
biseccion peso altura vObjetivo betaMin betaMax
  | betaMax - betaMin < toleranciaBeta = betaMax
  | velocidadAterrizaje betaMedio peso altura > vObjetivo =
      biseccion peso altura vObjetivo betaMedio betaMax -- frena poco: beta más grande
  | otherwise =
      biseccion peso altura vObjetivo betaMin betaMedio -- frena de más: beta más chico
  where
    betaMedio = (betaMin + betaMax) / 2

-- | Encuentra la constante beta (kg/s) con la que un peso W, saltando desde
-- una altura dada, llega al suelo a la velocidad objetivo.
buscarBeta :: Double -> Double -> Double -> Double
buscarBeta peso altura vObjetivo =
  biseccion peso altura vObjetivo 0 betaMax
  where
    betaMax = acotarBeta peso altura vObjetivo 1
