CC = wla-gb
CFLAGS = -x
LD = wlalink
LDFLAGS = -v -S
TARGET = finalhour.gb
XPMC ?= xpmc

SONGS  = music/main.asm

all: $(TARGET)

$(TARGET): main.o
	$(LD) $(LDFLAGS) linkfile $@

main.o: main.s Makefile $(SONGS) $(wildcard *.s include/*.s libgb/*.s gfx/*)
	$(CC) $(CFLAGS) -o $@ $<

%.asm: %.mml music/common.mml
	$(XPMC) -gbc ./$<

clean:
	rm -f main.o $(TARGET)

run:
	$(GBEMU) $(TARGET)
