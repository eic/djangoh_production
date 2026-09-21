# DJANGOH 9x275 Charged-Current DIS Production Inputs

## Release tag

`DJANGOH4.6.10-2.0`

- Generator: DJANGOH 4.6.10 with HERACLES
- Steering and preprocessing release: 1.0
- Beam energy: 9x275 GeV
- Process: charged-current DIS

## Included datasets

Exactly six production inputs are included:

- eMinus-pPlus, Q2 100 to 1000 GeV2
- eMinus-pPlus, Q2 1000 to 3000 GeV2
- eMinus-pPlus, Q2 3000 to 9000 GeV2
- eMinus-pMinus, Q2 100 to 1000 GeV2
- eMinus-pMinus, Q2 1000 to 3000 GeV2
- eMinus-pMinus, Q2 3000 to 9000 GeV2

No 1k, 5k or 18x275 datasets are included.

## Processing chain

1. Generate events using DJANGOH 4.6.10 and HERACLES.
2. Convert the DJANGOH event output using eic-smear BuildTree.
3. Convert to HepMC3 using TreeToHepMC.
4. Apply the Barak transport filtering program.
5. Retain incoming status-4 beam particles and status-1 final-state particles.
6. Recompute particle energy from momentum and generated mass.
7. Skip an event if an unhadronized final-state parton, string or diquark is found.
8. Apply the EIC afterburner profile `ip6_hidiv_275x9`.
9. Store the result in `hepmc3.tree.root` format.
10. Validate 100 events from every production input using npsim and the
    epic_craterlake detector geometry.

## Directory structure

`DIS/CC/<polarization>/<release-tag>/9x275/q2_<range>/<filename>`

## Filename convention

`<release-tag>_<process>_<beam>_q2_<range>_run<index>.hepmc3.tree.root`

## Metadata

- `metadata/datasets.tsv`: dataset event counts, cross sections and paths.
- `metadata/barak_filter_manifest.tsv`: filtering and ROOT-entry validation.
- `metadata/npsim_100event_validation.tsv`: npsim validation results.
- `metadata/checksums.sha256`: SHA-256 checksums.
- `steering_files/9x275/`: DJANGOH steering cards.
- `scripts/`: filtering, afterburner and validation programs.

## Repository

`https://github.com/churamani100/djangoh_production`
## Contact

**Churamani Paudel**

- New Mexico State University: cpaudel@nmsu.edu
- Jefferson Lab: churaman@jlab.org
## 9x275 GeV CC DIS final-state filtering investigation

Validation of the 9x275 GeV charged-current DIS production identified a loss
of physical hadrons during the existing transport-preprocessing step. The
pre-filter HepMC records retain the hadronic final state, while the previous
status-only filtering can remove terminal hadrons carrying non-status-1
generator statuses.

A topology-based HepMC3 filtering implementation and corrected samples were
produced as a validation candidate. All six candidate samples pass the
event-integrity checks and the 100-event npsim validation.

The implementation is currently under review. The final production workflow
will also be evaluated in the standard eic-shell environment with the
supported HepMC3 libraries before assigning a new production release tag.

Detailed validation information is available in:

metadata/physical_final_9x275/
