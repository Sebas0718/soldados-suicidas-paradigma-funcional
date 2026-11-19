;;; Método de Runge-Kutta de cuarto orden para sistemas de ecuaciones
;;; diferenciales de la forma y' = f(t, y).
;;;
;;; Este módulo no sabe nada de paracaidistas: recibe la función f como
;;; parámetro, así que sirve para cualquier sistema.
;;;
;;; Un vector es una lista de números, por ejemplo (x v).
;;; Un estado es una lista con el tiempo y el vector: (t (x v)).

(define-module (runge-kutta)
  #:export (sumar-vectores
            escalar-vector
            paso-rk4))

;; Suma dos vectores elemento por elemento.
(define (sumar-vectores a b)
  (map + a b))

;; Multiplica cada elemento de un vector por un número.
(define (escalar-vector c vector)
  (map (lambda (elemento) (* c elemento)) vector))

;; Avanza un paso de tamaño h, con la fórmula de [Burden85], p. 248:
;;
;;   k1 = h * f(t,       w)
;;   k2 = h * f(t + h/2, w + k1/2)
;;   k3 = h * f(t + h/2, w + k2/2)
;;   k4 = h * f(t + h,   w + k3)
;;   w' = w + (k1 + 2*k2 + 2*k3 + k4) / 6
(define (paso-rk4 f h estado)
  (let* ((t  (car estado))
         (w  (cadr estado))
         (k1 (escalar-vector h (f t w)))
         (k2 (escalar-vector h (f (+ t (/ h 2)) (sumar-vectores w (escalar-vector 0.5 k1)))))
         (k3 (escalar-vector h (f (+ t (/ h 2)) (sumar-vectores w (escalar-vector 0.5 k2)))))
         (k4 (escalar-vector h (f (+ t h) (sumar-vectores w k3))))
         (incremento (map (lambda (a b c d) (/ (+ a (* 2 b) (* 2 c) d) 6))
                          k1 k2 k3 k4)))
    (list (+ t h) (sumar-vectores w incremento))))
