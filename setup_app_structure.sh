#!/bin/bash
# setup_app_structure.sh
# Creates the full hackernews-nlp-pipeline directory structure
# Run from: ~/my_linux_projects/projects/hackernews-nlp-pipeline

set -e  # exit on any error

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  hackernews-nlp-pipeline — App Structure Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Pipeline package ──
echo ""
echo "Creating pipeline package..."
mkdir -p pipeline
touch pipeline/__init__.py
touch pipeline/config.py
touch pipeline/bigquery_to_gcs.py
touch pipeline/ray_data_pipeline.py
touch pipeline/tokenization.py
echo "  ✅ pipeline/__init__.py"
echo "  ✅ pipeline/config.py"
echo "  ✅ pipeline/bigquery_to_gcs.py"
echo "  ✅ pipeline/ray_data_pipeline.py"
echo "  ✅ pipeline/tokenization.py"

# ── Models package ──
echo ""
echo "Creating models package..."
mkdir -p models
touch models/__init__.py
touch models/bert_classifier.py
echo "  ✅ models/__init__.py"
echo "  ✅ models/bert_classifier.py"

# ── Tests package ──
echo ""
echo "Creating tests package..."
mkdir -p tests
touch tests/__init__.py
touch tests/test_config.py
touch tests/test_bigquery_to_gcs.py
touch tests/test_ray_data_pipeline.py
touch tests/test_tokenization.py
echo "  ✅ tests/__init__.py"
echo "  ✅ tests/test_config.py"
echo "  ✅ tests/test_bigquery_to_gcs.py"
echo "  ✅ tests/test_ray_data_pipeline.py"
echo "  ✅ tests/test_tokenization.py"

# ── Configs directory ──
echo ""
echo "Creating configs..."
mkdir -p configs
touch configs/dev.env.example
touch configs/staging.env.example
touch configs/prod.env.example
echo "  ✅ configs/dev.env.example"
echo "  ✅ configs/staging.env.example"
echo "  ✅ configs/prod.env.example"

# ── Notebooks ──
echo ""
echo "Creating notebooks..."
mkdir -p notebooks
touch notebooks/01_data_exploration.ipynb
touch notebooks/02_tokenization_exploration.ipynb
touch notebooks/03_model_exploration.ipynb
echo "  ✅ notebooks/01_data_exploration.ipynb"
echo "  ✅ notebooks/02_tokenization_exploration.ipynb"
echo "  ✅ notebooks/03_model_exploration.ipynb"

# ── Scripts ──
echo ""
echo "Creating scripts..."
mkdir -p scripts
touch scripts/run_pipeline.sh
touch scripts/run_tests.sh
echo "  ✅ scripts/run_pipeline.sh"
echo "  ✅ scripts/run_tests.sh"

# ── Credentials directory ──
echo ""
echo "Creating credentials directory..."
mkdir -p credentials
touch credentials/.gitkeep
echo "  ✅ credentials/ (gitignored)"

# ── GitHub Actions ──
echo ""
echo "Creating GitHub Actions..."
mkdir -p .github/workflows
touch .github/workflows/pipeline.yml
echo "  ✅ .github/workflows/pipeline.yml"

# ── Root level files ──
echo ""
echo "Creating root files..."
touch requirements.txt
touch Dockerfile
touch .dockerignore
echo "  ✅ requirements.txt"
echo "  ✅ Dockerfile"
echo "  ✅ .dockerignore"

# ── .gitignore ──
echo ""
echo "Updating .gitignore..."

add_if_missing() {
    local LINE="$1"
    local FILE=".gitignore"
    if ! grep -qxF "${LINE}" "${FILE}" 2>/dev/null; then
        echo "${LINE}" >> "${FILE}"
    fi
}

touch .gitignore

add_if_missing "# Python"
add_if_missing "__pycache__/"
add_if_missing "*.pyc"
add_if_missing "*.pyo"
add_if_missing "*.pyd"
add_if_missing ".venv/"
add_if_missing "*.egg-info/"
add_if_missing "dist/"
add_if_missing "build/"
add_if_missing ""
add_if_missing "# Credentials — never commit"
add_if_missing "credentials/*.json"
add_if_missing "credentials/*.pem"
add_if_missing ""
add_if_missing "# Environment configs with secrets"
add_if_missing "configs/dev.env"
add_if_missing "configs/staging.env"
add_if_missing "configs/prod.env"
add_if_missing ".env"
add_if_missing ""
add_if_missing "# Ray"
add_if_missing "/tmp/ray/"
add_if_missing ""
add_if_missing "# Checkpoints"
add_if_missing "checkpoints/"
add_if_missing ""
add_if_missing "# Jupyter"
add_if_missing ".ipynb_checkpoints/"
add_if_missing ""
add_if_missing "# OS"
add_if_missing ".DS_Store"
add_if_missing "Thumbs.db"
add_if_missing ""
add_if_missing "# Keep credentials folder in git (empty)"
add_if_missing "!credentials/.gitkeep"

echo "  ✅ .gitignore updated"

# ── Final structure summary ──
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Structure created successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "hackernews-nlp-pipeline/"
echo "├── Makefile                      ← all commands"
echo "├── requirements.txt              ← Python dependencies"
echo "├── Dockerfile                    ← containerization"
echo "├── .dockerignore"
echo "├── .gitignore"
echo "├── README.md"
echo "├── credentials/                  ← gitignored, SA key goes here"
echo "├── .github/"
echo "│   └── workflows/"
echo "│       └── pipeline.yml          ← CI/CD"
echo "├── pipeline/                     ← main application code"
echo "│   ├── __init__.py"
echo "│   ├── config.py                 ← reads from env vars"
echo "│   ├── bigquery_to_gcs.py        ← BQ → GCS"
echo "│   ├── ray_data_pipeline.py      ← GCS → Ray Data"
echo "│   └── tokenization.py           ← HuggingFace tokenizer"
echo "├── models/                       ← model definitions"
echo "│   ├── __init__.py"
echo "│   └── bert_classifier.py        ← BERT model"
echo "├── tests/                        ← unit tests"
echo "│   ├── __init__.py"
echo "│   ├── test_config.py"
echo "│   ├── test_bigquery_to_gcs.py"
echo "│   ├── test_ray_data_pipeline.py"
echo "│   └── test_tokenization.py"
echo "├── configs/                      ← env config templates"
echo "│   ├── dev.env.example"
echo "│   ├── staging.env.example"
echo "│   └── prod.env.example"
echo "├── notebooks/                    ← exploration notebooks"
echo "│   ├── 01_data_exploration.ipynb"
echo "│   ├── 02_tokenization_exploration.ipynb"
echo "│   └── 03_model_exploration.ipynb"
echo "└── scripts/"
echo "    ├── run_pipeline.sh           ← run full pipeline"
echo "    └── run_tests.sh              ← run tests"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Next steps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  1. bash setup_app_structure.sh  ← already done!"
echo "  2. Fill in each file step by step"
echo "  3. make install                 ← install dependencies"
echo "  4. make pipeline                ← run full pipeline"
echo ""