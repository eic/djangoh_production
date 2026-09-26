#!/usr/bin/env bash

set -u

PROD="${1:?production directory required}"
VAL="${2:?validation directory required}"

SUMMARY="metadata/release_4.0/npsim_100event_validation.tsv"
COMPACT="$DETECTOR_PATH/epic_craterlake.xml"

mkdir -p "$VAL/root" "$VAL/logs"

echo "Production directory:"
echo "  $PROD"
echo
echo "Validation directory:"
echo "  $VAL"
echo
echo "Compact:"
echo "  $COMPACT"
echo

mapfile -t INPUTS < <(
    find "$PROD" -type f \
      -name 'DJANGOH4.6.10-4.0_*.hepmc3.tree.root' \
      | sort
)

echo "Found ${#INPUTS[@]} release-4.0 input files."
echo

for INPUT in "${INPUTS[@]}"; do

    BASE=$(basename "$INPUT")
    SAMPLE=${BASE%.hepmc3.tree.root}

    # ----------------------------------------------------------
    # Skip samples already validated successfully.
    # ----------------------------------------------------------
    if awk -F'\t' -v s="$SAMPLE" \
       '$1==s && $6=="PASS"{found=1} END{exit !found}' \
       "$SUMMARY"
    then
        echo "SKIP existing PASS: $SAMPLE"
        continue
    fi

    OUTPUT="$VAL/root/${SAMPLE}.test100.edm4hep.root"
    LOG="$VAL/logs/${SAMPLE}.test100.log"

    echo
    echo "============================================================"
    echo "Testing: $SAMPLE"
    echo "Input:   $INPUT"
    echo "============================================================"

    # Remove an incomplete file from an interrupted npsim job.
    rm -f "$OUTPUT"

    npsim \
      --compactFile "$COMPACT" \
      --inputFiles "$INPUT" \
      --outputFile "$OUTPUT" \
      --numberOfEvents 100 \
      > "$LOG" 2>&1

    EC=$?

    EVENTS=0
    SIZE=0

    if [[ -f "$OUTPUT" ]]; then

        SIZE=$(stat -c%s "$OUTPUT" 2>/dev/null || echo 0)

        EVENTS=$(
            root -l -b -q \
              -e "TFile f(\"$OUTPUT\"); TTree *t=(TTree*)f.Get(\"events\"); if(t) std::cout << \"EVENTS_SAVED \" << t->GetEntries() << std::endl;" \
              2>/dev/null \
            | awk '/EVENTS_SAVED/{print $2}' \
            | tail -1
        )

        EVENTS=${EVENTS:-0}
    fi

    if [[ "$EC" -eq 0 && "$EVENTS" -eq 100 ]]; then
        STATUS="PASS"
    else
        STATUS="FAIL"
    fi

    printf "%s\t%s\t%s\t%s\t%s\t%s\n" \
      "$SAMPLE" \
      "$INPUT" \
      "$EC" \
      "$EVENTS" \
      "$SIZE" \
      "$STATUS" >> "$SUMMARY"

    echo "exit code:    $EC"
    echo "events saved: $EVENTS"
    echo "output size:  $SIZE"
    echo "status:       $STATUS"

    if [[ "$STATUS" != "PASS" ]]; then
        echo
        echo "STOPPING because validation failed."
        echo "Inspect:"
        echo "  $LOG"
        exit 1
    fi

done

echo
echo "============================================================"
echo "All remaining npsim validation tests completed."
echo "============================================================"
