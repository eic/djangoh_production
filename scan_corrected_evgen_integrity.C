#include <iostream>
#include <cmath>
#include <cstdlib>

#include "HepMC3/ReaderRootTree.h"
#include "HepMC3/GenEvent.h"
#include "HepMC3/GenParticle.h"

R__LOAD_LIBRARY(libHepMC3)
R__LOAD_LIBRARY(libHepMC3rootIO)

void scan_corrected_evgen_integrity(const char *filename)
{
    std::cout << "Opening:\n" << filename << "\n\n";

    HepMC3::ReaderRootTree reader(filename);

    if (reader.failed()) {
        std::cerr << "ERROR: could not open file\n";
        return;
    }

    long long nTotal = 0;
    long long nGood = 0;
    long long nBad = 0;

    long long nNoHadron = 0;
    long long nBadNoHadron = 0;
    long long nBadHasHadron = 0;
    long long nGoodNoHadron = 0;

    long long nNuGammaOnly = 0;
    long long nBadNuGammaOnly = 0;

    long long nNuNot1 = 0;
    long long nNuZero = 0;
    long long nNuMoreThan1 = 0;

    double maxAbsDE = 0.0;
    double maxDP = 0.0;

    while (!reader.failed()) {

        HepMC3::GenEvent evt(
            HepMC3::Units::GEV,
            HepMC3::Units::MM
        );

        reader.read_event(evt);

        if (reader.failed())
            break;

        double Ein=0, pxin=0, pyin=0, pzin=0;
        double Eout=0, pxout=0, pyout=0, pzout=0;

        int nHadron = 0;
        int nNu = 0;
        int nPhoton = 0;
        int nOtherFinal = 0;

        for (const auto &p : evt.particles()) {

            const auto m = p->momentum();
            const int pid = p->pid();
            const int st  = p->status();

            if (st == 4) {
                Ein  += m.e();
                pxin += m.px();
                pyin += m.py();
                pzin += m.pz();
            }

            if (st != 1)
                continue;

            Eout  += m.e();
            pxout += m.px();
            pyout += m.py();
            pzout += m.pz();

            const int a = std::abs(pid);

            if (a > 100)
                ++nHadron;

            if (a == 12)
                ++nNu;
            else if (pid == 22)
                ++nPhoton;
            else if (a <= 100)
                ++nOtherFinal;
        }

        const double dE  = Eout - Ein;
        const double dpx = pxout - pxin;
        const double dpy = pyout - pyin;
        const double dpz = pzout - pzin;

        const double dP =
            std::sqrt(
                dpx*dpx +
                dpy*dpy +
                dpz*dpz
            );

        const bool good =
            std::abs(dE) < 0.1 &&
            dP < 0.1;

        const bool noHadron =
            (nHadron == 0);

        const bool nuGammaOnly =
            noHadron &&
            nNu >= 1 &&
            nOtherFinal == 0;

        ++nTotal;

        if (good) ++nGood;
        else      ++nBad;

        if (noHadron)
            ++nNoHadron;

        if (!good && noHadron)
            ++nBadNoHadron;

        if (!good && !noHadron)
            ++nBadHasHadron;

        if (good && noHadron)
            ++nGoodNoHadron;

        if (nuGammaOnly)
            ++nNuGammaOnly;

        if (!good && nuGammaOnly)
            ++nBadNuGammaOnly;

        if (nNu != 1)
            ++nNuNot1;

        if (nNu == 0)
            ++nNuZero;

        if (nNu > 1)
            ++nNuMoreThan1;

        if (std::abs(dE) > maxAbsDE)
            maxAbsDE = std::abs(dE);

        if (dP > maxDP)
            maxDP = dP;

        if (nTotal % 2000 == 0)
            std::cout
                << "Processed "
                << nTotal << "\n";
    }

    reader.close();

    std::cout
        << "\n========================================\n"
        << "EVGEN INTEGRITY SUMMARY\n"
        << "========================================\n";

    std::cout
        << "Total events       = " << nTotal << "\n";

    std::cout
        << "Good 4-momentum    = " << nGood
        << " (" << 100.0*nGood/nTotal << "%)\n";

    std::cout
        << "Bad 4-momentum     = " << nBad
        << " (" << 100.0*nBad/nTotal << "%)\n";

    std::cout
        << "No hadrons         = " << nNoHadron << "\n";

    std::cout
        << "Bad && no hadrons  = " << nBadNoHadron << "\n";

    std::cout
        << "Bad && has hadrons = " << nBadHasHadron << "\n";

    std::cout
        << "Good && no hadrons = " << nGoodNoHadron << "\n";

    std::cout
        << "nu+gamma only      = " << nNuGammaOnly << "\n";

    std::cout
        << "Bad nu+gamma only  = " << nBadNuGammaOnly << "\n";

    std::cout
        << "nNu != 1           = " << nNuNot1 << "\n";

    std::cout
        << "nNu == 0           = " << nNuZero << "\n";

    std::cout
        << "nNu > 1            = " << nNuMoreThan1 << "\n";

    std::cout
        << "Maximum |dE|       = " << maxAbsDE << " GeV\n";

    std::cout
        << "Maximum dP         = " << maxDP << " GeV\n";
}
