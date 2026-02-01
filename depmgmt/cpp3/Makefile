.PHONY: all
all: build build/cpp3.a

build:
	mkdir build

build/cpp3.o: src/cpp3.cpp include/cpp3.h
	g++ -I include -c -o $@ $<

build/cpp3.a: build/cpp3.o
	ar rvs $@ $<

.PHONY: clean
clean:
	rm -rf build

