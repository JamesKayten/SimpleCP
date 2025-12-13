# SimpleCP Makefile
# Convenient commands for development and deployment

.PHONY: help install install-dev test lint format clean run daemon claude docker-build docker-run

# Default target
help:
	@echo "SimpleCP Development Commands"
	@echo ""
	@echo "Setup:"
	@echo "  make install        Install production dependencies"
	@echo "  make install-dev    Install development dependencies"
	@echo ""
	@echo "Development:"
	@echo "  make run           Run the daemon (clipboard monitor + API)"
	@echo "  make run-api       Run API server only (no clipboard monitoring)"
	@echo "  make claude        Launch Claude AI assistant"
	@echo "  make test          Run tests with coverage"
	@echo "  make lint          Run linters"
	@echo "  make format        Format code with black and isort"
	@echo ""
	@echo "Docker:"
	@echo "  make docker-build  Build Docker image"
	@echo "  make docker-run    Run Docker container"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean         Remove build artifacts and cache"

# Installation
install:
	pip install -e .

install-dev:
	pip install -e ".[dev]"
	pre-commit install

# Development
run:
	cd backend && python daemon.py

run-api:
	cd backend && python daemon.py --api-only

claude:
	./claude

# Testing
test:
	pytest tests/ -v --cov=. --cov-report=html --cov-report=term

test-unit:
	pytest tests/unit/ -v

test-integration:
	pytest tests/integration/ -v

# Code quality
lint:
	flake8 . --exclude=venv,.venv,build,dist,.eggs
	mypy . --ignore-missing-imports
	bandit -r . -ll --skip B101

format:
	black .
	isort .

format-check:
	black --check .
	isort --check-only .

# Pre-commit
pre-commit:
	pre-commit run --all-files

# Cleanup
clean:
	rm -rf build/
	rm -rf dist/
	rm -rf *.egg-info
	rm -rf htmlcov/
	rm -rf .pytest_cache/
	rm -rf .coverage
	rm -rf .mypy_cache/
	rm -rf .tox/
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.pyo" -delete

# Docker
docker-build:
	docker build -t simplecp:latest .

docker-run:
	docker run -d -p 8000:8000 --name simplecp simplecp:latest

docker-stop:
	docker stop simplecp
	docker rm simplecp

# Documentation
docs:
	@echo "Documentation generation not yet implemented"

# Distribution
dist:
	python -m build
	twine check dist/*
