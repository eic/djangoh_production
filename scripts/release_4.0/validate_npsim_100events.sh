#!/usr/bin/env bash

set -u

if [ $# -lt 2 ]; then
    echo "Usage:"
    echo "  $0 <production_ready_epic_dir> <validation_output_dir>"
    exit 1
fi

PROD="$1"
VAL="$2"

REPO_ROOT=$(git rev-parse --show-toplevel)
SUMMARY="$REPO_ROOT/metadata/release_4.0/npsim_100event_validation.tsv"

mkdir -p "$VAL/logs" "$VAL/root"

if [ -z "${DETECTOR_PATH:-}" ]; then
    echo "ERROR: DETECTOR_PATH is not set"
    exit 1
fi

if ! command -v npsim >/dev/null 2>&1; then
    echo "ERROR: npsim is not on PATH"
    exit 1
fi

COMPACT="$DETECTOR_PATH/epic_craterlake.xml"

if [ ! -f "$COMPACT" ]; then
    echo "ERROR: compact file not found:"
    echo "  $COMPACT"
    exit 1
fi

EPIC_PREFIX=$(dirname "$(dirname "$DETECTOR_PATH")")
export LD_LIBRARY_PATH=$EPIC_PREFIX/lib:$EPIC_PREFIX/lib64:${LD_LIBRARY_PATH:-}
export DD4HEP_LIBRARY_PATH=$EPIC_PREFIX/lib:$EPIC_PREFIX/lib64:${DD4HEP_LIBRARY_PATH:-}

printf \
"sample\tinput_root\texit_code\tevents_saved\toutput_size_bytes\tstatus\n" \
> "$SUMMARY"

mapfile -t INPUTS < <(
    find "$PROD" -type f \
      -name 'DJANGOH4.6.10-4.0_*.hepmc3.tree.root' \
      | sort
)

echo "Production directory:"
echo "  $PROD"
echo
echo "Compact:"
echo "  $COMPACT"
echo
echo "Found ${#INPUTS[@]} release-4.0 input files."

if [ "${#INPUTS[@]}" -ne 12 ]; then
    echo "ERROR: expected exactly 12 production files"
    printf '%s\n' "${INPUTS[@]}"
    exit 2
fi

FAILURES=0

for INPUT in "${INPUTS[@]}"; do

    FILE=$(basename "$INPUT")
    SAMPLE=${FILE%.hepmc3.tree.root}

    OUTPUT="$VAL/root/${SAMPLE}.test100.edm4hep.root"
    LOG="$VAL/logs/${SAMPLE}.test100.log"

    echo
    echo "============================================================"
    echo "Testing: $SAMPLE"
    echo "Input:   $INPUT"
    echo "============================================================"

    rm -f "$OUTPUT" "$LOG"

    npsim \
      --compactFile "$COMPACT" \
      --inputFiles "$INPUT" \
      --outputFile "$OUTPUT" \
      --numberOfEvents 100 \
      > "$LOG" 2>&1

    EC=$?
    SAVED=$(grep -c 'Saving EDM4hep event' "$LOG" 2>/dev/null || true)
    SIZE=$(stat -c '%s' "$OUTPUT" 2>/dev/null || echo 0)

    if [ "$EC" -eq 0 ] &&
       [ "$SAVED" -eq 100 ] &&
       [ "$SIZE" -gt 1000 ]; then
        STATUS=PASS
    else
        STATUS=FAIL
        FAILURES=$((FAILURES+1))
    fi

    printf "%s\t%s\t%s\t%s\t%s\t%s\n" \
      "$SAMPLE" "$INPUT" "$EC" "$SAVED" "$SIZE" "$STATUS" \
      >> "$SUMMARY"

    echo "exit code:    $EC"
    echo "events saved: $SAVED"
    echo "output size:  $SIZE"
    echo "status:       $STATUS"

    if [ "$STATUS" = "FAIL" ]; then
        echo
        echo "Last 60 log lines:"
        tail -60 "$LOG"
    fi
done

echo
echo "============================================================"
echo "FINAL VALIDATION SUMMARY"
echo "============================================================"

awk -F'\t' '
NR>1 {
    total++
    if ($6=="PASS") pass++
    else {
        fail++
        print "FAILED:", $1
    }
}
END {
    print "Total:", total
    print "PASS: ", pass+0
    print "FAIL: ", fail+0
}' "$SUMMARY"

echo
echo "Summary written to:"
echo "  $SUMMARY"

if [ "$FAILURES" -ne 0 ]; then
    exit 3
fi

exit 0
