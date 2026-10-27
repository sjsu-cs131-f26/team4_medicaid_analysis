#!/usr/bin/env bash

set -u
set -o pipefail

PROJECT_DIR="../"
MANIFEST="$PROJECT_DIR/state/partition_manifest.tsv"
COMPLETED_DIR="$PROJECT_DIR/state/completed"
LOG_DIR="$PROJECT_DIR/logs"
PARTITION_SCRIPT="$PROJECT_DIR/scripts/run_partition.sh"

mkdir -p "$COMPLETED_DIR" "$LOG_DIR"

NEXT_PARTITION="$(
    awk -F '\t' 'NR > 1 {print $1 "\t" $2}' "$MANIFEST" |
    while IFS=$'\t' read -r partition_id partition_path; do
        if [[ ! -f "$COMPLETED_DIR/${partition_id}.done" ]]; then
            printf '%s\t%s\n' "$partition_id" "$partition_path"
            break
        fi
    done
)"

if [[ -z "$NEXT_PARTITION" ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') no-work all partitions complete"
    exit 0
fi

PARTITION_ID="${NEXT_PARTITION%%$'\t'*}"
PARTITION_PATH="${NEXT_PARTITION#*$'\t'}"
PARTITION_PATH="${PARTITION_PATH//\'/}"
PARTITION_LOG="$LOG_DIR/partition_${PARTITION_ID}.log"
START_TIME="$(date '+%Y-%m-%d %H:%M:%S')"

"$PARTITION_SCRIPT" "$PARTITION_PATH" \
    >"$PARTITION_LOG" 2>&1

EXIT_STATUS=$?
END_TIME="$(date '+%Y-%m-%d %H:%M:%S')"

printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$START_TIME" \
    "$PARTITION_ID" \
    "$PARTITION_PATH" \
    "$START_TIME" \
    "$END_TIME" \
    "$EXIT_STATUS" >> "$LOG_DIR/cron.log"

if [[ "$EXIT_STATUS" -eq 0 ]]; then
    touch "$COMPLETED_DIR/${PARTITION_ID}.done"
    echo "Partition $PARTITION_ID completed successfully"
else
    echo "Partition $PARTITION_ID failed"
fi

exit "$EXIT_STATUS"
