.PHONY: help up down restart logs ps clean validate backup restore

# Colors for output
GREEN  := \033[0;32m
YELLOW := \033[0;33m
NC     := \033[0m # No Color

help: ## Show this help message
	@echo '$(GREEN)Grafana Observability Stack - Management Commands$(NC)'
	@echo ''
	@echo 'Usage:'
	@echo '  make $(YELLOW)<target>$(NC)'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

up: ## Start all services
	@echo "$(GREEN)Starting observability stack...$(NC)"
	docker-compose up -d
	@echo "$(GREEN)Stack started! Access Grafana at http://localhost:3000$(NC)"
	@echo "$(YELLOW)Default credentials: admin / StrongPass123$(NC)"

down: ## Stop all services
	@echo "$(YELLOW)Stopping observability stack...$(NC)"
	docker-compose down

restart: down up ## Restart all services

logs: ## Show logs from all services
	docker-compose logs -f

logs-%: ## Show logs for specific service (e.g., make logs-grafana)
	docker-compose logs -f $*

ps: ## Show running services
	docker-compose ps

validate: ## Validate docker-compose configuration
	@echo "$(GREEN)Validating configuration...$(NC)"
	docker-compose config --quiet && echo "$(GREEN)✓ Configuration is valid$(NC)" || echo "$(YELLOW)✗ Configuration has errors$(NC)"

clean: ## Stop services and remove volumes (WARNING: deletes all data)
	@echo "$(YELLOW)WARNING: This will delete all persistent data!$(NC)"
	@echo "Press Ctrl+C to cancel, or Enter to continue..."
	@read dummy
	docker-compose down -v
	@echo "$(GREEN)Cleanup complete$(NC)"

backup: ## Backup all volumes
	@echo "$(GREEN)Creating backup...$(NC)"
	@mkdir -p backups
	@docker run --rm -v observability_grafana-data:/data -v $(PWD)/backups:/backup alpine tar czf /backup/grafana-data-$$(date +%Y%m%d-%H%M%S).tar.gz -C /data .
	@docker run --rm -v observability_prometheus-data:/data -v $(PWD)/backups:/backup alpine tar czf /backup/prometheus-data-$$(date +%Y%m%d-%H%M%S).tar.gz -C /data .
	@docker run --rm -v observability_mimir-data:/data -v $(PWD)/backups:/backup alpine tar czf /backup/mimir-data-$$(date +%Y%m%d-%H%M%S).tar.gz -C /data .
	@docker run --rm -v observability_loki-data:/data -v $(PWD)/backups:/backup alpine tar czf /backup/loki-data-$$(date +%Y%m%d-%H%M%S).tar.gz -C /data .
	@docker run --rm -v observability_tempo-data:/data -v $(PWD)/backups:/backup alpine tar czf /backup/tempo-data-$$(date +%Y%m%d-%H%M%S).tar.gz -C /data .
	@echo "$(GREEN)Backup complete! Files saved to ./backups/$(NC)"

health: ## Check health status of all services
	@echo "$(GREEN)Checking service health...$(NC)"
	@echo "\nGrafana:"
	@curl -s http://localhost:3000/api/health | jq . || echo "$(YELLOW)Not responding$(NC)"
	@echo "\nPrometheus:"
	@curl -s http://localhost:9090/-/healthy || echo "$(YELLOW)Not responding$(NC)"
	@echo "\nLoki:"
	@curl -s http://localhost:3100/ready || echo "$(YELLOW)Not responding$(NC)"
	@echo "\nTempo:"
	@curl -s http://localhost:3200/ready || echo "$(YELLOW)Not responding$(NC)"
	@echo "\nMimir:"
	@curl -s http://localhost:8080/ready || echo "$(YELLOW)Not responding$(NC)"
	@echo "\nOTEL Collector:"
	@curl -s http://localhost:13133/ || echo "$(YELLOW)Not responding$(NC)"

pull: ## Pull latest images
	@echo "$(GREEN)Pulling latest images...$(NC)"
	docker-compose pull

update: pull down up ## Update all services to latest versions

stats: ## Show resource usage
	docker stats --no-stream $$(docker-compose ps -q)

shell-%: ## Open shell in specific service (e.g., make shell-grafana)
	docker-compose exec $* sh

prune: ## Remove unused Docker resources
	@echo "$(YELLOW)Cleaning up unused Docker resources...$(NC)"
	docker system prune -f
	@echo "$(GREEN)Cleanup complete$(NC)"

