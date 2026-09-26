#!/bin/bash
set -euo pipefail

BASE=/w/eic-scshelf2104/users/churaman/IMPACTstudy/ANA/djangoh_QA/eicsmear_djangoh_hack_test
CONV=/w/hallb-scshelf2102/clas12/cpaudel/EIC/hepmc3ascii2root/install/bin/hepmc3ascii2root

TAG=DJANGOH4.6.10-4.0
PROD="$BASE/production_ready_epic"

convert_one () {
    ENERGY="$1"
    POL="$2"
    SAMPLE="$3"
    Q2="$4"

    if [ "$ENERGY" = "9x275" ]; then
        SRC="$BASE/afterburner_9x275_full/$SAMPLE"
    else
        SRC="$BASE/afterburner_18x275_full/$SAMPLE"
    fi

    IN=$(find "$SRC" -maxdepth 1 -type f \
         -name "*_${ENERGY}_q2_${Q2}_evt_afterburned.hepmc" | head -1)

    if [ -z "$IN" ]; then
        echo "ERROR: input not found for $ENERGY $POL q2=$Q2"
        exit 1
    fi

    OUTDIR="$PROD/DIS/CC/$POL/$TAG/$ENERGY/q2_$Q2"
    mkdir -p "$OUTDIR"

    OUT="$OUTDIR/${TAG}_DIS-CC-${POL//_/-}_${ENERGY}_q2_${Q2}_run001.hepmc3.tree.root"

    echo
    echo "============================================================"
    echo "Converting"
    echo "  ENERGY : $ENERGY"
    echo "  POL    : $POL"
    echo "  Q2     : $Q2"
    echo "  INPUT  : $IN"
    echo "  OUTPUT : $OUT"
    echo "============================================================"

    "$CONV" "$IN" "$OUT"

    if [ ! -s "$OUT" ]; then
        echo "ERROR: output missing or empty"
        exit 1
    fi

    ls -lh "$OUT"
}

# ------------------------------------------------------------
# 9 x 275
# ------------------------------------------------------------

convert_one 9x275 eMinus_pPlus  pPlus_low   100to1000
convert_one 9x275 eMinus_pPlus  pPlus_mid   1000to3000
convert_one 9x275 eMinus_pPlus  pPlus_high  3000to9000

convert_one 9x275 eMinus_pMinus pMinus_low  100to1000
convert_one 9x275 eMinus_pMinus pMinus_mid  1000to3000
convert_one 9x275 eMinus_pMinus pMinus_high 3000to9000

# ------------------------------------------------------------
# 18 x 275
# ------------------------------------------------------------

convert_one 18x275 eMinus_pPlus  pPlus_low   100to1000
convert_one 18x275 eMinus_pPlus  pPlus_mid   1000to10000
convert_one 18x275 eMinus_pPlus  pPlus_high  10000to100000

convert_one 18x275 eMinus_pMinus pMinus_low  100to1000
convert_one 18x275 eMinus_pMinus pMinus_mid  1000to10000
convert_one 18x275 eMinus_pMinus pMinus_high 10000to100000

echo
echo "============================================================"
echo "ALL 12 CONVERSIONS COMPLETE"
echo "Production tree:"
echo "$PROD"
echo "============================================================"
