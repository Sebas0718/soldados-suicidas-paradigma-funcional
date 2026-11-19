;;; Modelo físico de la caída amortiguada de un paracaidista.
;;;
;;; Contiene las constantes, las conversiones de unidades, las ecuaciones del
;;; sistema y la solución exacta (analítica). Todas son funciones puras.
;;;
;;; Unidades: segundos, metros, m/s, newtons. La constante beta está en kg/s.

(define-module (fisica)
  #:export (gravedad
            peso-total
            kmh-a-ms
            ms-a-kmh
            velocidad-objetivo
            derivadas
            velocidad-exacta
            distancia-exacta))

;; Aceleración de la gravedad (m/s²).
(define gravedad 9.81)

;; Peso total W (en newtons) a partir de las masas en kg del paracaidista
;; y de su equipo: W = (m_paracaidista + m_equipo) * g.
(define (peso-total masa-paracaidista masa-equipo)
  (* (+ masa-paracaidista masa-equipo) gravedad))

;; Convierte km/h a m/s.
(define (kmh-a-ms kmh)
  (/ kmh 3.6))

;; Convierte m/s a km/h.
(define (ms-a-kmh ms)
  (* ms 3.6))

;; Velocidad de aterrizaje deseada: 8 km/h, expresada en m/s.
(define velocidad-objetivo (kmh-a-ms 8))

;; La función f(t, y) del sistema de ecuaciones, con y = (x v):
;;
;;   dx/dt = v
;;   dv/dt = g - (beta * g / W) * v
;;
;; Recibe beta y W, y devuelve otra función que recibe t y el estado (x v).
;; Así Runge-Kutta puede usarla como f(t, y) sin saber qué son beta y W.
(define (derivadas beta peso)
  (lambda (tiempo valores)
    (let ((velocidad (cadr valores)))
      (list velocidad
            (- gravedad (/ (* beta gravedad velocidad) peso))))))

;; Solución exacta de la velocidad: v(t) = (W/beta) * (1 - e^(-beta*g*t/W)).
(define (velocidad-exacta beta peso tiempo)
  (* (/ peso beta)
     (- 1 (exp (- (/ (* beta gravedad tiempo) peso))))))

;; Solución exacta de la distancia recorrida:
;; x(t) = (W/beta)*t + (W²/(beta²*g)) * e^(-beta*g*t/W) - W²/(beta²*g).
(define (distancia-exacta beta peso tiempo)
  (let ((c (/ (* peso peso) (* beta beta gravedad))))
    (+ (* (/ peso beta) tiempo)
       (* c (exp (- (/ (* beta gravedad tiempo) peso))))
       (- c))))
