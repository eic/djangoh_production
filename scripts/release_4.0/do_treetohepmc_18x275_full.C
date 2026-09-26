#include "TSystem.h"
#include "eicsmear/functions.h"
#include <iostream>

void do_treetohepmc_18x275_full()
{
    const char* input  = gSystem->Getenv("TTH_INPUT");
    const char* outdir = gSystem->Getenv("TTH_OUTDIR");

    std::cout << "INPUT  = " << input  << std::endl;
    std::cout << "OUTDIR = " << outdir << std::endl;

    Long64_t ret = TreeToHepMC(
        input,
        outdir,
        1000000000LL,
        erhic::HepMC_outtype::HepMC3
    );

    std::cout << "TreeToHepMC returned = " << ret << std::endl;
}
