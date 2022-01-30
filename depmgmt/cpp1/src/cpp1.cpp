#include "cpp1.h"
#include "cpp2.h"
#include <iostream>

std::string Cpp1::stringValue() {
    return std::string("Cpp1") + Cpp2::stringValue();
}

int main() {
	std::cout << Cpp1::stringValue() << std::endl;
}

