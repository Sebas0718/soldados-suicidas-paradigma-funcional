-- | Pruebas de la versión en Haskell.
--
-- No usa bibliotecas externas: cada prueba es un nombre y un valor Bool.
-- Se ejecuta con:  make test-haskell
module Main (main) where

import System.Exit (exitFailure, exitSuccess)

import Fisica
import RungeKutta
import Simulacion

-- | Una prueba: su nombre y si se cumplió.
type Prueba = (String, Bool)

-- | ¿Son dos números iguales con una tolerancia dada?
casiIgual :: Double -> Double -> Double -> Bool
casiIgual tolerancia esperado obtenido = abs (esperado - obtenido) < tolerancia

-- | Datos del caso del enunciado: 80 kg + 50 kg.
pesoEnunciado :: Double
pesoEnunciado = pesoTotal 80 50

-- | Compara Runge-Kutta con la solución exacta a los 20 s.
coincideConExacta :: Double -> Double -> Bool
coincideConExacta beta tolerancia =
  casiIgual tolerancia (velocidadExacta beta pesoEnunciado t) (velocidad estado)
    && casiIgual tolerancia (distanciaExacta beta pesoEnunciado t) (distancia estado)
  where
    estado = estadoEnTiempo beta pesoEnunciado 20
    t = tiempo estado

-- | Beta encontrado para el caso del enunciado (80 kg + 50 kg desde 1500 m).
-- Se calcula una sola vez y lo comparten varias pruebas.
betaEnunciado :: Double
betaEnunciado = buscarBeta pesoEnunciado 1500 velocidadObjetivo

pruebasFisica :: [Prueba]
pruebasFisica =
  [ ("pesoTotal 80 50 = 1275.3 N", casiIgual 1e-9 1275.3 pesoEnunciado)
  , ("8 km/h = 2.2222 m/s", casiIgual 1e-4 2.2222 (kmhAMs 8))
  , ("msAKmh deshace kmhAMs", casiIgual 1e-12 8 (msAKmh (kmhAMs 8)))
  , ("en reposo solo actúa la gravedad", derivadas 500 pesoEnunciado 0 [0, 0] == [0, gravedad])
  , ("a velocidad límite W/beta la aceleración es 0",
      casiIgual 1e-9 0 (derivadas 500 pesoEnunciado 0 [0, pesoEnunciado / 500] !! 1))
  , ("velocidad exacta en t = 0 es 0", casiIgual 1e-12 0 (velocidadExacta 500 pesoEnunciado 0))
  , ("distancia exacta en t = 0 es 0", casiIgual 1e-9 0 (distanciaExacta 500 pesoEnunciado 0))
  , ("velocidad exacta tiende a W/beta",
      casiIgual 1e-9 (pesoEnunciado / 500) (velocidadExacta 500 pesoEnunciado 100))
  ]

pruebasRungeKutta :: [Prueba]
pruebasRungeKutta =
  [ ("sumarVectores", sumarVectores [1, 2] [3, 4] == [4, 6])
  , ("escalarVector", escalarVector 2 [1, 2] == [2, 4])
  , ("pasoRK4 avanza el tiempo en h", fst (pasoRK4 (\_ w -> w) 0.1 (0, [1])) == 0.1)
    -- Con y' = y, y(0) = 1 y h = 0.1, un paso de RK4 da 1.1051708333...
    -- (el valor exacto es e^0.1 = 1.1051709180...).
  , ("pasoRK4 con y' = y da el valor conocido",
      casiIgual 1e-12 1.1051708333333333 (head (snd (pasoRK4 (\_ w -> w) 0.1 (0, [1])))))
  , ("RK4 = solución exacta con beta = 10 (error < 1e-6)", coincideConExacta 10 1e-6)
  , ("RK4 = solución exacta con beta = 574 (error < 1e-4)", coincideConExacta 574 1e-4)
  ]

pruebasSimulacion :: [Prueba]
pruebasSimulacion =
  [ ("la trayectoria empieza en reposo", head (trayectoria 500 pesoEnunciado) == estadoInicial)
  , ("cada paso avanza h segundos",
      casiIgual 1e-12 pasoTiempo (tiempo (trayectoria 500 pesoEnunciado !! 1)))
  , ("estadoEnTiempo 10 está en t = 10", casiIgual 1e-9 10 (tiempo (estadoEnTiempo 500 pesoEnunciado 10)))
  , ("la distancia nunca disminuye", siempreCrece (map distancia (take 1000 (trayectoria 500 pesoEnunciado))))
  , ("al aterrizar ya se recorrió la altura, sin pasarse más de un paso",
      let x = distancia (aterrizaje 500 pesoEnunciado 1500)
       in x >= 1500 && x < 1501)
  , ("más beta, aterrizaje más lento",
      velocidadAterrizaje 100 pesoEnunciado 1500 > velocidadAterrizaje 500 pesoEnunciado 1500)
  , ("acotarBeta da un beta que ya frena lo suficiente",
      velocidadAterrizaje (acotarBeta pesoEnunciado 1500 velocidadObjetivo 1) pesoEnunciado 1500
        <= velocidadObjetivo)
  , ("beta del enunciado = 573.885 kg/s", casiIgual 0.01 573.885 betaEnunciado)
  , ("con ese beta se aterriza a 8 km/h",
      casiIgual 0.01 8 (msAKmh (velocidadAterrizaje betaEnunciado pesoEnunciado 1500)))
  , ("otro caso (60 + 20 kg desde 800 m) también aterriza a 8 km/h",
      let peso = pesoTotal 60 20
          beta = buscarBeta peso 800 velocidadObjetivo
       in casiIgual 0.01 8 (msAKmh (velocidadAterrizaje beta peso 800)))
  , ("altura muy baja (0.1 m): casi no hace falta frenar",
      buscarBeta pesoEnunciado 0.1 velocidadObjetivo < 1)
  ]

-- | ¿Cada número es mayor o igual que el anterior?
siempreCrece :: [Double] -> Bool
siempreCrece xs = and (zipWith (<=) xs (drop 1 xs))

-- | Imprime el resultado de una prueba.
mostrarPrueba :: Prueba -> IO ()
mostrarPrueba (nombre, paso) =
  putStrLn ((if paso then "[OK]    " else "[FALLA] ") ++ nombre)

main :: IO ()
main = do
  let pruebas = pruebasFisica ++ pruebasRungeKutta ++ pruebasSimulacion
      fallidas = length (filter (not . snd) pruebas)
  mapM_ mostrarPrueba pruebas
  putStrLn ""
  putStrLn (show (length pruebas - fallidas) ++ " de " ++ show (length pruebas) ++ " pruebas pasaron.")
  if fallidas == 0 then exitSuccess else exitFailure
