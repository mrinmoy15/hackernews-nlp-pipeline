import os
import time
from google.cloud import bigquery
from google.cloud import storage

from pipeline.config import (
    PROJECT_ID,
    GCS_BUCKET,
    BQ_SOURCE_TABLE,
    BQ_DEST_TABLE,
    BQ_LOCATION,
    MIN_TEXT_LENGTH,
    MAX_TEXT_LENGTH,
    SAMPLE_SIZE,
    GOOGLE_APPLICATION_CREDENTIALS,
)
from pipeline.logger import get_logger

# ── Logger ──
logger = get_logger(__name__)

# ── Set credentials ──
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = GOOGLE_APPLICATION_CREDENTIALS

def get_bigquery_client() -> bigquery.Client:
    """Create and return BigQuery client."""
    logger.info(f"Initializing BigQuery client for project: {PROJECT_ID}")
    return bigquery.Client(project=PROJECT_ID)

def get_storage_client() -> storage.Client:
    """Create and return GCS client."""
    logger.info(f"Initializing GCS client for project: {PROJECT_ID}")
    return storage.Client(project=PROJECT_ID)


def transform_to_bq_table(client: bigquery.Client) -> str:
    """
    Step 1 — Run SQL transforms in BigQuery and save
    results to a destination table.

    No data leaves BigQuery — purely server side.
    Returns the destination table ID.
    """
    logger.info("**************************************************")
    logger.info("Step 1: BigQuery Transform → BQ Table")
    logger.info("***************************************************")
    logger.info(f"Source: {BQ_SOURCE_TABLE}")
    logger.info(f"Dest:   {BQ_DEST_TABLE}")
    logger.info(f"Rows:   {SAMPLE_SIZE:,}")

    query = f"""
    CREATE OR REPLACE TABLE `{BQ_DEST_TABLE}` AS

    WITH cleaned AS (
        SELECT
            id,
            TRIM(
                REGEXP_REPLACE(
                    REGEXP_REPLACE(text, r'<[^>]+>', ' '),
                    r'\\s+', ' '
                )
            ) AS text,
            `by` AS author,          -- ← was author, now `by`
            timestamp,               -- ← was time_ts, now timestamp
            LENGTH(
                TRIM(
                    REGEXP_REPLACE(
                        REGEXP_REPLACE(text, r'<[^>]+>', ' '),
                        r'\\s+', ' '
                    )
                )
            ) AS char_length,
            ARRAY_LENGTH(
                SPLIT(
                    TRIM(
                        REGEXP_REPLACE(
                            REGEXP_REPLACE(text, r'<[^>]+>', ' '),
                            r'\\s+', ' '
                        )
                    ), ' '
                )
            ) AS word_count,
            CASE
                WHEN MOD(ABS(FARM_FINGERPRINT(CAST(id AS STRING))), 10) < 8
                    THEN 'train'
                WHEN MOD(ABS(FARM_FINGERPRINT(CAST(id AS STRING))), 10) < 9
                    THEN 'val'
                ELSE 'test'
            END AS split
        FROM `{BQ_SOURCE_TABLE}`
        WHERE
            type = 'comment'
            AND deleted IS NULL
            AND dead IS NULL
            AND text IS NOT NULL
            AND `by` IS NOT NULL     -- ← was author
            AND LENGTH(TRIM(text)) >= {MIN_TEXT_LENGTH}
            AND LENGTH(TRIM(text)) <= {MAX_TEXT_LENGTH}
            AND text NOT LIKE '%http%'
            AND text NOT LIKE '%www.%'
        LIMIT {SAMPLE_SIZE}
    )
    SELECT * FROM cleaned
    ORDER BY RAND()
    """
    
    logger.info("Running BigQuery transform job...")
    start = time.time()

    job = client.query(
        query,
        location=BQ_LOCATION
    )
    
    job.result()  # wait for completion

    elapsed = time.time() - start
    logger.info(f"Transform complete in {elapsed:.1f}s")

    # Get row counts per split
    stats_query = f"""
    SELECT
        split,
        COUNT(*) as row_count
    FROM `{BQ_DEST_TABLE}`
    GROUP BY split
    ORDER BY split
    """

    stats = client.query(stats_query, location=BQ_LOCATION).to_dataframe()
    for _, row in stats.iterrows():
        logger.info(f"  {row['split']:5s}: {row['row_count']:,} rows")

    return BQ_DEST_TABLE


