# DJANGOH4.6.10-4.0

This release contains the steering and preprocessing configuration for
polarized charged-current DIS DJANGOH samples at 9x275 GeV and 18x275 GeV.

## Generator

- Generator: DJANGOH/HERACLES 4.6.10
- Repository release tag: DJANGOH4.6.10-4.0
- Process: DIS charged current
- Electron beam: e-
- Proton polarization samples: pPlus and pMinus

## Beam energies and Q2 bins

### 9x275 GeV

- Q2 = 100--1000 GeV^2
- Q2 = 1000--3000 GeV^2
- Q2 = 3000--9000 GeV^2

Steering cards are in:

steering_cards/9x275/

### 18x275 GeV

- Q2 = 100--1000 GeV^2
- Q2 = 1000--10000 GeV^2
- Q2 = 10000--100000 GeV^2

Steering cards are in:

steering_cards/18x275/

## Preprocessing chain

DJANGOH evt.dat
  -> eic-smear BuildTree
  -> EICTree ROOT
  -> TreeToHepMC (HepMC3)
  -> EIC afterburner
  -> hepmc3ascii2root
  -> hepmc3.tree.root

No intermediate transport/status filter is applied between
TreeToHepMC and the afterburner.

## eic-smear

Base version: eic-smear 1.2.3.

A local numerical safeguard is applied in computeHermesPhiH().
The cosine argument passed to TMath::ACos is clamped to [-1,1]
to protect against floating-point excursions such as:

1.0000000000000002

which otherwise produce NaN values.

The exact modification is stored in:

metadata/release_4.0/eic-smear-1.2.3-computeHermesPhiH-clamp.patch

Additional provenance is stored in:

metadata/release_4.0/eic-smear_provenance.txt
metadata/release_4.0/software_versions.tsv

## Afterburner

The ROOT-6.40-compatible abconv build was used.

- ROOT: 6.40.04
- CLHEP: 2.4.7.2
- 9x275 preset: ip6_hidiv_275x9
- 18x275 preset: ip6_hidiv_275x18

## HepMC3 ROOT conversion

Final HepMC3 ASCII files are converted using eic/hepmc3ascii2root.

Final filenames follow the epic-prod convention:

<release-tag>_<physics-process>_<energy>_q2_<min>to<max>_run001.hepmc3.tree.root

Example:

DJANGOH4.6.10-4.0_DIS-CC-eMinus-pPlus_9x275_q2_100to1000_run001.hepmc3.tree.root

## 9x275 afterburner QA

Input and afterburned output event counts agree exactly for all six samples:

- pMinus high: 999955 -> 999955; ReaderAscii warnings: 1
- pMinus low: 499952 -> 499952; ReaderAscii warnings: 2
- pMinus mid: 499976 -> 499976; ReaderAscii warnings: 3
- pPlus high: 999949 -> 999949; ReaderAscii warnings: 0
- pPlus low: 499936 -> 499936; ReaderAscii warnings: 3
- pPlus mid: 499977 -> 499977; ReaderAscii warnings: 2

Total: 3999745 input events and 3999745 afterburned events.

## 18x275 QA note

The 18x275 samples were converted using the same eic-smear 1.2.3
phi-fix workflow and the ip6_hidiv_275x18 afterburner preset.

A larger number of HepMC3 ReaderAscii diagnostics was observed in the
pPlus low-Q2 sample and is being tracked separately as part of production QA.
