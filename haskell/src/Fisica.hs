-- | Modelo físico de la caída amortiguada de un paracaidista.
--
-- Contiene las constantes, las conversiones de unidades, las ecuaciones del
-- sistema y la solución exacta (analítica). Todas son funciones puras.
--
-- Unidades: segundos, metros, m/s, newtons. La constante beta está en kg/s.
module Fisica
  ( gravedad
  , pesoTotal
  , kmhAMs
  , msAKmh
  , velocidadObjetivo
  , derivadas
  , velocidadExacta
  , distanciaExacta
  ) where

-- | Aceleración de la gravedad (m/s²).
gravedad :: Double
gravedad = 9.81

-- | Peso total W (en newtons) a partir de las masas en kg del paracaidista
-- y de su equipo: W = (m_paracaidista + m_equipo) * g.
pesoTotal :: Double -> Double -> Double
pesoTotal masaParacaidista masaEquipo = (masaParacaidista + masaEquipo) * gravedad

-- | Convierte km/h a m/s.
kmhAMs :: Double -> Double
kmhAMs kmh = kmh / 3.6

-- | Convierte m/s a km/h.
msAKmh :: Double -> Double
msAKmh ms = ms * 3.6

-- | Velocidad de aterrizaje deseada: 8 km/h, expresada en m/s.
velocidadObjetivo :: Double
velocidadObjetivo = kmhAMs 8

-- | La función f(t, y) del sistema de ecuaciones, con y = [x, v]:
--
-- >  dx/dt = v
-- >  dv/dt = g - (beta * g / W) * v
--
-- El tiempo no aparece en las ecuaciones, pero se recibe igual porque
-- Runge-Kutta trabaja con funciones de la forma f(t, y).
derivadas :: Double -> Double -> Double -> [Double] -> [Double]
derivadas beta peso _tiempo [_distancia, velocidad] =
  [velocidad, gravedad - beta * gravedad * velocidad / peso]
derivadas _ _ _ estado =
  error ("derivadas: se esperaba [x, v] y se recibió " ++ show estado)

-- | Solución exacta de la velocidad: v(t) = (W/beta) * (1 - e^(-beta*g*t/W)).
velocidadExacta :: Double -> Double -> Double -> Double
velocidadExacta beta peso tiempo =
  (peso / beta) * (1 - exp (-beta * gravedad * tiempo / peso))

-- | Solución exacta de la distancia recorrida:
-- x(t) = (W/beta)*t + (W²/(beta²*g)) * e^(-beta*g*t/W) - W²/(beta²*g).
distanciaExacta :: Double -> Double -> Double -> Double
distanciaExacta beta peso tiempo =
  (peso / beta) * tiempo + c * exp (-beta * gravedad * tiempo / peso) - c
  where
    c = peso ^ (2 :: Int) / (beta ^ (2 :: Int) * gravedad)