def export_bq_to_gcs(client: bigquery.Client) -> None:
    """
    Step 2 — Export BQ table directly to GCS as
    sharded parquet files.

    Fully server side — no data in Python memory.
    Handles petabyte scale datasets.
    """
    logger.info("*************************************************")
    logger.info("Step 2: BQ Table → GCS Export")
    logger.info("**************************************************")

    for split in ["train", "val", "test"]:
        gcs_path = f"gs://{GCS_BUCKET}/hackernews/{split}/*.parquet"

        logger.info(f"Exporting {split} → {gcs_path}")

        # Export only this split from the BQ table
        # Uses a view/query to filter by split
        split_query = f"""
        SELECT * EXCEPT(split)
        FROM `{BQ_DEST_TABLE}`
        WHERE split = '{split}'
        """

        # Create temp table for this split
        split_table = f"{BQ_DEST_TABLE}_{split}"
        create_job  = client.query(
            f"CREATE OR REPLACE TABLE `{split_table}` AS {split_query}",
            location=BQ_LOCATION
        )
        create_job.result()

        # Export temp table directly to GCS
        job_config = bigquery.ExtractJobConfig(
            destination_format = bigquery.DestinationFormat.PARQUET,
            compression        = bigquery.Compression.SNAPPY,
        )

        extract_job = client.extract_table(
            source            = split_table,
            destination_uris  = [gcs_path],
            job_config        = job_config,
            location          = BQ_LOCATION,
        )

        start   = time.time()
        extract_job.result()  # wait for completion
        elapsed = time.time() - start

        logger.info(f"✅ {split} exported in {elapsed:.1f}s → {gcs_path}")

        # Cleanup temp split table
        client.delete_table(split_table)
        logger.debug(f"Cleaned up temp table: {split_table}")
        

def verify_gcs_export(storage_client: storage.Client) -> None:
    """
    Step 3 — Verify all splits exported correctly to GCS.
    """
    logger.info("**************************************************")
    logger.info("Step 3: Verify GCS Export")
    logger.info("**************************************************")

    bucket = storage_client.bucket(GCS_BUCKET)
    total_size = 0

    for split in ["train", "val", "test"]:
        blobs = list(bucket.list_blobs(
            prefix=f"hackernews/{split}/"
        ))
        parquet_blobs = [b for b in blobs if b.name.endswith(".parquet")]
        split_size    = sum(b.size for b in parquet_blobs) / (1024 * 1024)
        total_size   += split_size

        logger.info(
            f"{split:5s}: "
            f"{len(parquet_blobs)} shards | "
            f"{split_size:.1f} MB | "
            f"gs://{GCS_BUCKET}/hackernews/{split}/"
        )

    logger.info(f"Total size: {total_size:.1f} MB")


def run() -> None:
    """
    Run the full production BigQuery → GCS pipeline.

    Flow:
        1. SQL transforms in BigQuery → saved as BQ table
           (no data in Python memory)
        2. BQ table → GCS parquet shards
           (server side export, no memory limit)
        3. Verify GCS export
    """
    logger.info("**************************************************")
    logger.info("BigQuery → GCS Pipeline (Production Mode)")
    logger.info(f"Project:  {PROJECT_ID}")
    logger.info(f"Bucket:   gs://{GCS_BUCKET}")
    logger.info(f"BQ Dest:  {BQ_DEST_TABLE}")
    logger.info("**************************************************")

    bq_client      = get_bigquery_client()
    storage_client = get_storage_client()

    # Step 1 — transform in BigQuery
    transform_to_bq_table(bq_client)

    # Step 2 — export directly to GCS
    export_bq_to_gcs(bq_client)

    # Step 3 — verify
    verify_gcs_export(storage_client)

    logger.info("**************************************************")
    logger.info("✅ Pipeline complete!")
    logger.info(f"Data ready at: gs://{GCS_BUCKET}/hackernews/")
    logger.info("***************************************************")


if __name__ == "__main__":
    run()