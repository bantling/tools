// SPDX-License-Identifier: Apache-2.0
#include <iostream>
#include "message.h"

int main() {
	std::cout << "Hello " << message();

#ifdef DEBUG
	std::cout << " Debug";
#else
	std::cout << " Release";
#endif

	std::cout << std::endl;
}
