#include "eicsmear/functions.h"
#include "TSystem.h"
#include <iostream>

void build_18x275_phi_fix_env()
{
    const char* input   = gSystem->Getenv("EIC_INPUT");
    const char* outdir  = gSystem->Getenv("EIC_OUTDIR");
    const char* logfile = gSystem->Getenv("EIC_LOGFILE");

    if (!input || !outdir || !logfile) {
        std::cerr << "Missing EIC_INPUT/EIC_OUTDIR/EIC_LOGFILE" << std::endl;
        return;
    }

    std::cout << "INPUT  = " << input << std::endl;
    std::cout << "OUTDIR = " << outdir << std::endl;

    Long64_t ret = BuildTree(input, outdir, 0, logfile);

    std::cout << "BuildTree returned = " << ret << std::endl;
}
