# Nombre del target por defecto
.PHONY: all setup clean

all: setup

# Crear la estructura de directorios y archivos
setup:
	@echo "Creando estructura de directorios..."
	mkdir -p config models scripts tests docs

	@echo "Creando archivos base en la raíz..."
	touch Containerfile README.md compose.yaml .gitlab-ci.yml

	@echo "Creando archivos en subdirectorios..."
	touch models/.gitkeep
	touch scripts/build.sh scripts/run.sh scripts/verify-isolation.sh
	touch docs/architecture.md docs/security.md docs/isolation-tests.md

	@echo "Asignando permisos de ejecución a los scripts..."
	chmod +x scripts/*.sh

	@echo "¡Estructura de local-llm-secure creada con éxito!"

# Limpiar los archivos creados (opcional, usar con cuidado)
clean:
	@echo "Eliminando estructura creada..."
	rm -rf config models scripts tests docs
	rm -f Containerfile README.md compose.yaml .gitlab-ci.yml
	@echo "Limpieza completada."

