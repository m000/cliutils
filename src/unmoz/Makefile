RM=rm -f
CFLAGS=-std=c99 -Wall -pedantic -O3

TARGET=unmoz
SRC=$(wildcard *.c)
OBJ=$(addsuffix .o,$(basename $(SRC)))

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(OBJ)

clean:
	$(RM) $(wildcard *.o) $(TARGET)

