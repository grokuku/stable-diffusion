# get the current machines 
export HOSTIP := $(shell ip route get 1.1.1.1 | grep -oP 'src \K\S+')
export PUID := $(shell id -u)
export PGID := $(shell id -g)

# Parse the available profiles from the docker-compose.yml
AVAILABLE_PROFILES := $(shell grep -oP 'profiles:\s*\[\K[^\]]+' docker-compose.yml | sed 's/\s*//g' | tr '\n' ' ')

# Include .env variable in the current environment
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

# Default target
.DEFAULT_GOAL := help
.PHONY: help up down start stop logs

# Help target
help:
	@echo "Available targets:"
	@echo "  up [profile]   Start the specified profile (e.g., make up fooocus)"
	@echo "  down [profile] Stop the specified profile (e.g., make down fooocus)"
	@echo "  help           Show this help message"

# up target
up:
	docker compose --profile $(filter-out $@,$(MAKECMDGOALS)) up

# down/stop target
down: stop
stop:
	docker compose --profile $(filter-out $@,$(MAKECMDGOALS)) down

# start target
start:
	docker compose --profile $(filter-out $@,$(MAKECMDGOALS)) up -d

logs:
	docker compose --profile $(filter-out $@,$(MAKECMDGOALS)) logs -f

# Allow extra arguments for the up and down targets
%:
	@:
