#include "HepMC3/ReaderAscii.h"
#include "HepMC3/GenEvent.h"
#include "HepMC3/GenVertex.h"
#include "HepMC3/GenParticle.h"

#include <iostream>
#include <memory>

int main(int argc, char** argv) {
    if (argc < 3) {
        std::cerr << "Usage: print_vertices input.hepmc event_number\n";
        return 1;
    }

    std::string filename = argv[1];
    int target_event = std::stoi(argv[2]);

    HepMC3::ReaderAscii reader(filename);
    HepMC3::GenEvent evt;

    int current_event = 0;
    while (!reader.failed()) {
        reader.read_event(evt);
        if (reader.failed()) break;

        if (current_event == target_event) {
            std::cout << "Event " << evt.event_number()
                      << " with " << evt.vertices().size()
                      << " vertices and " << evt.particles().size()
                      << " particles\n";

            for (auto v : evt.vertices()) {
                auto pos = v->position();
                std::cout << "Vertex id=" << v->id()
                          << " at (" << pos.x() << ", "
                          << pos.y() << ", "
                          << pos.z() << ", "
                          << pos.t() << ")\n";

                std::cout << "  Incoming:";
                for (auto p : v->particles_in()) {
                    std::cout << " [id=" << p->id()
                              << ", pdg=" << p->pid()
                              << ", status=" << p->status() << "]";
                }
                std::cout << "\n";

                std::cout << "  Outgoing:";
                for (auto p : v->particles_out()) {
                    std::cout << " [id=" << p->id()
                              << ", pdg=" << p->pid()
                              << ", status=" << p->status() << "]";
                }
                std::cout << "\n";
            }

            break;
        }

        evt.clear();
        current_event++;
    }

    reader.close();
    return 0;
}

