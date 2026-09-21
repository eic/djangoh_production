#include "HepMC3/ReaderAscii.h"
#include "HepMC3/WriterAscii.h"
#include "HepMC3/GenEvent.h"
#include "HepMC3/GenVertex.h"
#include "HepMC3/GenParticle.h"

#include <cmath>
#include <cstdlib>
#include <iostream>
#include <memory>

using namespace HepMC3;

// Generator-internal objects that must NOT be transported.
static bool is_internal_generator_object(int pid)
{
    const int a = std::abs(pid);

    // quarks
    if (a >= 1 && a <= 6)
        return true;

    // gluon
    if (a == 21)
        return true;

    // electroweak / Higgs propagators
    if (a == 23 || a == 24 || a == 25)
        return true;

    // string / cluster-like generator bookkeeping
    if (a == 90 || a == 91 || a == 92)
        return true;

    // diquarks
    switch (a) {
        case 1103:
        case 2101:
        case 2103:
        case 2203:
        case 3101:
        case 3103:
        case 3201:
        case 3203:
        case 3303:
        case 4101:
        case 4103:
        case 4201:
        case 4203:
        case 4301:
        case 4303:
        case 4403:
        case 5101:
        case 5103:
        case 5201:
        case 5203:
        case 5301:
        case 5303:
        case 5401:
        case 5403:
        case 5503:
            return true;
    }

    return false;
}

static bool is_hadron(int pid)
{
    const int a = std::abs(pid);

    // Adequate for this DJANGOH CC final-state validation.
    return (a > 100 && !is_internal_generator_object(pid));
}

