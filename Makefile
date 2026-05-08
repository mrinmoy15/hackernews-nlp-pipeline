# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# hackernews-nlp-pipeline Makefile
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

.PHONY: help setup
.DEFAULT_GOAL := help

ROOT_DIR := $(shell pwd)
ENV ?= dev
PYTHON := $(ROOT_DIR)/.venv/bin/python
PIP    := $(ROOT_DIR)/.venv/bin/pip
UV     := uv

help:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  hackernews-nlp-pipeline — Available commands"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "  make help     → show this message"
	@echo "  make setup    → create application structure"
	@echo ""
	@echo "  make install-dependencies  → install uv + venv + packages"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

setup:
	@echo "Creating application structure..."
	@bash $(ROOT_DIR)/setup_app_structure.sh
	@echo "✅ Done — structure created"

install-dependencies:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  Installing dependencies"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "Step 1: Installing uv..."
	@if ! command -v uv &> /dev/null; then \
		curl -LsSf https://astral.sh/uv/install.sh | sh; \
		echo "✅ uv installed"; \
	else \
		echo "⏭️  uv already installed — skipping"; \
	fi
	@echo ""
	@echo "Step 2: Creating virtual environment..."
	@if [ ! -d ".venv" ]; then \
		$$HOME/.local/bin/uv venv .venv --python 3.12; \
		echo "✅ venv created"; \
	else \
		echo "⏭️  venv already exists — skipping"; \
	fi
	@echo ""
	@echo "Step 3: Installing Python packages..."
	$$HOME/.local/bin/uv pip install \
		--python $(ROOT_DIR)/.venv/bin/python \
		-r requirements.txt
	@echo ""
	@echo "✅ All dependencies installed!"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  Now activate: source .venv/bin/activate"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"