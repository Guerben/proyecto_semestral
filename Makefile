# ============================================================================
# Makefile - Comandos útiles para desarrollo y despliegue
# ============================================================================
# Uso: make <objetivo>
# Ejemplo: make docker-build, make docker-up, make docker-logs

.PHONY: help docker-build docker-up docker-down docker-logs docker-ps \
        docker-clean docker-push docker-scan quick-start deploy-local

# Variables
DOCKER_HUB_USER ?= tu-usuario
DOCKER_REGISTRY ?= docker.io
PROJECT_NAME = proyecto-semestral
ENV_FILE = .env

# Colores para output
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[1;33m
NC = \033[0m # No Color

# ============================================================================
# HELP - Mostrar información de comandos disponibles
# ============================================================================
help:
	@echo "$(GREEN)╔════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║ Docker Project - Comandos Disponibles                     ║$(NC)"
	@echo "$(GREEN)╚════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)📦 CONSTRUCCIÓN DE IMÁGENES$(NC)"
	@echo "  make docker-build              Construir todas las imágenes"
	@echo "  make docker-build-ventas       Construir solo API Ventas"
	@echo "  make docker-build-despachos    Construir solo API Despachos"
	@echo "  make docker-build-frontend     Construir solo Frontend"
	@echo ""
	@echo "$(YELLOW)🚀 EJECUCIÓN$(NC)"
	@echo "  make docker-up                 Levantar todos los servicios"
	@echo "  make quick-start               Build + up (inicio rápido)"
	@echo "  make docker-down               Detener servicios"
	@echo "  make docker-restart            Reiniciar servicios"
	@echo ""
	@echo "$(YELLOW)📊 MONITOREO$(NC)"
	@echo "  make docker-ps                 Ver estado de contenedores"
	@echo "  make docker-logs               Ver logs en tiempo real"
	@echo "  make docker-logs-ventas        Ver logs API Ventas"
	@echo "  make docker-logs-despachos     Ver logs API Despachos"
	@echo "  make docker-logs-frontend      Ver logs Frontend"
	@echo "  make docker-logs-db            Ver logs Base de Datos"
	@echo ""
	@echo "$(YELLOW)🔧 MANTENIMIENTO$(NC)"
	@echo "  make docker-clean              Limpiar imágenes no usadas"
	@echo "  make docker-prune              Limpiar sistema completo"
	@echo "  make docker-scan               Escanear vulnerabilidades"
	@echo ""
	@echo "$(YELLOW)📤 PUBLICACIÓN$(NC)"
	@echo "  make docker-push               Publicar imágenes en Docker Hub"
	@echo "  make docker-tag                Taggear imágenes para publicar"
	@echo ""
	@echo "$(YELLOW)⚙️ CONFIGURACIÓN$(NC)"
	@echo "  make setup-env                 Crear .env desde .env.example"
	@echo "  make docker-shell-ventas       Acceder al shell de API Ventas"
	@echo "  make docker-shell-despachos    Acceder al shell de API Despachos"
	@echo "  make docker-shell-db           Acceder a MySQL"
	@echo ""

# ============================================================================
# SETUP
# ============================================================================
setup-env:
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "$(YELLOW)Creando $(ENV_FILE) desde .env.example...$(NC)"; \
		cp .env.example $(ENV_FILE); \
		echo "$(GREEN)✓ Archivo $(ENV_FILE) creado$(NC)"; \
		echo "$(YELLOW)⚠️  Editar $(ENV_FILE) con tus valores si es necesario$(NC)"; \
	else \
		echo "$(GREEN)✓ $(ENV_FILE) ya existe$(NC)"; \
	fi

# ============================================================================
# CONSTRUCCIÓN DE IMÁGENES
# ============================================================================
docker-build: setup-env
	@echo "$(YELLOW)📦 Construyendo todas las imágenes...$(NC)"
	docker-compose build --no-cache

docker-build-ventas: setup-env
	@echo "$(YELLOW)📦 Construyendo API Ventas...$(NC)"
	docker-compose build --no-cache api-ventas

docker-build-despachos: setup-env
	@echo "$(YELLOW)📦 Construyendo API Despachos...$(NC)"
	docker-compose build --no-cache api-despachos

docker-build-frontend: setup-env
	@echo "$(YELLOW)📦 Construyendo Frontend...$(NC)"
	docker-compose build --no-cache frontend

# ============================================================================
# EJECUCIÓN
# ============================================================================
docker-up: setup-env
	@echo "$(YELLOW)🚀 Levantando servicios...$(NC)"
	docker-compose up -d
	@echo "$(GREEN)✓ Servicios iniciados$(NC)"
	@echo ""
	@echo "$(GREEN)Acceso a servicios:$(NC)"
	@echo "  Frontend:    http://localhost:3000"
	@echo "  API Ventas:  http://localhost:8080/swagger-ui.html"
	@echo "  API Despachos: http://localhost:8081/swagger-ui.html"
	@echo "  MySQL:       localhost:3306"
	@echo ""

docker-down:
	@echo "$(YELLOW)⬇️  Deteniendo servicios...$(NC)"
	docker-compose down
	@echo "$(GREEN)✓ Servicios detenidos$(NC)"

docker-restart: docker-down docker-up
	@echo "$(GREEN)✓ Servicios reiniciados$(NC)"

quick-start: docker-build docker-up
	@echo "$(GREEN)✓ Inicio rápido completado$(NC)"

# ============================================================================
# MONITOREO
# ============================================================================
docker-ps:
	@echo "$(YELLOW)📊 Estado de contenedores:$(NC)"
	@docker-compose ps

docker-logs:
	@docker-compose logs -f

docker-logs-ventas:
	@docker-compose logs -f api-ventas

docker-logs-despachos:
	@docker-compose logs -f api-despachos

docker-logs-frontend:
	@docker-compose logs -f frontend

docker-logs-db:
	@docker-compose logs -f db

# ============================================================================
# SHELL INTERACTIVO
# ============================================================================
docker-shell-ventas:
	@echo "$(YELLOW)Accediendo a shell de API Ventas...$(NC)"
	@docker-compose exec api-ventas bash

docker-shell-despachos:
	@echo "$(YELLOW)Accediendo a shell de API Despachos...$(NC)"
	@docker-compose exec api-despachos bash

docker-shell-frontend:
	@echo "$(YELLOW)Accediendo a shell de Frontend...$(NC)"
	@docker-compose exec frontend sh

docker-shell-db:
	@echo "$(YELLOW)Accediendo a MySQL...$(NC)"
	@docker-compose exec db mysql -u appuser -pappuser123 -e "USE proyecto_db; SHOW TABLES;"

# ============================================================================
# MANTENIMIENTO Y LIMPIEZA
# ============================================================================
docker-clean:
	@echo "$(YELLOW)🧹 Limpiando imágenes no usadas...$(NC)"
	@docker image prune -f
	@echo "$(GREEN)✓ Limpieza completada$(NC)"

docker-prune:
	@echo "$(RED)⚠️  ADVERTENCIA: Esto eliminará imágenes, contenedores y volúmenes no usados$(NC)"
	@read -p "¿Continuar? [y/N] " confirm && [ "$$confirm" = "y" ] && \
		docker system prune -a --volumes -f && \
		echo "$(GREEN)✓ Sistema limpiado$(NC)" || echo "Cancelado"

# ============================================================================
# SEGURIDAD
# ============================================================================
docker-scan:
	@echo "$(YELLOW)🔒 Escaneando vulnerabilidades con Trivy...$(NC)"
	@command -v trivy >/dev/null 2>&1 || \
		{ echo "$(RED)Trivy no está instalado$(NC)"; exit 1; }
	@trivy image docker.io/$(DOCKER_HUB_USER)/api-ventas:latest
	@trivy image docker.io/$(DOCKER_HUB_USER)/api-despachos:latest
	@trivy image docker.io/$(DOCKER_HUB_USER)/frontend:latest

# ============================================================================
# PUBLICACIÓN EN REGISTROS
# ============================================================================
docker-tag:
	@echo "$(YELLOW)🏷️  Taggeando imágenes...$(NC)"
	@docker tag api-ventas:latest $(DOCKER_REGISTRY)/$(DOCKER_HUB_USER)/api-ventas:latest
	@docker tag api-despachos:latest $(DOCKER_REGISTRY)/$(DOCKER_HUB_USER)/api-despachos:latest
	@docker tag frontend:latest $(DOCKER_REGISTRY)/$(DOCKER_HUB_USER)/frontend:latest
	@echo "$(GREEN)✓ Imágenes taggeadas$(NC)"

docker-push: docker-tag
	@echo "$(YELLOW)📤 Publicando imágenes en Docker Hub...$(NC)"
	@docker push $(DOCKER_REGISTRY)/$(DOCKER_HUB_USER)/api-ventas:latest
	@docker push $(DOCKER_REGISTRY)/$(DOCKER_HUB_USER)/api-despachos:latest
	@docker push $(DOCKER_REGISTRY)/$(DOCKER_HUB_USER)/frontend:latest
	@echo "$(GREEN)✓ Imágenes publicadas$(NC)"

# ============================================================================
# INFORMACIÓN
# ============================================================================
info:
	@echo "$(GREEN)╔════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║ Información del Proyecto                                   ║$(NC)"
	@echo "$(GREEN)╚════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)Docker Info:$(NC)"
	@docker --version
	@docker-compose --version
	@echo ""
	@echo "$(YELLOW)Imágenes construidas:$(NC)"
	@docker images | grep -E "api-ventas|api-despachos|frontend" || echo "No hay imágenes construidas"
	@echo ""
	@echo "$(YELLOW)Contenedores activos:$(NC)"
	@docker-compose ps || echo "No hay contenedores"

# ============================================================================
# DEFAULT
# ============================================================================
.DEFAULT_GOAL := help
