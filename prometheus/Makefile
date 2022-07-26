.PHONY: default config_prom config_grafana config env up start stop restart down destroy delete_mount logs ps backup_logs nodex reload_prom promtool simulate help

# define _script
# cat > .env <<'EOF'
# ALERTMGR_HOST=$(hostname -I)
# EOF
# endef
# export script = $(value _script)

# env:; @ eval "$$script"

default: help

ALERTMGR_HOST := $$(hostname -I)
DOCKER_COMPOSE_CMD := docker-compose -f docker-compose.yml
TAIL := $${t:-10}
SERVICE := $${s:-}
PROMTOOL_VERSION := 2.37.0
PROMTOOL_TZG := https://github.com/prometheus/prometheus/releases/download/v${PROMTOOL_VERSION}/prometheus-${PROMTOOL_VERSION}.linux-amd64.tar.gz
# Color codes
BLUE := \033[36m
NC := \033[0m
BOLD := \033[1m

config_prom: 		# Create & copy configuration files into /etc/prometheus
	@echo ...Creating /etc/prometheus folder
	sudo mkdir -p /etc/prometheus
	@# a workaround go get away with error of permission denied
	sudo chmod 777 /etc/prometheus
	@echo
	@echo ...Copying configuration files
	sudo cp -r etc/prometheus/* /etc/prometheus/
	@echo
config_grafana: 	# Create & copy configuration files into /etc/grafana
	@echo ...Creating /etc/grafana folder
	sudo mkdir -p /etc/grafana
	@# a workaround go get away with error of permission denied
	@#sudo chmod 777 /etc/grafana
	@echo
	@echo ...Copying configuration files
	sudo cp -r etc/grafana/* /etc/grafana/
	@echo

config: config_prom config_grafana	## Create & copy configuration files for Prometheus & grafana

env:				## Create .env file (currently with ALERMGT_HOST var) for docker-compose
	@echo ...Creating .env file for docker-compose
	echo ALERTMGR_HOST=${ALERTMGR_HOST} > .env
	@echo

up: config env		## Build, (re)create & start containers
	@echo
	${DOCKER_COMPOSE_CMD} up -d ${SERVICE}
	@echo
	@echo ' Prometheus --> http://localhost:9091'
	@echo ' Grafana --> http://localhost:3000'

start:				## Starts previously-built containers
	${DOCKER_COMPOSE_CMD} start ${SERVICE}

stop:				## Stops containers (without removing them)
	${DOCKER_COMPOSE_CMD} stop ${SERVICE}

restart: stop start	## Stops containers (via 'stop'), and starts them again (via 'start')

down:				## Stop & delete the running containers & networking
	@echo ...Stopping and deleting all the containers
	${DOCKER_COMPOSE_CMD} down

destroy:			## Stop & delete the running containers, networking & volumes
	@echo ...Stopping and deleting all the containers, volumes and networking
	@sleep 2
	${DOCKER_COMPOSE_CMD} down -v

delete_mount:		## Delete /etc/prometheus & /etc/grafana directories
	@echo ...Deleting mounted directories [/etc/prometheus, /etc/grafana]
	sudo rm -Ir /etc/prometheus /etc/grafana

logs:				## Tail containers log
	@echo ...Tailing last ${TAIL} lines of the logs...Press Ctrl+C to exit
	@sleep 2
	${DOCKER_COMPOSE_CMD} logs -f --tail=${TAIL} ${SERVICE}

ps:					## Display running containers
	${DOCKER_COMPOSE_CMD} ps

backup_logs:		## Backs up containers log
	mkdir -p backup
	${DOCKER_COMPOSE_CMD} logs --no-color > backup/docker.$$(date +'%Y%m%d_%H%M%S').logs

nodex:				## Deploy node-exporter on Node machine(s)
	./setup_node_exporter.sh

reload_prom: 		## Reload Prometheus configuration file
	@echo ...Reload prometheus configuration...
	curl -w "status code: %{http_code}\\n" -X POST http://localhost:9091/-/reload

.ONESHELL:
promtool:	## Download and setup promtool binary
	@if [ -f /usr/local/bin/promtool ]; then \
		echo "Binary already present (/usr/local/bin/promtool)"; \
	else \
		echo ...Downloading promtool and placing it in /usr/local/bin/
		wget --show-progress --progress=bar:force -N -qO- ${PROMTOOL_TZG} | sudo tar zxf - -C /usr/local/bin/ --strip-components=1 --wildcards '**/promtool'
		if [ $$? -eq 0 ]; then echo Downloaded successfully.; fi
	fi
	@echo "Run \`promtool --version\`"

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
	@awk 'BEGIN {FS = ":.*##"; printf "\nTargets:\n"} /^[$$()% a-zA-Z_-]+:.*?##/ { printf "  ${BLUE}%-15s${NC}-- %s\n", $$1, $$2 } /^##@/ { printf "\n${BOLD}%s${NC}\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@printf  "\nOptions:\n"
	@printf "  ${BLUE}%-15s${NC}-- %s${BLUE}%s${NC}\n" "t=numeric" " No. of lines to tail docker logs. E.g " "\`make logs t=10\`"
	@printf "  ${BLUE}%-15s${NC}-- %s${BLUE}%s${NC}\n" "s=string" " Name of the service to run docker logs against. E.g " "\`make logs s=grafana\`"

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
