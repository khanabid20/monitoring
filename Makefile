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
DOCKER_COMPOSE_CMD = docker-compose -f docker-compose.yml

config:				## Create & copy configuration files into /etc/prometheus
	@echo ...Creating /etc/prometheus folder
	sudo mkdir -p /etc/prometheus
	sudo chmod 777 /etc/prometheus
	@echo
	@echo ...Copying configuration files
	sudo cp -r etc/prometheus/* /etc/prometheus/
	@echo

env:				## Create .env file (currently with ALERMGT_HOST var)
	@echo ...Creating .env file for docker-compose
	echo ALERTMGR_HOST=${ALERTMGR_HOST} > .env
	@echo

up: config env		## Build, (re)create & start containers
	@echo
	${DOCKER_COMPOSE_CMD} up -d

start:				## Starts previously-built containers
	${DOCKER_COMPOSE_CMD} start

stop:				## Stops containers (without removing them)
	${DOCKER_COMPOSE_CMD} stop

restart: stop start	## Stops containers (via 'stop'), and starts them again (via 'start')

down:				## Stop & delete the running containers
	@echo Stop and delete all the containers
	${DOCKER_COMPOSE_CMD} down

destroy:			## Stop & delete the running containers, volumes, networking, etc.
	@echo Stop and delete all the containers, volumes and networking
	${DOCKER_COMPOSE_CMD} down -v

logs:				## Tail containers log
	${DOCKER_COMPOSE_CMD} logs -f --tail=10

ps:					## Display running containers
	${DOCKER_COMPOSE_CMD} ps

backup_logs:		## Backs up containers log
	mkdir -p backup
	${DOCKER_COMPOSE_CMD} logs --no-color > backup/docker.$$(date +'%Y%m%d_%H%M%S').logs

nodex:				## Deploy node-exporter on Node machine(s)
	./setup_node_exporter.sh

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
	@echo '  make <target>'		#' [option1=val1 option2=val2 ...]'
	@awk 'BEGIN {FS = ":.*##"; printf "\nTargets:\033[36m\033[0m\n"} /^[$$()% a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m-- %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
#	@printf  "\nOptions:\n"
#	@printf "  \033[36m%-15s\033[0m-- %s\n" "profile=value" " Profile name of docker-compose service(s)"

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
