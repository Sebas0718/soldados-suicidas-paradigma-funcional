-- | Programa principal: pide los datos al usuario, busca la constante beta
-- y muestra los resultados.
--
-- Es el único módulo que hace entrada/salida. Los cálculos están en los
-- módulos Fisica, RungeKutta y Simulacion.
module Main (main) where

import Data.Char (isSpace)
import System.Exit (die)
import System.IO (hFlush, hSetEncoding, isEOF, stdout, utf8)
import Text.Printf (printf)

import Fisica
import RungeKutta (Estado)
import Simulacion

-- | Tiempos (s) en los que se muestra una fila de la tabla. Hay varios en el
-- primer segundo, donde la velocidad cambia rápido, y luego cada vez más
-- separados, porque la velocidad ya casi no cambia.
tiemposMuestra :: [Double]
tiemposMuestra =
  [0, 0.1, 0.2, 0.5, 1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000]

-- | Convierte un texto en un número mayor que 0, si se puede.
-- Ejemplos: "80" -> Just 80.0 ; "-3" -> Nothing ; "abc" -> Nothing
-- También rechaza "Infinity": con una altura infinita nunca se llegaría al suelo.
interpretarPositivo :: String -> Maybe Double
interpretarPositivo texto =
  case reads texto of
    [(numero, resto)]
      | all isSpace resto && numero > 0 && not (isInfinite numero) -> Just numero
    _ -> Nothing

-- | Muestra un mensaje y lee un número mayor que 0.
-- Si el dato no es válido, avisa y lo vuelve a pedir.
leerPositivo :: String -> IO Double
leerPositivo mensaje = do
  putStr mensaje
  hFlush stdout
  sinDatos <- isEOF
  if sinDatos
    then die "\nNo hay más datos de entrada."
    else do
      linea <- getLine
      case interpretarPositivo linea of
        Just numero -> return numero
        Nothing -> do
          putStrLn "  Dato inválido: escriba un número mayor que 0."
          leerPositivo mensaje

-- | Líneas con el resumen de resultados.
resumen :: Double -> Double -> Double -> [String]
resumen peso altura beta =
  [ ""
  , "RESULTADOS"
  , printf "  Peso total W .................. %.3f N" peso
  , printf "  Constante beta encontrada ..... %.3f kg/s" beta
  , printf "  Tiempo de caída ............... %.2f s" (tiempo final)
  , printf "  Velocidad de aterrizaje ....... %.4f m/s (%.2f km/h)"
      (velocidad final) (msAKmh (velocidad final))
  , printf "  Velocidad límite W/beta ....... %.4f m/s" (peso / beta)
  ]
  where
    final = aterrizaje beta peso altura

-- | Una fila de la tabla: tiempo, velocidad y distancia por Runge-Kutta y exactas.
filaTabla :: Double -> Double -> Estado -> String
filaTabla peso beta estado =
  printf "%10.2f %13.4f %13.4f %12.3f %12.3f"
    t (velocidad estado) (velocidadExacta beta peso t)
    (distancia estado) (distanciaExacta beta peso t)
  where
    t = tiempo estado

-- | Líneas de la tabla: una fila por cada tiempo de muestra anterior al
-- aterrizaje, y al final la fila del aterrizaje.
tabla :: Double -> Double -> Double -> [String]
tabla peso altura beta =
  [ ""
  , "VELOCIDAD Y DISTANCIA EN EL TIEMPO (Runge-Kutta vs. solución exacta)"
  , "     t (s)   v RK4 (m/s) v exacta(m/s)    x RK4 (m) x exacta (m)"
  ]
    ++ map (filaTabla peso beta) estadosMuestra
    ++ [filaTabla peso beta final ++ "  <- aterrizaje"]
  where
    final = aterrizaje beta peso altura
    tiempos = takeWhile (< tiempo final) tiemposMuestra
    estadosMuestra = map (estadoEnTiempo beta peso) tiempos

main :: IO ()
main = do
  hSetEncoding stdout utf8
  putStrLn "=================================================="
  putStrLn "  Caída amortiguada de un paracaidista (Haskell)"
  putStrLn "=================================================="
  masaParacaidista <- leerPositivo "Peso del paracaidista (kg): "
  masaEquipo <- leerPositivo "Peso del equipo (kg): "
  altura <- leerPositivo "Altura del salto (m): "

  let peso = pesoTotal masaParacaidista masaEquipo
      beta = buscarBeta peso altura velocidadObjetivo

  printf "\nBuscando beta para aterrizar a %.0f km/h...\n" (msAKmh velocidadObjetivo)
  mapM_ putStrLn (resumen peso altura beta)
  mapM_ putStrLn (tabla peso altura beta)
