#include "TSystem.h"
#include "TROOT.h"
#include "TString.h"
#include <iostream>

void launch_treetohepmc_18x275_full()
{
    const char* env = gSystem->Getenv("EICSMEAR_PREFIX");

    if (!env) {
        std::cerr
            << "ERROR: EICSMEAR_PREFIX is not set.\n"
            << "Example:\n"
            << "  export EICSMEAR_PREFIX=/path/to/eic-smear/install-phi-fix\n";
        return;
    }

    TString prefix = env;
    TString oldpath = gSystem->GetDynamicPath();

    gSystem->SetDynamicPath(
        prefix + "/lib:" + oldpath
    );

    gSystem->AddIncludePath(
        TString("-I") + prefix + "/include"
    );

    std::cout << "EICSMEAR_PREFIX = "
              << prefix << std::endl;

    std::cout << "Resolved libeicsmear.so = "
              << gSystem->DynamicPathName("libeicsmear.so", kTRUE)
              << std::endl;

    int rc = gSystem->Load(
        prefix + "/lib/libeicsmear.so"
    );

    std::cout << "Load return code = "
              << rc << std::endl;

    if (rc < 0) {
        std::cerr << "ERROR: could not load libeicsmear.so"
                  << std::endl;
        return;
    }

    gROOT->ProcessLine(
        ".x scripts/release_4.0/do_treetohepmc_18x275_full.C"
    );
}
