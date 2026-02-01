#include "cpp2.h"
#include "cpp3.h"

std::string Cpp2::stringValue() {
    return std::string("Cpp2-1") + Cpp3::stringValue();
}

