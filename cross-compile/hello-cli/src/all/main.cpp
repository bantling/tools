#include <iostream>

int main() {
	std::cout << "Hello";
#ifdef WINDOWS
	std::cout << " Windows";
#else
	std::cout << " Linux";
#endif
#ifdef DEBUG
	std::cout << " Debug";
#else
	std::cout << " Release";
#endif
	std::cout << std::endl;
}