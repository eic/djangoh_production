#!/usr/bin/env bash
set -euo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

BASE=/w/hallb-scshelf2102/clas12/cpaudel/EIC/g5_djangoh_test
SRC=$BASE/physical_final_production/9x275/q2binned

MANIFEST=$SRC/physical_final_manifest.tsv
INTEGRITY=$SRC/integrity_summary.tsv

VALIDATION=$BASE/physical_final_production/9x275/npsim_validation100/physical_final_npsim_100event_validation.tsv

TAG=${TAG:?Set TAG before running this script}

STAGE=$BASE/production_candidate_${TAG}

rm -rf "$STAGE"

mkdir -p \
  "$STAGE/metadata" \
  "$STAGE/scripts" \
  "$STAGE/steering_files/9x275"

DATASETS=$STAGE/metadata/datasets.tsv

printf \
"release_tag\tprocess\tsubprocess\tbeam\tq2_range\trun\tinput_events\twritten_events\tclosure_warning\tskipped_pathological\tskipped_no_hadron\tskipped_empty\troot_entries\tcross_section_pb\tsize_bytes\trelative_path\n" \
> "$DATASETS"

stage_one() {

    local sample=$1
    local subprocess_dir=$2
    local subprocess_label=$3
    local q2=$4
    local xsec=$5

    local source_root
    source_root=$SRC/${sample}.physical_final.eicsmear.ab640.hepmc3.tree.root

    if [ ! -s "$source_root" ]; then
        echo "ERROR: missing source file:"
        echo "$source_root"
        exit 1
    fi

    local row
    row=$(
        awk -F'\t' -v sample="$sample" '
        NR>1 && $1==sample {
            print
            exit
        }' "$MANIFEST"
    )

    if [ -z "$row" ]; then
        echo "ERROR: sample missing from corrected production manifest:"
        echo "$sample"
        exit 1
    fi

    local manifest_sample
    local input_events written_events closure_warning
    local skipped_pathological skipped_no_hadron
    local skipped_empty root_entries status

    IFS=$'\t' read -r \
      manifest_sample \
      input_events \
      written_events \
      closure_warning \
      skipped_pathological \
      skipped_no_hadron \
      skipped_empty \
      root_entries \
      status \
      <<< "$row"

    if [ "$status" != "PASS" ] ||
       [ "$written_events" != "$root_entries" ]; then
        echo "ERROR: corrected filtering/ROOT validation failed:"
        echo "$sample"
        exit 1
    fi

    if ! awk -F'\t' -v sample="$sample" '
        NR>1 &&
        $1==sample &&
        $3==0 &&
        $4==100 &&
        $6=="PASS" {
            found=1
        }
        END {
            exit(found ? 0 : 1)
        }' "$VALIDATION"
    then
        echo "ERROR: 100-event npsim validation missing or failed:"
        echo "$sample"
        exit 1
    fi

    local destination_dir
    destination_dir=$STAGE/DIS/CC/$subprocess_dir/$TAG/9x275/q2_$q2

    mkdir -p "$destination_dir"

    local filename
    filename=${TAG}_DIS-CC-${subprocess_label}_9x275_q2_${q2}_run001.hepmc3.tree.root

    local destination
    destination=$destination_dir/$filename

    ln "$source_root" "$destination" 2>/dev/null ||
    cp -p "$source_root" "$destination"

    local bytes relative
    bytes=$(stat -c '%s' "$destination")
    relative=${destination#"$STAGE/"}

    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
      "$TAG" \
      "DIS-CC" \
      "$subprocess_dir" \
      "9x275" \
      "$q2" \
      "001" \
      "$input_events" \
      "$written_events" \
      "$closure_warning" \
      "$skipped_pathological" \
      "$skipped_no_hadron" \
      "$skipped_empty" \
      "$root_entries" \
      "$xsec" \
      "$bytes" \
      "$relative" \
      >> "$DATASETS"

    echo "STAGED: $relative"
    echo "EVENTS: $root_entries"
}

stage_one \
  cc_g5_eMinus_pPlus_9x275_q2_100to1000 \
  eMinus_pPlus eMinus-pPlus 100to1000 21.440

stage_one \
  cc_g5_eMinus_pPlus_9x275_q2_1000to3000 \
  eMinus_pPlus eMinus-pPlus 1000to3000 10.321

stage_one \
  cc_g5_eMinus_pPlus_9x275_q2_3000to9000 \
  eMinus_pPlus eMinus-pPlus 3000to9000 1.2666

stage_one \
  cc_g5_eMinus_pMinus_9x275_q2_100to1000 \
  eMinus_pMinus eMinus-pMinus 100to1000 9.5747

stage_one \
  cc_g5_eMinus_pMinus_9x275_q2_1000to3000 \
  eMinus_pMinus eMinus-pMinus 1000to3000 3.0338

stage_one \
  cc_g5_eMinus_pMinus_9x275_q2_3000to9000 \
  eMinus_pMinus eMinus-pMinus 3000to9000 0.30165


# ----------------------------------------------------------------------
# Production metadata
# ----------------------------------------------------------------------

cp -p \
  "$MANIFEST" \
  "$STAGE/metadata/physical_final_manifest.tsv"

cp -p \
  "$INTEGRITY" \
  "$STAGE/metadata/integrity_summary.tsv"

cp -p \
  "$VALIDATION" \
  "$STAGE/metadata/npsim_100event_validation.tsv"

if [ -f "$REPO/metadata/physical_final_9x275/software_versions.txt" ]; then
    cp -p \
      "$REPO/metadata/physical_final_9x275/software_versions.txt" \
      "$STAGE/metadata/"
fi


# ----------------------------------------------------------------------
# Corrected production/validation source
# ----------------------------------------------------------------------

cp -p \
  "$REPO/baraks_filter/rewrite_hepmc_physical_final_prod.cxx" \
  "$STAGE/scripts/"

cp -p \
  "$REPO/scripts/run_all_physical_final_9x275.sh" \
  "$STAGE/scripts/"

cp -p \
  "$REPO/scripts/validate_physical_final_9x275_100events.sh" \
  "$STAGE/scripts/"

cp -p \
  "$REPO/scripts/collect_software_versions_9x275.sh" \
  "$STAGE/scripts/"

cp -p \
  "$REPO/scan_prefilter_physical_final.C" \
  "$STAGE/scripts/"

cp -p \
  "$REPO/scan_corrected_evgen_integrity.C" \
  "$STAGE/scripts/"

cp -p \
  "$REPO/run_integrity_all6.sh" \
  "$STAGE/scripts/"


# ----------------------------------------------------------------------
# DJANGOH steering cards
# ----------------------------------------------------------------------

find "$BASE/djangoh_q2binned_9x275" \
  -maxdepth 1 \
  -type f \
  -name '*.in' \
  -exec cp -p {} "$STAGE/steering_files/9x275/" \;


# ----------------------------------------------------------------------
# Checksums for staged production files
# ----------------------------------------------------------------------

(
    cd "$STAGE"

    find DIS \
      -type f \
      -name '*.hepmc3.tree.root' \
      -print0 |
    sort -z |
    xargs -0 sha256sum \
      > metadata/checksums.sha256
)


# ----------------------------------------------------------------------
# README
# ----------------------------------------------------------------------

cat > "$STAGE/README.md" <<EOF2
# DJANGOH 9x275 GeV Polarized Charged-Current DIS Production Inputs

## Release tag

\`$TAG\`

Generator: DJANGOH 4.6.10 with HERACLES

Beam energy: 9x275 GeV

Process: polarized charged-current DIS

## Reason for this production revision

The previous transport preprocessing retained status-4 incoming beam
particles and status-1 final-state particles.

Validation showed that physically terminal hadrons in the TreeToHepMC
records can carry status 2. The status-only filter therefore removed the
hadronic system from a substantial fraction of events, producing
incomplete no-hadron / neutrino-plus-photon-only transport records.

The original pre-filter HepMC records retain the physical hadronic final
state. DJANGOH generation therefore did not need to be repeated.

## Corrected preprocessing

The corrected transport filter determines the physical final state from
HepMC event topology rather than requiring status==1.

It:

1. retains the status-4 incoming beams;
2. selects terminal physical particles with no end vertex;
3. excludes generator-internal quarks, gluons, electroweak propagators,
   strings/clusters and diquarks;
4. writes retained physical final-state particles with transport status 1;
5. recomputes particle energy from momentum and generated mass;
6. records a four-momentum-closure warning above 0.1 GeV;
7. rejects clearly pathological events above 1.0 GeV;
8. rejects no-hadron event records;
9. applies the EIC afterburner profile \`ip6_hidiv_275x9\`;
10. writes the output in HepMC3 ROOT-tree format.

## Validation

All six corrected afterburned EVGEN datasets have:

- zero retained no-hadron events;
- zero retained neutrino-plus-photon-only events;
- zero events without an electron-flavor neutrino.

All six corrected production inputs also passed the 100-event npsim
validation using the ePIC 26.07.1 \`epic_craterlake.xml\` detector
configuration:

- npsim exit code 0 for all six datasets;
- 100/100 events saved for each dataset;
- 6/6 validation status PASS.

The 0.1 GeV closure value is a diagnostic threshold. Retained warning
events have a maximum mismatch below 1 GeV.

## Included datasets

eMinus-pPlus:
- Q2 = 100-1000 GeV2
- Q2 = 1000-3000 GeV2
- Q2 = 3000-9000 GeV2

eMinus-pMinus:
- Q2 = 100-1000 GeV2
- Q2 = 1000-3000 GeV2
- Q2 = 3000-9000 GeV2

## Directory convention

\`DIS/CC/<polarization>/<release-tag>/9x275/q2_<range>/<filename>\`

## Filename convention

\`<release-tag>_DIS-CC-<beam-helicity>_9x275_q2_<range>_run001.hepmc3.tree.root\`

## Metadata

- \`metadata/datasets.tsv\`
- \`metadata/physical_final_manifest.tsv\`
- \`metadata/integrity_summary.tsv\`
- \`metadata/npsim_100event_validation.tsv\`
- \`metadata/checksums.sha256\`
- \`metadata/software_versions.txt\`
- \`steering_files/9x275/\`
- \`scripts/\`

See \`metadata/software_versions.txt\` for the exact generator,
afterburner, ROOT, HepMC3, ePIC, npsim, DD4hep, Geant4 and compiler
versions used for production and validation.
EOF2


echo
echo "============================================================"
echo "Production files"
echo "============================================================"

find "$STAGE/DIS" \
  -type f \
  -name '*.hepmc3.tree.root' |
sort

echo
echo "ROOT file count:"

find "$STAGE/DIS" \
  -type f \
  -name '*.hepmc3.tree.root' |
wc -l

echo
echo "Dataset metadata:"
column -t -s $'\t' "$DATASETS" 2>/dev/null || cat "$DATASETS"

echo
echo "Submission directory:"
echo "$STAGE"

