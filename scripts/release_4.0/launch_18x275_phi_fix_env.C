#include "TSystem.h"
#include "TROOT.h"
#include "TString.h"
#include <iostream>

void launch_18x275_phi_fix_env()
{
    TString oldpath = gSystem->GetDynamicPath();

    gSystem->SetDynamicPath(
        "/w/eic-scshelf2104/users/churaman/IMPACTstudy/ANA/djangoh_QA/eicsmear_djangoh_hack_test/install-phi-fix/lib:" + oldpath
    );

    std::cout << "Resolved BEFORE LOAD = "
              << gSystem->DynamicPathName("libeicsmear.so", kTRUE)
              << std::endl;

    int rc = gSystem->Load(
        "/w/eic-scshelf2104/users/churaman/IMPACTstudy/ANA/djangoh_QA/eicsmear_djangoh_hack_test/install-phi-fix/lib/libeicsmear.so"
    );

    std::cout << "Load return code = " << rc << std::endl;

    if (rc < 0) {
        std::cerr << "ERROR: failed to load fixed libeicsmear.so" << std::endl;
        return;
    }

    gROOT->ProcessLine(
        ".x /w/eic-scshelf2104/users/churaman/IMPACTstudy/ANA/djangoh_QA/eicsmear_djangoh_hack_test/build_18x275_phi_fix_env.C"
    );
}
