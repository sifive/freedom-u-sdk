# SPDX-License-Identifier: GPL-2.0
CFLAGS := -O2 -Wall
LDFLAGS :=  -lpthread

TARGET := es-bmcd
SRCS := es-bmc-daemon.c ring.c
OBJS := $(SRCS:.c=.o)

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -rf $(TARGET) $(OBJS)
