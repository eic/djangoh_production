#!/usr/bin/env bash
set -euo pipefail

BASE=/w/hallb-scshelf2102/clas12/cpaudel/EIC/g5_djangoh_test

SRC=$BASE/djangoh_q2binned_9x275_official_converted
OUT=$BASE/physical_final_production/9x275/q2binned

FILTER=/w/eic-scshelf2104/users/churaman/IMPACTstudy/ANA/djangoh_production/baraks_filter/rewrite_hepmc_physical_final_prod

AB=/w/hallb-scshelf2102/clas12/cpaudel/EIC/afterburner/install_root640/bin/abconv

PROFILE=ip6_hidiv_275x9

mkdir -p "$OUT/logs"

MANIFEST=$OUT/physical_final_manifest.tsv

printf \
"sample\tinput_events\twritten_events\tclosure_warning\tskipped_pathological\tskipped_no_hadron\tskipped_empty\troot_entries\tstatus\n" \
> "$MANIFEST"

process_one()
{
    local sample=$1

    local input=$SRC/${sample}_evt.hepmc
    local filtered=$OUT/${sample}.physical_final.hepmc
    local prefix=$OUT/${sample}.physical_final.eicsmear.ab640
    local root=${prefix}.hepmc3.tree.root

    local filter_log=$OUT/logs/${sample}.filter.log
    local ab_log=$OUT/logs/${sample}.ab640.log

    echo
    echo "============================================================"
    echo "PROCESSING: $sample"
    echo "============================================================"

    if [ ! -s "$input" ]; then
        echo "ERROR: missing input:"
        echo "$input"
        exit 1
    fi

    # --------------------------------------------------------
    # Correct physical-final-state filtering
    # --------------------------------------------------------
    if [ ! -s "$filtered" ]; then

        echo "[1/3] Physical-final filtering"

        "$FILTER" \
            "$input" \
            "$filtered" \
            |& tee "$filter_log"

    else
        echo "[1/3] Existing filtered HepMC found; reusing:"
        echo "$filtered"

        # Existing low-Q2 pMinus log may be outside logs/.
        if [ ! -s "$filter_log" ] &&
           [ -s "$OUT/${sample}.filter.log" ]; then
            cp -p \
              "$OUT/${sample}.filter.log" \
              "$filter_log"
        fi
    fi

    if [ ! -s "$filter_log" ]; then
        echo "ERROR: missing filter log:"
        echo "$filter_log"
        exit 1
    fi

    local input_events
    local written_events
    local closure_warning
    local skipped_pathological
    local skipped_no_hadron
    local skipped_empty

    input_events=$(
        awk -F= '/^SUMMARY_INPUT_EVENTS=/{print $2}' \
        "$filter_log" | tail -1
    )

    written_events=$(
        awk -F= '/^SUMMARY_WRITTEN_EVENTS=/{print $2}' \
        "$filter_log" | tail -1
    )

    closure_warning=$(
        awk -F= '/^SUMMARY_CLOSURE_WARNING=/{print $2}' \
        "$filter_log" | tail -1
    )

    skipped_pathological=$(
        awk -F= '/^SUMMARY_SKIPPED_PATHOLOGICAL=/{print $2}' \
        "$filter_log" | tail -1
    )

    skipped_no_hadron=$(
        awk -F= '/^SUMMARY_SKIPPED_NO_HADRON=/{print $2}' \
        "$filter_log" | tail -1
    )

    skipped_empty=$(
        awk -F= '/^SUMMARY_SKIPPED_EMPTY_EVENTS=/{print $2}' \
        "$filter_log" | tail -1
    )

    echo
    echo "Filter accounting:"
    echo "  input                 = $input_events"
    echo "  written               = $written_events"
    echo "  closure warnings      = $closure_warning"
    echo "  skipped pathological  = $skipped_pathological"
    echo "  skipped no-hadron     = $skipped_no_hadron"
    echo "  skipped empty         = $skipped_empty"

    # --------------------------------------------------------
    # Afterburner
    # --------------------------------------------------------
    if [ ! -s "$root" ]; then

        echo
        echo "[2/3] Afterburner"

        "$AB" \
            -p "$PROFILE" \
            "$filtered" \
            -o "$prefix" \
            > "$ab_log" 2>&1

    else
        echo
        echo "[2/3] Existing afterburned ROOT found; reusing:"
        echo "$root"
    fi

    if [ ! -s "$root" ]; then
        echo "ERROR: afterburned ROOT file not produced"
        tail -60 "$ab_log" || true
        exit 1
    fi

    # --------------------------------------------------------
    # ROOT entry validation
    # --------------------------------------------------------
    echo
    echo "[3/3] ROOT entry validation"

    local root_entries

    root_entries=$(
        root -l -b -q "$root" \
        -e 'TTree *t=(TTree*)_file0->Get("hepmc3_tree"); if(t) cout<<"ROOT_ENTRIES="<<t->GetEntries()<<endl;' \
        2>/dev/null |
        awk -F= '/ROOT_ENTRIES=/{print $2}' |
        tail -1
    )

    echo "ROOT entries = $root_entries"

    local status=PASS

    if [ -z "$root_entries" ] ||
       [ "$root_entries" != "$written_events" ]; then
        status=FAIL
    fi

    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
        "$sample" \
        "$input_events" \
        "$written_events" \
        "$closure_warning" \
        "$skipped_pathological" \
        "$skipped_no_hadron" \
        "$skipped_empty" \
        "$root_entries" \
        "$status" \
        >> "$MANIFEST"

    echo "STATUS = $status"

    if [ "$status" != "PASS" ]; then
        echo "ERROR: event-count validation failed"
        exit 1
    fi
}


process_one cc_g5_eMinus_pPlus_9x275_q2_100to1000
process_one cc_g5_eMinus_pPlus_9x275_q2_1000to3000
process_one cc_g5_eMinus_pPlus_9x275_q2_3000to9000

process_one cc_g5_eMinus_pMinus_9x275_q2_100to1000
process_one cc_g5_eMinus_pMinus_9x275_q2_1000to3000
process_one cc_g5_eMinus_pMinus_9x275_q2_3000to9000

echo
echo "============================================================"
echo "ALL PHYSICAL-FINAL DATASETS FINISHED"
echo "============================================================"

column -t -s $'\t' "$MANIFEST" || cat "$MANIFEST"

