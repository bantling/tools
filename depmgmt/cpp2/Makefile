.PHONY: all
all: build/deps build/cpp2.a

build/deps:
	mvn generate-sources

build/cpp2.o: src/cpp2.cpp include/cpp2.h
	g++ -I include -I build/deps/include -c -o $@ $<

build/cpp2.a: build/cpp2.o
	ar rvs $@ $<

.PHONY: clean
clean:
	rm -rf build