int main(int argc, char **argv)
{
    if (argc < 3) {
        std::cerr
            << "Usage: " << argv[0]
            << " input.hepmc output.hepmc [max_events]\n";
        return 1;
    }

    const char *input_name  = argv[1];
    const char *output_name = argv[2];

    long long max_events = -1;

    if (argc >= 4)
        max_events = std::atoll(argv[3]);

    ReaderAscii reader(input_name);
    WriterAscii writer(output_name);

    if (reader.failed()) {
        std::cerr
            << "ERROR: could not open input "
            << input_name << "\n";
        return 2;
    }

    GenEvent evt;

    long long input_events = 0;
    long long written_events = 0;

    long long skipped_empty = 0;
    long long skipped_no_hadron = 0;
    
    long long closure_warning = 0;
    long long skipped_pathological = 0;


    long long internal_terminal_objects = 0;

    while (!reader.failed()) {

        if (max_events >= 0 &&
            input_events >= max_events)
            break;

        evt.clear();
        reader.read_event(evt);

        if (reader.failed())
            break;

        ++input_events;

        GenEvent new_evt(
            evt.momentum_unit(),
            evt.length_unit()
        );

        new_evt.set_event_number(
            evt.event_number()
        );

        auto vtx =
            std::make_shared<GenVertex>();

        vtx->set_position(
            FourVector(0,0,0,0)
        );

        double Ein=0.0;
        double pxin=0.0;
        double pyin=0.0;
        double pzin=0.0;

        double Eout=0.0;
        double pxout=0.0;
        double pyout=0.0;
        double pzout=0.0;

        int n_final = 0;
        int n_hadron = 0;
        int n_beam = 0;

        for (const auto &p :
             evt.particles())
        {
            const double px =
                p->momentum().px();

            const double py =
                p->momentum().py();

            const double pz =
                p->momentum().pz();

            const double p3 =
                p->momentum().p3mod();

            const double mass =
                p->generated_mass() > 0.0 ?
                p->generated_mass() : 0.0;

            // Preserve existing production convention:
            // recompute E from |p| and generated mass.
            const FourVector momentum(
                px,
                py,
                pz,
                std::hypot(p3,mass)
            );

            // ------------------------------------------------
            // Incoming beam particles
            // ------------------------------------------------
            if (p->status() == 4) {

                auto q =
                    std::make_shared<GenParticle>(
                        momentum,
                        p->pid(),
                        4
                    );

                vtx->add_particle_in(q);

                ++n_beam;

                Ein  += momentum.e();
                pxin += momentum.px();
                pyin += momentum.py();
                pzin += momentum.pz();

                continue;
            }

            // ------------------------------------------------
            // Correct physical final-state definition:
            //
            //   1. terminal in HepMC graph
            //   2. not generator-internal bookkeeping
            //
            // DO NOT require original status==1.
            // ------------------------------------------------

            if (p->end_vertex())
                continue;

            if (is_internal_generator_object(
                    p->pid()))
            {
                ++internal_terminal_objects;
                continue;
            }

            // IMPORTANT:
            // normalize selected physical terminal particles
            // to status 1 for transport / detector simulation.
            auto q =
                std::make_shared<GenParticle>(
                    momentum,
                    p->pid(),
                    1
                );

            vtx->add_particle_out(q);

            ++n_final;

            if (is_hadron(p->pid()))
                ++n_hadron;

            Eout  += momentum.e();
            pxout += momentum.px();
            pyout += momentum.py();
            pzout += momentum.pz();
        }

        if (n_beam < 2 ||
            n_final == 0)
        {
            ++skipped_empty;
            continue;
        }

        if (n_hadron == 0) {
            ++skipped_no_hadron;
            continue;
        }

        const double dE =
            Eout-Ein;

        const double dpx =
            pxout-pxin;

        const double dpy =
            pyout-pyin;

        const double dpz =
            pzout-pzin;

        const double dP =
            std::sqrt(
                dpx*dpx +
                dpy*dpy +
                dpz*dpz
            );

        // ------------------------------------------------
        // Closure diagnostics.
        //
        // 0.1 GeV is retained as a diagnostic threshold,
        // but mildly imperfect events are NOT rejected.
        // ------------------------------------------------
        if (std::abs(dE) >= 0.1 ||
            dP >= 0.1)
        {
            ++closure_warning;
        }

        // ------------------------------------------------
        // Reject only clearly pathological event records.
        // ------------------------------------------------
        if (std::abs(dE) >= 1.0 ||
            dP >= 1.0)
        {
            ++skipped_pathological;

            if (skipped_pathological <= 20) {
                std::cerr
                    << "SKIP_PATHOLOGICAL"
                    << " event="
                    << evt.event_number()
                    << " nFinal="
                    << n_final
                    << " nHadron="
                    << n_hadron
                    << " dE="
                    << dE
                    << " dP="
                    << dP
                    << "\n";
            }

            continue;
        }

        new_evt.add_vertex(vtx);
        writer.write_event(new_evt);

        ++written_events;

        if (input_events % 10000 == 0) {
            std::cout
                << "Processed "
                << input_events
                << " input; wrote "
                << written_events
                
    << "; closure warnings "
                << closure_warning

                << "; skip no-hadron "
                << skipped_no_hadron
                << "; skip empty "
                << skipped_empty
                << "\n";
        }
    }

    reader.close();
    writer.close();

    std::cout
        << "\n========================================\n"
        << "PHYSICAL-FINAL FILTER SUMMARY\n"
        << "========================================\n";

    std::cout
        << "SUMMARY_INPUT_EVENTS="
        << input_events << "\n";

    std::cout
        << "SUMMARY_WRITTEN_EVENTS="
        << written_events << "\n";

    std::cout
        << "SUMMARY_CLOSURE_WARNING="
        << closure_warning << "\n";

    std::cout
        << "SUMMARY_SKIPPED_PATHOLOGICAL="
        << skipped_pathological << "\n";

    std::cout
        << "SUMMARY_SKIPPED_NO_HADRON="
        << skipped_no_hadron << "\n";

    std::cout
        << "SUMMARY_SKIPPED_EMPTY_EVENTS="
        << skipped_empty << "\n";

    std::cout
        << "SUMMARY_INTERNAL_TERMINAL_OBJECTS="
        << internal_terminal_objects << "\n";

    return 0;
}
