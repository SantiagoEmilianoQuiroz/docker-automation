#include <cstdlib>
#include <iostream>
#include <sstream>
#include <string>
#include <sys/wait.h>
#include <vector>

struct MenuOption {
    std::string label;
    std::string target;
    bool destructive;
};

bool readChoice(int& choice) {
    std::string input;
    if (!std::getline(std::cin, input)) {
        return false;
    }

    std::istringstream line(input);
    char extra = '\0';
    if (!(line >> choice) || (line >> extra)) {
        return false;
    }
    return true;
}

bool confirmDestructiveAction() {
    std::cout << "Esta accion puede eliminar contenedores o imagenes. "
                 "Escribe 's' para continuar: ";
    std::string answer;
    if (!std::getline(std::cin, answer)) {
        return false;
    }
    return answer == "s" || answer == "S";
}

void printMenu(const std::vector<MenuOption>& options) {
    std::cout << "\n=== Administrador Docker ===\n"
              << "\nRedis\n";
    for (std::size_t i = 0; i < 2; ++i) {
        std::cout << "  " << i + 1 << ". " << options[i].label << '\n';
    }
    std::cout << "\nMonitorizacion\n";
    for (std::size_t i = 2; i < 5; ++i) {
        std::cout << "  " << i + 1 << ". " << options[i].label << '\n';
    }
    std::cout << "\nELK\n";
    for (std::size_t i = 5; i < 11; ++i) {
        std::cout << "  " << i + 1 << ". " << options[i].label << '\n';
    }
    std::cout << "\ncAdvisor\n";
    for (std::size_t i = 11; i < 15; ++i) {
        std::cout << "  " << i + 1 << ". " << options[i].label << '\n';
    }
    std::cout << "\nUtilidades\n"
              << "  " << options.size() << ". " << options.back().label << '\n'
              << "  0. Salir\n"
              << "Selecciona una opcion: ";
}

int main() {
    const std::vector<MenuOption> options = {
        {"Iniciar Redis", "build_redis", false},
        {"Eliminar Redis y su imagen", "delete_redis", true},
        {"Iniciar todo el monitor", "build_monitor", false},
        {"Detener y eliminar contenedores del monitor", "down_monitor", true},
        {"Eliminar contenedores e imagenes del monitor", "down_monitor_all", true},
        {"Construir e iniciar ELK", "build_elk", false},
        {"Detener ELK", "stop_elk", false},
        {"Iniciar ELK", "start_elk", false},
        {"Reiniciar ELK", "restart_elk", false},
        {"Mostrar imagenes y contenedores", "show_elk", false},
        {"Eliminar ELK e imagenes", "deep_delete", true},
        {"Descargar e iniciar cAdvisor", "build_cadvisor", false},
        {"Guardar imagen de cAdvisor", "save_cadvisor", false},
        {"Cargar imagen e iniciar cAdvisor", "load_cadvisor", false},
        {"Eliminar cAdvisor y su imagen", "delete_cadvisor", true},
        {"Mostrar ayuda de Make", "help", false},
    };

    while (true) {
        printMenu(options);
        int choice = -1;
        if (!readChoice(choice)) {
            if (std::cin.eof()) {
                std::cout << "\nFin de entrada. Saliendo.\n";
                return 0;
            }
            std::cout << "Entrada no valida. Introduce el numero de una opcion.\n";
            continue;
        }

        if (choice == 0) {
            std::cout << "Hasta luego.\n";
            return 0;
        }
        if (choice < 1 || static_cast<std::size_t>(choice) > options.size()) {
            std::cout << "Opcion fuera de rango.\n";
            continue;
        }

        const MenuOption& option = options[static_cast<std::size_t>(choice - 1)];
        if (option.destructive && !confirmDestructiveAction()) {
            std::cout << "Operacion cancelada.\n";
            continue;
        }

        std::cout << "\nEjecutando: make " << option.target << "\n\n";
        std::cout.flush();
        const std::string command = "make " + option.target;
        const int result = std::system(command.c_str());
        if (result == -1) {
            std::cerr << "Error: no se pudo iniciar el comando make.\n";
        } else if (WIFEXITED(result) && WEXITSTATUS(result) != 0) {
            std::cerr << "El objetivo 'make " << option.target
                      << "' termino con codigo " << WEXITSTATUS(result) << ".\n";
        } else if (WIFSIGNALED(result)) {
            std::cerr << "El objetivo 'make " << option.target
                      << "' termino por la senal " << WTERMSIG(result) << ".\n";
        } else if (WIFEXITED(result)) {
            std::cout << "Objetivo completado correctamente.\n";
        }
    }
}
