;;; Pruebas de la versión en Scheme, con SRFI-64 (incluida en Guile).
;;; Se ejecuta con:  make test-scheme

(use-modules (srfi srfi-64)
             (fisica)
             (runge-kutta)
             (simulacion))

;; Datos del caso del enunciado: 80 kg + 50 kg.
(define peso-enunciado (peso-total 80 50))

;; ¿Coincide Runge-Kutta con la solución exacta a los 20 s?
(define (coincide-con-exacta? beta tolerancia)
  (let* ((estado (estado-en-tiempo beta peso-enunciado 20))
         (t (tiempo estado)))
    (and (< (abs (- (velocidad estado) (velocidad-exacta beta peso-enunciado t))) tolerancia)
         (< (abs (- (distancia estado) (distancia-exacta beta peso-enunciado t))) tolerancia))))

;; Distancias de los primeros n estados de la caída, en orden.
(define (distancias-primeros-pasos n beta peso)
  (let avanzar ((pasos-restantes n)
                (estado estado-inicial)
                (distancias '()))
    (if (= pasos-restantes 0)
        (reverse distancias)
        (avanzar (- pasos-restantes 1)
                 (siguiente-estado beta peso estado)
                 (cons (distancia estado) distancias)))))

;; ¿Cada número es mayor o igual que el anterior?
(define (siempre-crece? numeros)
  (or (null? numeros)
      (null? (cdr numeros))
      (and (<= (car numeros) (cadr numeros))
           (siempre-crece? (cdr numeros)))))

;; Beta encontrado para el caso del enunciado (80 kg + 50 kg desde 1500 m).
;; Se calcula una sola vez y lo comparten varias pruebas.
(define beta-enunciado (buscar-beta peso-enunciado 1500 velocidad-objetivo))

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

(test-group "simulacion"
  (test-equal "la simulación empieza en reposo"
    estado-inicial (estado-en-tiempo 500 peso-enunciado 0))
  (test-approximate "cada paso avanza h segundos"
    paso-tiempo (tiempo (siguiente-estado 500 peso-enunciado estado-inicial)) 1e-12)
  (test-approximate "estado-en-tiempo 10 está en t = 10"
    10 (tiempo (estado-en-tiempo 500 peso-enunciado 10)) 1e-9)
  (test-assert "la distancia nunca disminuye"
    (siempre-crece? (distancias-primeros-pasos 1000 500 peso-enunciado)))
  (test-assert "al aterrizar ya se recorrió la altura, sin pasarse más de un paso"
    (let ((x (distancia (aterrizaje 500 peso-enunciado 1500))))
      (and (>= x 1500) (< x 1501))))
  (test-assert "más beta, aterrizaje más lento"
    (> (velocidad-aterrizaje 100 peso-enunciado 1500)
       (velocidad-aterrizaje 500 peso-enunciado 1500)))
  (test-assert "acotar-beta da un beta que ya frena lo suficiente"
    (<= (velocidad-aterrizaje (acotar-beta peso-enunciado 1500 velocidad-objetivo 1)
                              peso-enunciado 1500)
        velocidad-objetivo))
  (test-approximate "beta del enunciado = 573.885 kg/s" 573.885 beta-enunciado 0.01)
  (test-approximate "con ese beta se aterriza a 8 km/h"
    8 (ms-a-kmh (velocidad-aterrizaje beta-enunciado peso-enunciado 1500)) 0.01)
  (test-approximate "otro caso (60 + 20 kg desde 800 m) también aterriza a 8 km/h"
    8
    (let* ((peso (peso-total 60 20))
           (beta (buscar-beta peso 800 velocidad-objetivo)))
      (ms-a-kmh (velocidad-aterrizaje beta peso 800)))
    0.01)
  (test-assert "altura muy baja (0.1 m): casi no hace falta frenar"
    (< (buscar-beta peso-enunciado 0.1 velocidad-objetivo) 1)))

;; Se guarda el número de fallas antes de cerrar la suite, para terminar el
;; programa con código de error si alguna prueba falló.
(define fallas (test-runner-fail-count (test-runner-current)))
(test-end "paracaidista")
(exit (if (= fallas 0) 0 1))
