#include <iostream>

int main() {
	std::cout << "Hello";
#if defined LINUX
	std::cout << " Linux";
#elif defined WINDOWS
	std::cout << " Windows";
#elif defined OSX
	std::cout << " OSX";
#elif defined FREEBSD
	std::cout << " FreeBSD";
#else
#error Unsupported platform
#endif

#ifdef DEBUG
	std::cout << " Debug";
#else
	std::cout << " Release";
#endif

	std::cout << std::endl;
}
