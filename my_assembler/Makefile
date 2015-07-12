COMPILER = g++
COMPILER_FLAGS = -c -g -O0 -Wall -Werror
LINKER = g++

mp3 : main.o lc3x.o
	$(LINKER) main.o lc3x.o -lpng -o mp3

main.o : main.cpp lc3x.h
	$(COMPILER) $(COMPILER_FLAGS) main.cpp

lc3x.o : lc3x.cpp lc3x.h
	$(COMPILER) $(COMPILER_FLAGS) lc3x.cpp

clean:
	-rm -f *.o mp3
