;;; Simulación de la caída con Runge-Kutta y búsqueda de la constante beta.
;;;
;;; Une el modelo físico (fisica) con el método numérico (runge-kutta).
;;; Todas son funciones puras. Las repeticiones se hacen con recursión de
;;; cola ("let con nombre"), que Scheme ejecuta sin gastar pila.

(define-module (simulacion)
  #:use-module (fisica)
  #:use-module (runge-kutta)
  #:export (paso-tiempo
            tolerancia-beta
            estado-inicial
            tiempo
            distancia
            velocidad
            siguiente-estado
            aterrizaje
            velocidad-aterrizaje
            estado-en-tiempo
            acotar-beta
            biseccion
            buscar-beta))

;; Paso de tiempo h de Runge-Kutta (s).
(define paso-tiempo 0.05)

;; La búsqueda de beta termina cuando el intervalo mide menos que esto (kg/s).
(define tolerancia-beta 1e-6)

;; Al inicio (t = 0) el paracaidista está en reposo: x = 0, v = 0.
(define estado-inicial (list 0 (list 0 0)))

;; Tiempo de un estado (s).
(define (tiempo estado)
  (car estado))

;; Distancia recorrida en un estado (m).
(define (distancia estado)
  (car (cadr estado)))

;; Velocidad en un estado (m/s).
(define (velocidad estado)
  (cadr (cadr estado)))

;; El estado un paso de tiempo después.
(define (siguiente-estado beta peso estado)
  (paso-rk4 (derivadas beta peso) paso-tiempo estado))

;; Primer estado en que la distancia recorrida alcanza la altura del salto.
(define (aterrizaje beta peso altura)
  (let avanzar ((estado estado-inicial))
    (if (>= (distancia estado) altura)
        estado
        (avanzar (siguiente-estado beta peso estado)))))

;; Velocidad con la que el paracaidista llega al suelo (m/s).
(define (velocidad-aterrizaje beta peso altura)
  (velocidad (aterrizaje beta peso altura)))

;; Estado de la caída en el tiempo t (el paso más cercano a t).
(define (estado-en-tiempo beta peso t)
  (let avanzar ((pasos-restantes (inexact->exact (round (/ t paso-tiempo))))
                (estado estado-inicial))
    (if (= pasos-restantes 0)
        estado
        (avanzar (- pasos-restantes 1)
                 (siguiente-estado beta peso estado)))))

;; Fase 1 de la búsqueda: duplica beta hasta que el paracaidista aterrice
;; a la velocidad objetivo o más lento. Devuelve ese beta (un límite superior).
(define (acotar-beta peso altura v-objetivo beta)
  (if (<= (velocidad-aterrizaje beta peso altura) v-objetivo)
      beta
      (acotar-beta peso altura v-objetivo (* 2 beta))))

;; Fase 2 de la búsqueda: parte el intervalo [beta-min, beta-max] a la mitad
;; hasta que mida menos que la tolerancia.
;;
;; Devuelve beta-max porque siempre cumple: aterriza a v-objetivo o más lento.
(define (biseccion peso altura v-objetivo beta-min beta-max)
  (let ((beta-medio (/ (+ beta-min beta-max) 2)))
    (cond ((< (- beta-max beta-min) tolerancia-beta)
           beta-max)
          ((> (velocidad-aterrizaje beta-medio peso altura) v-objetivo)
           ;; frena poco: beta más grande
           (biseccion peso altura v-objetivo beta-medio beta-max))
          (else
           ;; frena de más: beta más chico
           (biseccion peso altura v-objetivo beta-min beta-medio)))))

;; Encuentra la constante beta (kg/s) con la que un peso W, saltando desde
;; una altura dada, llega al suelo a la velocidad objetivo.
(define (buscar-beta peso altura v-objetivo)
  (let ((beta-max (acotar-beta peso altura v-objetivo 1)))
    (biseccion peso altura v-objetivo 0 beta-max)))
