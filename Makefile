# Atajos para compilar, ejecutar y probar las dos versiones del proyecto.
#   make run-haskell   -> compila y ejecuta la versión en Haskell
#   make run-scheme    -> ejecuta la versión en Scheme (Guile)
#   make test          -> corre las pruebas de ambas versiones
#   make clean         -> borra los archivos generados

# -dynamic: enlaza con las bibliotecas dinámicas que trae el paquete "ghc" de Arch
# (así no hace falta instalar "ghc-static", que pesa unos 2 GB).
# -Wall: muestra todas las advertencias, para mantener el código limpio.
GHC   = ghc -dynamic -O1 -Wall
BUILD = haskell/build
GUILE = guile -L scheme

.PHONY: haskell run-haskell run-scheme test test-haskell test-scheme clean

haskell:
	mkdir -p $(BUILD)
	$(GHC) -ihaskell/src -outputdir $(BUILD) -o $(BUILD)/paracaidista haskell/src/Main.hs

run-haskell: haskell
	./$(BUILD)/paracaidista

run-scheme:
	$(GUILE) scheme/main.scm

test: test-haskell test-scheme

test-haskell:
	mkdir -p $(BUILD)
	$(GHC) -ihaskell/src -outputdir $(BUILD) -o $(BUILD)/pruebas haskell/pruebas/Pruebas.hs
	./$(BUILD)/pruebas

test-scheme:
	$(GUILE) scheme/pruebas.scm

clean:
	rm -rf $(BUILD)
