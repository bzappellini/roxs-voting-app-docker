# Makefile para proyecto ROXS DevOps Voting App

.PHONY: help build up down restart logs clean ps health test up-local down-local logs-local

# Variables
COMPOSE_FILE=docker-compose.yml
COMPOSE_FILE_LOCAL=docker-compose.local-db.yml
PROJECT_NAME=roxs-voting-app

help: ## Mostrar esta ayuda
	@echo "Comandos disponibles:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Construir todas las imágenes
	docker-compose -f $(COMPOSE_FILE) build

up: ## Levantar todos los servicios
	docker-compose -f $(COMPOSE_FILE) up -d

down: ## Detener y eliminar todos los contenedores
	docker-compose -f $(COMPOSE_FILE) down

restart: down up ## Reiniciar todos los servicios

logs: ## Ver logs de todos los servicios
	docker-compose -f $(COMPOSE_FILE) logs -f

logs-vote: ## Ver logs del servicio vote
	docker-compose -f $(COMPOSE_FILE) logs -f vote

logs-worker: ## Ver logs del servicio worker
	docker-compose -f $(COMPOSE_FILE) logs -f worker

logs-result: ## Ver logs del servicio result
	docker-compose -f $(COMPOSE_FILE) logs -f result

ps: ## Listar todos los contenedores
	docker-compose -f $(COMPOSE_FILE) ps

health: ## Verificar el estado de salud de los servicios
	@echo "=== Verificando servicios ==="
	@curl -s http://localhost:5000/healthz | jq . || echo "❌ Vote service no disponible"
	@curl -s http://localhost:3001/healthz | jq . || echo "❌ Worker service no disponible"
	@curl -s http://localhost:5001/healthz | jq . || echo "❌ Result service no disponible"

stats: ## Ver estadísticas de votos
	@curl -s http://localhost:5000/stats | jq .

clean: down ## Limpiar contenedores, volúmenes e imágenes
	docker-compose -f $(COMPOSE_FILE) down -v
	docker system prune -f

clean-all: ## Limpiar todo incluyendo imágenes del proyecto
	docker-compose -f $(COMPOSE_FILE) down -v --rmi all
	docker system prune -af

metrics-vote: ## Ver métricas de Prometheus del servicio vote
	@curl -s http://localhost:5000/metrics

metrics-worker: ## Ver métricas de Prometheus del servicio worker
	@curl -s http://localhost:3001/metrics

metrics-result: ## Ver métricas de Prometheus del servicio result
	@curl -s http://localhost:5001/metrics

test-vote: ## Enviar un voto de prueba
	@curl -X POST http://localhost:5000/ -d "vote=a" -H "Content-Type: application/x-www-form-urlencoded"

shell-vote: ## Acceder al shell del contenedor vote
	docker exec -it roxs-vote sh

shell-worker: ## Acceder al shell del contenedor worker
	docker exec -it roxs-worker sh

shell-result: ## Acceder al shell del contenedor result
	docker exec -it roxs-result sh

shell-db: ## Acceder al shell de PostgreSQL
	docker exec -it roxs-database psql -U postgres -d votes

shell-redis: ## Acceder al CLI de Redis
	docker exec -it roxs-redis redis-cli

dev: ## Modo desarrollo con logs en tiempo real
	docker-compose -f $(COMPOSE_FILE) up --build

rebuild: ## Reconstruir y levantar un servicio específico (uso: make rebuild service=vote)
	docker-compose -f $(COMPOSE_FILE) up -d --build $(service)

scale-worker: ## Escalar workers (uso: make scale-worker n=3)
	docker-compose -f $(COMPOSE_FILE) up -d --scale worker=$(n)

# ======================
# Comandos para DB Local
# ======================

up-local: ## Levantar servicios con PostgreSQL local
	docker-compose -f $(COMPOSE_FILE_LOCAL) --env-file .env.local up -d

down-local: ## Detener servicios con PostgreSQL local
	docker-compose -f $(COMPOSE_FILE_LOCAL) down

logs-local: ## Ver logs con PostgreSQL local
	docker-compose -f $(COMPOSE_FILE_LOCAL) logs -f

build-local: ## Construir imágenes para setup local
	docker-compose -f $(COMPOSE_FILE_LOCAL) build

restart-local: down-local up-local ## Reiniciar servicios con DB local

ps-local: ## Ver estado de contenedores con DB local
	docker-compose -f $(COMPOSE_FILE_LOCAL) ps

setup-local-db: ## Instrucciones para configurar PostgreSQL local
	@echo "=================================="
	@echo "Setup PostgreSQL Local"
	@echo "=================================="
	@echo ""
	@echo "1. Asegúrate de que PostgreSQL esté corriendo:"
	@echo "   sudo systemctl status postgresql"
	@echo ""
	@echo "2. Crea la base de datos y tabla:"
	@echo "   psql -U postgres -f setup-local-db.sql"
	@echo ""
	@echo "3. Configura las credenciales:"
	@echo "   cp .env.local.example .env.local"
	@echo "   nano .env.local"
	@echo ""
	@echo "4. Levanta los servicios:"
	@echo "   make up-local"
	@echo ""
	@echo "Ver guía completa: LOCAL-DB-GUIDE.md"

# ======================
# PostgreSQL Standalone
# ======================

postgres-up: ## Levantar solo PostgreSQL en Docker
	docker-compose -f docker-compose.postgres.yml up -d

postgres-down: ## Detener PostgreSQL
	docker-compose -f docker-compose.postgres.yml down

postgres-restart: postgres-down postgres-up ## Reiniciar PostgreSQL

postgres-logs: ## Ver logs de PostgreSQL
	docker-compose -f docker-compose.postgres.yml logs -f

postgres-shell: ## Conectarse a PostgreSQL
	docker exec -it postgres-standalone psql -U postgres -d votes

postgres-status: ## Ver estado de PostgreSQL
	docker-compose -f docker-compose.postgres.yml ps

postgres-clean: ## Detener y eliminar datos de PostgreSQL
	docker-compose -f docker-compose.postgres.yml down -v

postgres-backup: ## Hacer backup de la base de datos
	@mkdir -p backups
	docker exec postgres-standalone pg_dump -U postgres votes > backups/backup_votes_$$(date +%Y%m%d_%H%M%S).sql
	@echo "Backup guardado en: backups/backup_votes_$$(date +%Y%m%d_%H%M%S).sql"
