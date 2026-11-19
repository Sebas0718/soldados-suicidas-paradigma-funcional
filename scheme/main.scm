;;; Programa principal: pide los datos al usuario, busca la constante beta
;;; y muestra los resultados.
;;;
;;; Es la única parte que hace entrada/salida. Los cálculos están en los
;;; módulos fisica, runge-kutta y simulacion.
;;;
;;; Se ejecuta con:  guile -L scheme scheme/main.scm   (o make run-scheme)

(use-modules (ice-9 format)      ; format: imprimir números con decimales
             (ice-9 rdelim)      ; read-line: leer una línea
             (fisica)
             (simulacion))

;; Tiempos (s) en los que se muestra una fila de la tabla. Hay varios en el
;; primer segundo, donde la velocidad cambia rápido, y luego cada vez más
;; separados, porque la velocidad ya casi no cambia.
(define tiempos-muestra
  '(0 0.1 0.2 0.5 1 2 5 10 20 50 100 200 500 1000 2000 5000 10000))

;; Convierte un texto en un número mayor que 0, o devuelve #f si no se puede.
;; Ejemplos: "80" -> 80.0 ; "-3" -> #f ; "abc" -> #f
(define (interpretar-positivo texto)
  (let ((numero (string->number (string-trim-both texto))))
    (if (and numero (real? numero) (finite? numero) (> numero 0))
        (exact->inexact numero)
        #f)))

;; Muestra un mensaje y lee un número mayor que 0.
;; Si el dato no es válido, avisa y lo vuelve a pedir.
(define (leer-positivo mensaje)
  (display mensaje)
  (force-output)
  (let ((linea (read-line)))
    (cond ((eof-object? linea)
           (display "\nNo hay más datos de entrada.\n")
           (exit 1))
          ((interpretar-positivo linea) => (lambda (numero) numero))
          (else
           (display "  Dato inválido: escriba un número mayor que 0.\n")
           (leer-positivo mensaje)))))

;; Líneas con el resumen de resultados.
(define (resumen peso altura beta)
  (let ((final (aterrizaje beta peso altura)))
    (list ""
          "RESULTADOS"
          (format #f "  Peso total W .................. ~,3f N" peso)
          (format #f "  Constante beta encontrada ..... ~,3f kg/s" beta)
          (format #f "  Tiempo de caída ............... ~,2f s" (tiempo final))
          (format #f "  Velocidad de aterrizaje ....... ~,4f m/s (~,2f km/h)"
                  (velocidad final) (ms-a-kmh (velocidad final)))
          (format #f "  Velocidad límite W/beta ....... ~,4f m/s" (/ peso beta)))))

;; Una fila de la tabla: tiempo, velocidad y distancia por Runge-Kutta y exactas.
(define (fila-tabla peso beta estado)
  (let ((t (tiempo estado)))
    (format #f "~10,2f ~13,4f ~13,4f ~12,3f ~12,3f"
            t (velocidad estado) (velocidad-exacta beta peso t)
            (distancia estado) (distancia-exacta beta peso t))))

;; Líneas de la tabla: una fila por cada tiempo de muestra anterior al
;; aterrizaje, y al final la fila del aterrizaje.
(define (tabla peso altura beta)
  (let* ((final (aterrizaje beta peso altura))
         (tiempos (filter (lambda (t) (< t (tiempo final))) tiempos-muestra))
         (estados-muestra (map (lambda (t) (estado-en-tiempo beta peso t)) tiempos)))
    (append
     (list ""
           "VELOCIDAD Y DISTANCIA EN EL TIEMPO (Runge-Kutta vs. solución exacta)"
           "     t (s)   v RK4 (m/s) v exacta(m/s)    x RK4 (m) x exacta (m)")
     (map (lambda (estado) (fila-tabla peso beta estado)) estados-muestra)
     (list (string-append (fila-tabla peso beta final) "  <- aterrizaje")))))

;; Imprime una lista de líneas.
(define (mostrar-lineas lineas)
  (for-each (lambda (linea) (display linea) (newline)) lineas))

(define (main)
  (display "==================================================\n")
  (display "  Caída amortiguada de un paracaidista (Scheme)\n")
  (display "==================================================\n")
  (let* ((masa-paracaidista (leer-positivo "Peso del paracaidista (kg): "))
         (masa-equipo (leer-positivo "Peso del equipo (kg): "))
         (altura (leer-positivo "Altura del salto (m): "))
         (peso (peso-total masa-paracaidista masa-equipo)))
    (format #t "\nBuscando beta para aterrizar a ~a km/h...\n"
            (inexact->exact (round (ms-a-kmh velocidad-objetivo))))
    (force-output)
    (let ((beta (buscar-beta peso altura velocidad-objetivo)))
      (mostrar-lineas (resumen peso altura beta))
      (mostrar-lineas (tabla peso altura beta)))))

(main)
