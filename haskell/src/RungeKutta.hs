-- | Método de Runge-Kutta de cuarto orden para sistemas de ecuaciones
-- diferenciales de la forma y' = f(t, y).
--
-- Este módulo no sabe nada de paracaidistas: recibe la función f como
-- parámetro, así que sirve para cualquier sistema.
module RungeKutta
  ( Vector
  , Estado
  , sumarVectores
  , escalarVector
  , pasoRK4
  ) where

import Data.List (zipWith4)

-- | Un vector de valores, por ejemplo [x, v].
type Vector = [Double]

-- | Un estado es el tiempo y el vector de valores en ese tiempo: (t, w).
type Estado = (Double, Vector)

-- | Suma dos vectores elemento por elemento.
sumarVectores :: Vector -> Vector -> Vector
sumarVectores = zipWith (+)

-- | Multiplica cada elemento de un vector por un número.
escalarVector :: Double -> Vector -> Vector
escalarVector c = map (c *)

-- | Avanza un paso de tamaño h, con la fórmula de [Burden85], p. 248:
--
-- >  k1 = h * f(t,       w)
-- >  k2 = h * f(t + h/2, w + k1/2)
-- >  k3 = h * f(t + h/2, w + k2/2)
-- >  k4 = h * f(t + h,   w + k3)
-- >  w' = w + (k1 + 2*k2 + 2*k3 + k4) / 6
pasoRK4 :: (Double -> Vector -> Vector) -> Double -> Estado -> Estado
pasoRK4 f h (t, w) = (t + h, sumarVectores w incremento)
  where
    k1 = escalarVector h (f t w)
    k2 = escalarVector h (f (t + h / 2) (sumarVectores w (escalarVector 0.5 k1)))
    k3 = escalarVector h (f (t + h / 2) (sumarVectores w (escalarVector 0.5 k2)))
    k4 = escalarVector h (f (t + h) (sumarVectores w k3))
    incremento = zipWith4 (\a b c d -> (a + 2 * b + 2 * c + d) / 6) k1 k2 k3 k4
