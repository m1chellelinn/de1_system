CC = gcc
CFLAGS = -Wall -Iinc -g

SRC = src/increment_led.c src/decrement_led.c src/
OBJ = $(SRC:src/%.c=%.o)
TARGETS = increment_led decrement_led

all: $(TARGETS)

increment_led: increment_led.o
	$(CC) -o $@ $^

decrement_led: decrement_led.o
	$(CC) -o $@ $^

%.o: src/%.c inc/address_map_arm.h inc/peripherals.h
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJ) $(TARGETS)
