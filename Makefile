CC = wla-gb
CFLAGS = -x
LD = wlalink
LDFLAGS = -v
TARGET = dare.gb

all: $(TARGET)

$(TARGET): main.o
	$(LD) $(LDFLAGS) linkfile $@

main.o: main.s Makefile $(wildcard *.s include/*.s libgb/*.s)
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f main.o $(TARGET)

run:
	$(GBEMU) $(TARGET)
