-- | Pruebas de la versión en Haskell.
--
-- No usa bibliotecas externas: cada prueba es un nombre y un valor Bool.
-- Se ejecuta con:  make test-haskell
module Main (main) where

import System.Exit (exitFailure, exitSuccess)

import Fisica
import RungeKutta

-- | Una prueba: su nombre y si se cumplió.
type Prueba = (String, Bool)

-- | ¿Son dos números iguales con una tolerancia dada?
casiIgual :: Double -> Double -> Double -> Bool
casiIgual tolerancia esperado obtenido = abs (esperado - obtenido) < tolerancia

-- | Datos del caso del enunciado: 80 kg + 50 kg.
pesoEnunciado :: Double
pesoEnunciado = pesoTotal 80 50

-- | Estado después de n pasos de Runge-Kutta con h = 0.05, partiendo del reposo.
estadoTrasPasos :: Int -> Double -> Double -> Estado
estadoTrasPasos n beta peso =
  iterate (pasoRK4 (derivadas beta peso) 0.05) (0, [0, 0]) !! n

-- | Compara Runge-Kutta con la solución exacta a los 20 s (400 pasos).
coincideConExacta :: Double -> Double -> Bool
coincideConExacta beta tolerancia =
  casiIgual tolerancia (velocidadExacta beta pesoEnunciado t) v
    && casiIgual tolerancia (distanciaExacta beta pesoEnunciado t) x
  where
    (t, w) = estadoTrasPasos 400 beta pesoEnunciado
    x = w !! 0
    v = w !! 1

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

-- | Imprime el resultado de una prueba.
mostrarPrueba :: Prueba -> IO ()
mostrarPrueba (nombre, paso) =
  putStrLn ((if paso then "[OK]    " else "[FALLA] ") ++ nombre)

main :: IO ()
main = do
  let pruebas = pruebasFisica ++ pruebasRungeKutta
      fallidas = length (filter (not . snd) pruebas)
  mapM_ mostrarPrueba pruebas
  putStrLn ""
  putStrLn (show (length pruebas - fallidas) ++ " de " ++ show (length pruebas) ++ " pruebas pasaron.")
  if fallidas == 0 then exitSuccess else exitFailure
