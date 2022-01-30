.PHONY: all
all: build/deps build/cpp1

build/deps:
	mvn generate-sources

build/cpp1.o: src/cpp1.cpp include/cpp1.h
	g++ -std=c++14 -Wall -Wextra -pedantic -Weffc++ -Wshadow -Werror -I include -I build/deps/include -c -o $@ $<

build/cpp1: build/cpp1.o
	g++ -o $@ $< build/deps/lib/cpp2.a build/deps/lib/cpp3.a

.PHONY: clean
clean:
	rm -rf build

