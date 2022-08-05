.PHONY: prom_reload env up start down destroy stop restart logs ps backup_logs simulate

# define _script
# cat > .env <<'EOF'
# ALERTMGR_HOST=$(hostname -I)
# EOF
# endef
# export script = $(value _script)

# env:; @ eval "$$script"

default: help

ALERTMGR_HOST := $$(hostname -I)
# DOCKER_COMPOSE_CMD = docker-compose -f docker-compose.yml

ifdef profile
	DOCKER_COMPOSE_CMD = docker-compose -f docker-compose.yml --profile=${profile}
else
	DOCKER_COMPOSE_CMD = docker-compose -f docker-compose.yml
endif

env:				## Create .env file (currently with ALERMGT_HOST var)
	@echo $(ALERTMGR_HOST)
	echo ALERTMGR_HOST=${ALERTMGR_HOST} > .env

up: env				## Build, (re)create & start containers
	${DOCKER_COMPOSE_CMD} up -d

start: env			## Start the stopped containers
	${DOCKER_COMPOSE_CMD} start

stop: env			## Stop the running containers
	${DOCKER_COMPOSE_CMD} stop

restart: env		## Restart the containers
	${DOCKER_COMPOSE_CMD} stop
	${DOCKER_COMPOSE_CMD} up -d

down:				## Stop & delete the running containers
	@echo Stop and delete all the containers
	${DOCKER_COMPOSE_CMD} down

destroy:			## Stop & delete the running containers as well as the volumes
	@echo Stop and delete all the containers and volumes
	${DOCKER_COMPOSE_CMD} down -v

logs:				## Tail containers log
	${DOCKER_COMPOSE_CMD} logs -f --tail=10

ps:					## Display running containers
	${DOCKER_COMPOSE_CMD} ps

backup_logs: ps		## Backs up docker logs
	mkdir -p backup
	${DOCKER_COMPOSE_CMD} logs --no-color > backup/docker.$$(date +'%Y%m%d_%H%M%S').logs

prom_reload: 		## Reload Prometheus configuration file
	@echo Reload prometheus configuration...
	curl -X POST http://localhost:9091/-/reload

simulate: 			## Simulate Alert
	@echo .................
	@echo . Send \"down\" alert
	@echo .................
	@curl -X POST -d @examples/firing-alert.json http://localhost:2000/high_prio_ch #| jq -r
	@echo 
	@echo .................
	@echo . Send \"resolved\" alert
	@echo .................
	@curl -X POST -d @examples/resolved-alert.json http://localhost:2000/high_prio_ch #| jq -r

help: ## Show help message
	@echo 'Usage:'
	@echo '  make <target> [option1=val1 option2=val2 ...]'
	@awk 'BEGIN {FS = ":.*##"; printf "\nTargets:\033[36m\033[0m\n"} /^[$$()% a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m-- %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@printf  "\nOptions:\n"
	@printf "  \033[36m%-15s\033[0m-- %s\n" "profile=value" " Profile name of docker-compose service(s)"

## Show help message
# help:
# 	@printf "Available targets:\n\n"
# 	@awk '/^[a-zA-Z\-_0-9%:\\]+/ { \
# 	  helpMessage = match(lastLine, /^## (.*)/); \
# 	  if (helpMessage) { \
# 	    helpCommand = $$1; \
# 	    helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
#         gsub("\\\\", "", helpCommand); \
#         gsub(":+$$", "", helpCommand); \
# 	    printf "  \x1b[32;01m%-15s\x1b[0m %s\n", helpCommand, helpMessage; \
# 	  } \
# 	} \
# 	{ lastLine = $$0 }' $(MAKEFILE_LIST) | sort -u
# 	@printf "\n"
