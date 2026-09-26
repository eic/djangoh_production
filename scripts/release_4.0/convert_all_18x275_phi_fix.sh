#!/usr/bin/env bash
set -euo pipefail

QA=/w/eic-scshelf2104/users/churaman/IMPACTstudy/ANA/djangoh_QA/eicsmear_djangoh_hack_test
IN=/w/eic-scshelf2104/users/churaman/IMPACTstudy/ANA/djangoh_production/runs/18x275
OUT=$QA/root_phi_fix_18x275_full

mkdir -p "$OUT"

samples=(
"pPlus_low cc_g5_eMinus_pPlus_18x275_q2_100to1000_evt.dat 500000"
"pMinus_low cc_g5_eMinus_pMinus_18x275_q2_100to1000_evt.dat 500000"
"pPlus_mid cc_g5_eMinus_pPlus_18x275_q2_1000to10000_evt.dat 500000"
"pMinus_mid cc_g5_eMinus_pMinus_18x275_q2_1000to10000_evt.dat 500000"
"pPlus_high cc_g5_eMinus_pPlus_18x275_q2_10000to100000_evt.dat 1000000"
"pMinus_high cc_g5_eMinus_pMinus_18x275_q2_10000to100000_evt.dat 1000000"
)

echo "========== VERIFYING SIX INPUT FILES =========="

for item in "${samples[@]}"; do
    read -r tag file expected <<< "$item"

    input="$IN/$file"

    if [[ ! -s "$input" ]]; then
        echo "ERROR: missing input: $input"
        exit 1
    fi

    last=$(tail -2000 "$input" | awk '$1==0 {n=$2} END{print n}')

    echo "$tag : last event = $last ; expected = $expected"

    if [[ "$last" != "$expected" ]]; then
        echo "ERROR: $tag is not complete. No conversion started."
        exit 1
    fi
done

echo
echo "All six generator files are complete."
echo

for item in "${samples[@]}"; do
    read -r tag file expected <<< "$item"

    input="$IN/$file"
    outdir="$OUT/$tag"

    mkdir -p "$outdir"

    export EIC_INPUT="$input"
    export EIC_OUTDIR="$outdir"
    export EIC_LOGFILE="$outdir/buildtree.log"

    echo
    echo "============================================================"
    echo "CONVERTING: $tag"
    echo "$input"
    echo "============================================================"

    root -l -b -q "$QA/launch_18x275_phi_fix_env.C" \
        2>&1 | tee "$outdir/console.log"

    if ! grep -q 'BuildTree returned = 0' "$outdir/console.log"; then
        echo "ERROR: BuildTree did not return 0 for $tag"
        exit 1
    fi

    n_nan=$(grep -c 'Phi_0_2pi.*NaN' "$outdir/console.log" || true)

    echo "$tag : Phi_0_2pi NaN warnings = $n_nan"

    if [[ "$n_nan" -ne 0 ]]; then
        echo "ERROR: unexpected NaN warning in $tag"
        exit 1
    fi

    touch "$outdir/DONE"

    echo "$tag : COMPLETE"
done

echo
echo "============================================================"
echo "ALL SIX 18x275 BUILDTREE CONVERSIONS COMPLETE"
echo "============================================================"
