#!/usr/bin/env bash
set -euo pipefail

OUT=/w/hallb-scshelf2102/clas12/cpaudel/EIC/g5_djangoh_test/physical_final_production/9x275/q2binned
MACRO=/w/eic-scshelf2104/users/churaman/IMPACTstudy/ANA/djangoh_production/scan_corrected_evgen_integrity.C

mkdir -p "$OUT/integrity"

SAMPLES=(
  cc_g5_eMinus_pPlus_9x275_q2_100to1000
  cc_g5_eMinus_pPlus_9x275_q2_1000to3000
  cc_g5_eMinus_pPlus_9x275_q2_3000to9000
  cc_g5_eMinus_pMinus_9x275_q2_100to1000
  cc_g5_eMinus_pMinus_9x275_q2_1000to3000
  cc_g5_eMinus_pMinus_9x275_q2_3000to9000
)

SUMMARY="$OUT/integrity_summary.tsv"

printf \
"sample\ttotal\tgood\tbad\tno_hadrons\tnu_gamma_only\tnNu0\tnNuGT1\tmax_dE\tmax_dP\n" \
> "$SUMMARY"

for S in "${SAMPLES[@]}"; do

    FILE="$OUT/${S}.physical_final.eicsmear.ab640.hepmc3.tree.root"
    LOG="$OUT/integrity/${S}.integrity.log"

    echo
    echo "============================================================"
    echo "SCANNING: $S"
    echo "============================================================"

    if [ ! -s "$FILE" ]; then
        echo "ERROR: missing file:"
        echo "$FILE"
        exit 1
    fi

    root -l -b -q \
      "${MACRO}(\"${FILE}\")" \
      |& tee "$LOG"

    total=$(awk '/^Total events/{print $4}' "$LOG")
    good=$(awk '/^Good 4-momentum/{print $4}' "$LOG")
    bad=$(awk '/^Bad 4-momentum/{print $4}' "$LOG")
    nohad=$(awk '/^No hadrons/{print $4}' "$LOG")
    nugamma=$(awk '/^nu\+gamma only/{print $4}' "$LOG")
    nnu0=$(awk '/^nNu == 0/{print $4}' "$LOG")
    nnugt1=$(awk '/^nNu > 1/{print $4}' "$LOG")
    maxde=$(awk '/^Maximum \|dE\|/{print $4}' "$LOG")
    maxdp=$(awk '/^Maximum dP/{print $4}' "$LOG")

    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
      "$S" \
      "$total" \
      "$good" \
      "$bad" \
      "$nohad" \
      "$nugamma" \
      "$nnu0" \
      "$nnugt1" \
      "$maxde" \
      "$maxdp" \
      >> "$SUMMARY"

done

echo
echo "============================================================"
echo "FINAL SIX-SAMPLE INTEGRITY SUMMARY"
echo "============================================================"

column -t -s $'\t' "$SUMMARY" || cat "$SUMMARY"
