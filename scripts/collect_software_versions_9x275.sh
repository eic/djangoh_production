#!/usr/bin/env bash
set -u

OUT=${1:-metadata/physical_final_9x275/software_versions.txt}

mkdir -p "$(dirname "$OUT")"

ABDIR=/w/hallb-scshelf2102/clas12/cpaudel/EIC/afterburner
AB640=$ABDIR/install_root640/bin/abconv

{
echo "============================================================"
echo "9x275 CC DIS corrected EVGEN production software record"
echo "============================================================"
echo

echo "Production physics configuration"
echo "--------------------------------"
echo "Process                  : charged-current DIS"
echo "Beam                     : e- p, 9x275 GeV"
echo "Generator                : DJANGOH 4.6.10"
echo "Radiative corrections    : HERACLES"
echo "Afterburner profile      : ip6_hidiv_275x9"
echo "Detector validation      : epic_craterlake.xml"
echo

echo "Conversion environments"
echo "--------------------------------"
echo "eic-smear BuildTree      : EIC2020b"
echo "TreeToHepMC              : EIC2021a"
echo

echo "Corrected HepMC filter"
echo "--------------------------------"
echo "Filter source            : rewrite_hepmc_physical_final_prod.cxx"
echo "Final-state definition   : terminal physical particles"
echo "Output transport status  : 1"
echo "Closure warning threshold: 0.1 GeV"
echo "Pathological threshold   : 1.0 GeV"
echo

echo "Afterburner"
echo "--------------------------------"
if [ -d "$ABDIR/.git" ]; then
    echo -n "Git commit               : "
    git -C "$ABDIR" rev-parse HEAD 2>/dev/null || true

    echo -n "Git description          : "
    git -C "$ABDIR" describe --tags --always 2>/dev/null || true
fi

echo "Afterburner executable   : $AB640"

if [ -x "$AB640" ]; then
    echo
    echo "Afterburner shared-library dependencies:"
    ldd "$AB640" 2>/dev/null | \
        grep -E 'ROOT|libTree|libCore|libRIO|libHist|HepMC|CLHEP|yaml|gsl' || true
fi

echo
echo "Current validation environment"
echo "--------------------------------"

echo -n "ePIC release path        : "
echo "${DETECTOR_PATH:-NOT_SET}"

echo -n "ROOT version             : "
root-config --version 2>/dev/null || echo "UNKNOWN"

echo -n "ROOTSYS                  : "
echo "${ROOTSYS:-NOT_SET}"

echo -n "ROOT executable          : "
command -v root 2>/dev/null || echo "UNKNOWN"

echo -n "HepMC3 version           : "
if command -v HepMC3-config >/dev/null 2>&1; then
    HepMC3-config --version 2>/dev/null || echo "UNKNOWN"
else
    echo "UNKNOWN"
fi

echo -n "HepMC3-config            : "
command -v HepMC3-config 2>/dev/null || echo "UNKNOWN"

echo -n "npsim executable         : "
command -v npsim 2>/dev/null || echo "UNKNOWN"

echo -n "npsim version            : "
NPSIM_REAL=$(readlink -f "$(command -v npsim)" 2>/dev/null || true)
if [[ "$NPSIM_REAL" =~ npsim-([0-9.]+)- ]]; then
    echo "${BASH_REMATCH[1]}"
else
    echo "UNKNOWN"
fi

echo -n "npsim package path       : "
dirname "$(dirname "$NPSIM_REAL")" 2>/dev/null || echo "UNKNOWN"

echo -n "DD4hep version           : "
DD4DIR=$(find /opt/software/linux-x86_64_v2 -maxdepth 1 -type d -name 'dd4hep-*' | head -1)
if [[ "$DD4DIR" =~ dd4hep-([0-9.]+)- ]]; then
    echo "${BASH_REMATCH[1]}"
else
    echo "UNKNOWN"
fi

echo "DD4hep package path      : ${DD4DIR:-UNKNOWN}"

echo -n "Geant4 version           : "
G4DIR=$(find /opt/software/linux-x86_64_v2 -maxdepth 1 -type d -name 'geant4-[0-9]*' ! -name 'geant4-data-*' | head -1)
if [[ "$G4DIR" =~ geant4-([^-/]+)- ]]; then
    echo "${BASH_REMATCH[1]}"
else
    echo "UNKNOWN"
fi

echo "Geant4 package path      : ${G4DIR:-UNKNOWN}"

echo -n "Geant4 data version      : "
G4DATADIR=$(find /opt/software/linux-x86_64_v2 -maxdepth 1 -type d -name 'geant4-data-*' | head -1)
if [[ "$G4DATADIR" =~ geant4-data-([0-9.]+)- ]]; then
    echo "${BASH_REMATCH[1]}"
else
    echo "UNKNOWN"
fi

echo -n "Python version           : "
python3 -c 'import platform; print(platform.python_version())' 2>/dev/null || echo "UNKNOWN"

echo -n "CMake version            : "
cmake --version 2>/dev/null | head -1 || echo "UNKNOWN"

echo -n "C++ compiler             : "
c++ --version 2>/dev/null | head -1 || echo "UNKNOWN"

echo -n "GCC version              : "
gcc --version 2>/dev/null | head -1 || echo "UNKNOWN"

echo
echo "Detector configuration"
echo "--------------------------------"
echo "DETECTOR_PATH            : ${DETECTOR_PATH:-NOT_SET}"

if [ -n "${DETECTOR_PATH:-}" ]; then
    echo "Compact XML              : $DETECTOR_PATH/epic_craterlake.xml"

    if [ -e "$DETECTOR_PATH/epic_craterlake.xml" ]; then
        echo -n "Compact XML SHA256       : "
        sha256sum "$DETECTOR_PATH/epic_craterlake.xml" | awk '{print $1}'
    fi
fi

echo
echo "Repository"
echo "--------------------------------"

REPO=/w/eic-scshelf2104/users/churaman/IMPACTstudy/ANA/djangoh_production

if [ -d "$REPO/.git" ]; then
    echo -n "Production repo commit   : "
    git -C "$REPO" rev-parse HEAD 2>/dev/null || true

    echo -n "Production repo branch   : "
    git -C "$REPO" branch --show-current 2>/dev/null || true
fi

echo
echo "Generated on"
echo "--------------------------------"
date -Is

} > "$OUT"

echo "Saved software record:"
echo "$OUT"
