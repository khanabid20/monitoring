.PHONY: prom_reload env up start down destroy stop restart logs

# define _script
# cat > .env <<'EOF'
# ALERTMGR_HOST=$(hostname -I)
# EOF
# endef
# export script = $(value _script)

# env:; @ eval "$$script"

help: ## show help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n"} /^[$$()% a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

ALERTMGR_HOST := $$(hostname -I)

env:
	@echo $(ALERTMGR_HOST)
	echo ALERTMGR_HOST=${ALERTMGR_HOST} > .env

up: env			## Build, (re)create & start containers
	docker-compose -f docker-compose.yml up -d

start: env		## Start the stopped containers
	docker-compose -f docker-compose.yml start

stop: env		## Stop the running containers
	docker-compose -f docker-compose.yml stop

restart: env	## Stop the running containers
	docker-compose -f docker-compose.yml stop
	docker-compose -f docker-compose.yml up -d 

down:
	@echo Stop and delete all the containers
	docker-compose -f docker-compose.yml down

destroy:
	@echo Stop and delete all the containers and volumes
	docker-compose -f docker-compose.yml down -v

logs:
	docker-compose -f docker-compose.yml logs -f --tail=10

ps:
	docker-compose -f docker-compose.yml ps

backup_logs: ps
	mkdir -p backup
	docker-compose -f docker-compose.yml logs --no-color > backup/docker.$$(date +'%Y%m%d_%H%M%S').logs

prom_reload:
	@echo Reload prometheus configuration...
	curl -X POST http://localhost:9091/-/reload

# Simulate Alert
simulate:
	@echo .................
	@echo ... Send \"down\" alert
	@echo .................
	@curl -X POST -d @examples/firing-alert.json http://localhost:2000/high_prio_ch
	@echo 
	@echo .................
	@echo ... Send \"resolved\" alert
	@echo .................
	@curl -X POST -d @examples/resolved-alert.json http://localhost:2000/high_prio_ch
  
