CC = gcc
CFLAGS = -O2 -Wall -bundle -undefined dynamic_lookup
TARGET = msgpack.so

.PHONY : all clean

all : $(TARGET)

$(TARGET) : msgpack.c
	$(CC) $(CFLAGS) -o $@ -I../../skynet/3rd/lua $^ 

clean :
	rm -f $(TARGET)
