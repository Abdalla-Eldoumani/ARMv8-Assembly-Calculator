CC=gcc
TARGET=calculator
SOURCE=src/calculator.s

.PHONY: all clean test

all: $(TARGET)

$(TARGET): $(SOURCE)
	$(CC) $< -o $@

clean:
	rm -f $(TARGET)