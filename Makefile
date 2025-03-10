# Extract command-line arguments excluding target name
ARGS = $(filter-out $@,$(MAKECMDGOALS))

export DOCKER_BUILDKIT=1
#export COMPOSE_PROJECT_NAME=api
#export COMPOSE_FILE=docker-compose-dev.yml
#export COMPOSE_FILE=docker-compose-test.yml

# Default service name (can be overridden)
SERVICE ?= api

list:
	@echo "Available commands:"
	@echo ""
	@echo "  make os                       - Display OS information"
	@echo "  make ls                       - List active Docker Compose projects"
	@echo "  make ps                       - Show running Docker containers"
	@echo "  make pa                       - Show all Docker containers"
	@echo "  make stats                    - Show resource usage of running containers"
	@echo "  make ssh service=<srv>        - SSH into a running container (default: api)"
	@echo "  make log service=<srv>        - Show logs for a specific container (default: api)"
	@echo "  make inspect service=<srv>    - Inspect a container (default: api)"
	@echo "  make kill                     - Kill all running containers"
	@echo "  make stop                     - Stop all running containers"
	@echo "  make start                    - Start containers (detached mode)"
	@echo "  make restart                  - Restart all containers"
	@echo "  make build                    - Build images and start containers"
	@echo "  make build-dev                - Build using dev configuration"
	@echo "  make build-test               - Build using test configuration"
	@echo "  make supervisor <cmd>         - Run Supervisor command inside 'api' container"
	@echo "  make supervisor_log           - Tail Supervisor logs"
	@echo "  make supervisor_restart       - Restart all Supervisor-managed processes"
	@echo "  make reverb_log               - Tail Reverb logs"
	@echo ""

os:
	@uname -a
	@cat /etc/os-release || true
	@lsb_release -a || true
	@hostnamectl || true

ls:
	@docker compose ls

ps:
	@docker compose ps --format "table {{.ID}}\t{{.Name}}\t{{.Status}}"

pa:
	@docker compose ps -a --format "table {{.ID}}\t{{.Name}}\t{{.Status}}\t{{.Ports}}"

ssh:
	@if [ -z "$(SERVICE)" ]; then echo "Usage: make ssh service=<srv>"; exit 1; fi
	@docker compose exec $(SERVICE) sh

log:
	@if [ -z "$(SERVICE)" ]; then echo "Usage: make log service=<srv>"; exit 1; fi
	@docker compose logs $(SERVICE) --follow

logs:
	@docker compose logs

inspect:
	@if [ -z "$(SERVICE)" ]; then echo "Usage: make inspect service=<srv>"; exit 1; fi
	@docker inspect $(shell docker compose ps -q $(SERVICE))

docker-log:
	@sudo journalctl -u docker -n 100 --no-pager

kill:
	@docker compose kill

stats:
	@docker stats

start:
	@docker compose up --build -d

stop:
	@docker compose down

restart:
	@docker compose restart

build:
	@docker compose up --build --force-recreate -d --remove-orphans

build-dev:
	@docker compose -f ./docker-compose-dev.yml up --build --force-recreate -d --remove-orphans

build-test:
	@docker compose -f ./docker-compose-test.yml up --build --force-recreate -d --remove-orphans

supervisor:
	@docker compose exec $(SERVICE) supervisorctl $(ARGS)

supervisor_log:
	@docker compose exec $(SERVICE) tail -f /var/log/supervisor/supervisord.log

supervisor_update:
	@docker compose exec $(SERVICE) supervisorctl reread
	@docker compose exec $(SERVICE) supervisorctl update

supervisor_restart:
	@docker compose exec $(SERVICE) supervisorctl restart all

reverb_log:
	@docker compose exec $(SERVICE) tail -f /var/log/supervisor/reverb.log

# Prevent Make from interpreting args as targets
%:
	@:
