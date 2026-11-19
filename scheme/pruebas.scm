;;; Pruebas de la versión en Scheme, con SRFI-64 (incluida en Guile).
;;; Se ejecuta con:  make test-scheme

(use-modules (srfi srfi-64)
             (fisica)
             (runge-kutta))

;; Datos del caso del enunciado: 80 kg + 50 kg.
(define peso-enunciado (peso-total 80 50))

;; Estado después de n pasos de Runge-Kutta con h = 0.05, partiendo del reposo.
(define (estado-tras-pasos n beta peso)
  (let avanzar ((pasos-restantes n)
                (estado (list 0 (list 0 0))))
    (if (= pasos-restantes 0)
        estado
        (avanzar (- pasos-restantes 1)
                 (paso-rk4 (derivadas beta peso) 0.05 estado)))))

;; ¿Coincide Runge-Kutta con la solución exacta a los 20 s (400 pasos)?
(define (coincide-con-exacta? beta tolerancia)
  (let* ((estado (estado-tras-pasos 400 beta peso-enunciado))
         (t (car estado))
         (x (car (cadr estado)))
         (v (cadr (cadr estado))))
    (and (< (abs (- v (velocidad-exacta beta peso-enunciado t))) tolerancia)
         (< (abs (- x (distancia-exacta beta peso-enunciado t))) tolerancia))))

(test-begin "paracaidista")

(test-group "fisica"
  (test-approximate "peso-total 80 50 = 1275.3 N" 1275.3 peso-enunciado 1e-9)
  (test-approximate "8 km/h = 2.2222 m/s" 2.2222 (kmh-a-ms 8) 1e-4)
  (test-approximate "ms-a-kmh deshace kmh-a-ms" 8 (ms-a-kmh (kmh-a-ms 8)) 1e-12)
  (test-equal "en reposo solo actúa la gravedad"
    (list 0 gravedad)
    ((derivadas 500 peso-enunciado) 0 (list 0 0)))
  (test-approximate "a velocidad límite W/beta la aceleración es 0"
    0 (cadr ((derivadas 500 peso-enunciado) 0 (list 0 (/ peso-enunciado 500)))) 1e-9)
  (test-approximate "velocidad exacta en t = 0 es 0"
    0 (velocidad-exacta 500 peso-enunciado 0) 1e-12)
  (test-approximate "distancia exacta en t = 0 es 0"
    0 (distancia-exacta 500 peso-enunciado 0) 1e-9)
  (test-approximate "velocidad exacta tiende a W/beta"
    (/ peso-enunciado 500) (velocidad-exacta 500 peso-enunciado 100) 1e-9))

(test-group "runge-kutta"
  (test-equal "sumar-vectores" (list 4 6) (sumar-vectores (list 1 2) (list 3 4)))
  (test-equal "escalar-vector" (list 2 4) (escalar-vector 2 (list 1 2)))
  (test-approximate "paso-rk4 avanza el tiempo en h"
    0.1 (car (paso-rk4 (lambda (t w) w) 0.1 (list 0 (list 1)))) 1e-12)
  ;; Con y' = y, y(0) = 1 y h = 0.1, un paso de RK4 da 1.1051708333...
  ;; (el valor exacto es e^0.1 = 1.1051709180...).
  (test-approximate "paso-rk4 con y' = y da el valor conocido"
    1.1051708333333333
    (car (cadr (paso-rk4 (lambda (t w) w) 0.1 (list 0 (list 1)))))
    1e-12)
  (test-assert "RK4 = solución exacta con beta = 10 (error < 1e-6)"
    (coincide-con-exacta? 10 1e-6))
  (test-assert "RK4 = solución exacta con beta = 574 (error < 1e-4)"
    (coincide-con-exacta? 574 1e-4)))

;; Se guarda el número de fallas antes de cerrar la suite, para terminar el
;; programa con código de error si alguna prueba falló.
(define fallas (test-runner-fail-count (test-runner-current)))
(test-end "paracaidista")
(exit (if (= fallas 0) 0 1))
