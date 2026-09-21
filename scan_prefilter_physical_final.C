#include <iostream>
#include <cmath>
#include <cstdlib>

#include "HepMC3/ReaderAscii.h"
#include "HepMC3/GenEvent.h"
#include "HepMC3/GenParticle.h"

R__LOAD_LIBRARY(libHepMC3)

bool is_internal_generator_object(int pid)
{
    const int a = std::abs(pid);

    // quarks
    if (a >= 1 && a <= 6)
        return true;

    // gluon
    if (a == 21)
        return true;

    // electroweak / generator propagators
    if (a == 23 || a == 24 || a == 25)
        return true;

    // string / cluster-like generator objects
    if (a == 90 || a == 91 || a == 92)
        return true;

    // diquarks
    if (a == 1103 ||
        a == 2101 || a == 2103 ||
        a == 2203 ||
        a == 3101 || a == 3103 ||
        a == 3201 || a == 3203 ||
        a == 3303 ||
        a == 4101 || a == 4103 ||
        a == 4201 || a == 4203 ||
        a == 4301 || a == 4303 ||
        a == 4403 ||
        a == 5101 || a == 5103 ||
        a == 5201 || a == 5203 ||
        a == 5301 || a == 5303 ||
        a == 5401 || a == 5403 ||
        a == 5503)
        return true;

    return false;
}

void scan_prefilter_physical_final(
    const char *filename,
    long long maxEvents=-1)
{
    HepMC3::ReaderAscii reader(filename);

    long long nTot  = 0;
    long long nGood = 0;
    long long nBad  = 0;

    long long nNoPhysical = 0;
    long long nNoHadron   = 0;

    double maxAbsDE = 0.0;
    double maxDP    = 0.0;

    while (!reader.failed() &&
           (maxEvents < 0 || nTot < maxEvents))
    {
        HepMC3::GenEvent evt(
            HepMC3::Units::GEV,
            HepMC3::Units::MM
        );

        reader.read_event(evt);
        if (reader.failed())
            break;

        double Ein=0, pxin=0, pyin=0, pzin=0;
        double Ef =0, pxf =0, pyf =0, pzf =0;

        int nPhysical = 0;
        int nHadron   = 0;

        for (const auto &p : evt.particles()) {

            const auto m = p->momentum();

            if (p->status() == 4) {
                Ein  += m.e();
                pxin += m.px();
                pyin += m.py();
                pzin += m.pz();
                continue;
            }

            // Physical terminal particle:
            // no further generator decay/history vertex
            if (p->end_vertex())
                continue;

            // Remove partonic / propagator / generator bookkeeping
            if (is_internal_generator_object(p->pid()))
                continue;

            ++nPhysical;

            if (std::abs(p->pid()) > 100)
                ++nHadron;

            Ef  += m.e();
            pxf += m.px();
            pyf += m.py();
            pzf += m.pz();
        }

        const double dE  = Ef-Ein;
        const double dpx = pxf-pxin;
        const double dpy = pyf-pyin;
        const double dpz = pzf-pzin;

        const double dP =
            std::sqrt(
                dpx*dpx +
                dpy*dpy +
                dpz*dpz
            );

        ++nTot;

        if (nPhysical == 0)
            ++nNoPhysical;

        if (nHadron == 0)
            ++nNoHadron;

        maxAbsDE = std::max(maxAbsDE,std::abs(dE));
        maxDP    = std::max(maxDP,dP);

        // Same loose test we used previously
        if (std::abs(dE) < 0.1 && dP < 0.1) {
            ++nGood;
        }
        else {
            ++nBad;

            if (nBad <= 20) {
                std::cout
                    << "BAD EVENT "
                    << evt.event_number()
                    << " nPhysical=" << nPhysical
                    << " nHadron=" << nHadron
                    << " dE=" << dE
                    << " dP=" << dP
                    << "\n";
            }
        }

        if (nTot % 50000 == 0) {
            std::cout
                << "Processed " << nTot
                << " good=" << nGood
                << " bad=" << nBad
                << "\n";
        }
    }

    reader.close();

    std::cout
        << "\n========================================\n"
        << "PHYSICAL FINAL-STATE CLOSURE SUMMARY\n"
        << "========================================\n";

    std::cout << "Total events       = " << nTot << "\n";
    std::cout << "Good closure       = " << nGood
              << " (" << 100.0*nGood/nTot << "%)\n";
    std::cout << "Bad closure        = " << nBad
              << " (" << 100.0*nBad/nTot << "%)\n";

    std::cout << "No physical final  = "
              << nNoPhysical << "\n";

    std::cout << "No hadrons         = "
              << nNoHadron << "\n";

    std::cout << "Maximum |dE|       = "
              << maxAbsDE << " GeV\n";

    std::cout << "Maximum dP         = "
              << maxDP << " GeV\n";
}
