# Corrected 9x275 GeV Polarized CC DIS EVGEN Production

This directory documents the corrected 9x275 GeV polarized charged-current
DIS EVGEN production inputs.

## Issue

The previous HepMC transport filter retained incoming status-4 beam
particles and only status-1 final-state particles.

Validation showed that physically terminal hadrons in the TreeToHepMC
records can carry status 2. The status-only filter therefore removed the
hadronic final state from a substantial fraction of events.

In the original low-Q2 samples, the affected fractions were:

- pMinus, Q2 = 100-1000 GeV2: 37.3738%
- pPlus,  Q2 = 100-1000 GeV2: 41.5181%

The affected records were no-hadron / neutrino-plus-photon-only events
with large four-momentum non-closure.

The original pre-filter HepMC records retain the physical hadronic final
state, so DJANGOH generation did not need to be repeated.

## Correction

The corrected filter:

- retains the incoming status-4 beams;
- selects terminal physical particles using HepMC topology;
- excludes generator-internal quarks, gluons, electroweak propagators,
  strings/clusters, and diquarks;
- writes retained physical final-state particles with transport status 1;
- records a closure warning above 0.1 GeV;
- rejects clearly pathological events above 1.0 GeV;
- rejects no-hadron records.

Production filter:

baraks_filter/rewrite_hepmc_physical_final_prod.cxx

## Final validation

Across all six corrected afterburned EVGEN samples:

- retained no-hadron events: 0
- retained neutrino-plus-photon-only events: 0
- events without an electron-flavor neutrino: 0

All six corrected EVGEN inputs passed the 100-event npsim validation
using the ePIC 26.07.1 epic_craterlake.xml detector configuration:

- datasets tested: 6
- npsim exit code: 0 for all six
- events saved: 100/100 for all six
- final validation: 6/6 PASS

## Metadata

- physical_final_manifest.tsv
  Event accounting from corrected filtering and afterburner production.

- integrity_summary.tsv
  Full corrected EVGEN integrity validation.

- physical_final_npsim_100event_validation.tsv
  Final 100-event npsim validation of the corrected six EVGEN inputs.

- checksums.sha256
  SHA-256 checksums of the corrected EVGEN files.

- software_versions.txt
  Detailed production and validation software environment.

- software_versions.tsv
  Compact software-version record.

- afterburner_root640_CMakeCache.txt
  Build configuration for the ROOT 6.40 afterburner rebuild.

## Software summary

Generator: DJANGOH 4.6.10 with HERACLES

Afterburner: v0.2.1
Afterburner commit:
740f6356225fc81c9baee5c76d6dd19976c99417

HepMC3: 3.03.00
ROOT: 6.40.04
CLHEP: 2.4.7.2

ePIC detector release: 26.07.1
npsim: 1.8.0
DD4hep: 1.37
Geant4: 11.4.1.east

Detector configuration:
epic_craterlake.xml

Detector XML SHA256:
e7b487c09ea650b6073e1577a7849e64f07cc18811f54cdaf84575a6b956eca6

The corrected production is intended to replace the affected
status-only-filtered EVGEN inputs.

Proposed corrected production release:
DJANGOH4.6.10-3.0
