.PHONY: install-tools install install-dev unit-test help build-container

PROJECT_DIR = $(shell pwd)

default: help

install-tools: ## Install required utilities/tools
	@command -v pdm > /dev/null || { echo >&2 "pdm is not installed. Installing..."; pip install pdm; }
	pdm --version

install: install-tools ## Sync all required dependencies for shellai to work
	pdm sync

install-dev: install-tools ## Sync all development dependencies
	pdm sync --dev

unit-test: install-dev ## Unit test shellai
	@echo "Running tests..."
	@coverage run -m pytest tests
	@coverage report
	@echo "Tests completed."

help: ## Show available make commands
	@echo 'Usage: make <OPTIONS> ... <TARGETS>'
	@echo ''
	@echo 'Available targets are:'
	@echo ''
	@grep -E '^[ a-zA-Z0-9_.-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'
	@echo ''

requirements.txt: pyproject.toml pdm.lock ## Generate requirements.txt file containing hashes for all non-devel packages
	pdm export --prod --format requirements --output requirements.txt

clean: ## Clean project files
	@echo 'Cleanup project specific files...'
	@find . -name '__pycache__' -exec rm -fr {} +
	@find . -name '*.pyc' -exec rm -f {} +
	@find . -name '*.pyo' -exec rm -f {} +
	@rm -rf .pdm-build .ruff_cache .coverage .pdm-python

build-container: ## Build shellai container
	@podman build --tag rhel-lightspeed/shellai:latest -f ./containerfiles/shellai.Containerfile .
