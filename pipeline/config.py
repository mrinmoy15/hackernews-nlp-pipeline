# pipeline/config.py

import os
from dotenv import load_dotenv
from pathlib import Path

# ── Load environment config ──
# Looks for configs/dev.env, configs/staging.env etc.
ENV = os.environ.get("ENV", "dev")
config_path = Path(__file__).parent.parent / "configs" / f"{ENV}.env"

if config_path.exists():
    load_dotenv(config_path)
else:
    # Fall back to .env at root
    load_dotenv()

# ── GCP Infrastructure ──
# Set by Terraform outputs — comes from infra repo
PROJECT_ID  = os.environ["PROJECT_ID"]
GCS_BUCKET  = os.environ["GCS_BUCKET"]
REGION      = os.environ.get("REGION", "us-central1")

# ── GCS paths ──
GCS_DATA_PATH  = f"gs://{GCS_BUCKET}/hackernews"
GCS_TRAIN_PATH = f"{GCS_DATA_PATH}/train"
GCS_VAL_PATH   = f"{GCS_DATA_PATH}/val"
GCS_TEST_PATH  = f"{GCS_DATA_PATH}/test"

# ── BigQuery ──
BQ_SOURCE_TABLE  = "bigquery-public-data.hacker_news.comments"
BQ_DEST_DATASET  = os.environ.get("BQ_DEST_DATASET", "hackernews_processed")
BQ_DEST_TABLE    = f"{PROJECT_ID}.{BQ_DEST_DATASET}.comments_clean"

# ── Data config ──
MIN_TEXT_LENGTH = int(os.environ.get("MIN_TEXT_LENGTH", "50"))
MAX_TEXT_LENGTH = int(os.environ.get("MAX_TEXT_LENGTH", "512"))
SAMPLE_SIZE     = int(os.environ.get("SAMPLE_SIZE", "100000"))

# ── Model config ──
MODEL_NAME     = os.environ.get("MODEL_NAME", "bert-base-uncased")
MAX_SEQ_LENGTH = int(os.environ.get("MAX_SEQ_LENGTH", "128"))
BATCH_SIZE     = int(os.environ.get("BATCH_SIZE", "32"))

# ── Credentials ──
GOOGLE_APPLICATION_CREDENTIALS = os.environ.get(
    "GOOGLE_APPLICATION_CREDENTIALS",
    "./credentials/pipeline-sa-key.json"
)