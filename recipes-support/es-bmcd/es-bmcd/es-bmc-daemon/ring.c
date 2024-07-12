#include "es-bmc-deamon.h"

void ring_init(RingBuffer *ring)
{
	ring->head = 0;
	ring->tail = 0;
}

int ring_push(RingBuffer *ring, Message *msg)
{
	int new_head = (ring->head + 1) % RING_BUFFER_SIZE;
	if (new_head == ring->tail) {  // Buffer is full
		return -1;
	}
	ring->buffer[ring->head] = *msg;
	ring->head = new_head;
	return 0;
}

int ring_pop(RingBuffer *ring, Message *msg)
{
	if(ring->head == ring->tail) {  // Buffer is empty
		return -1;
	}
	*msg = ring->buffer[ring->tail];
	ring->tail = (ring->tail + 1) % RING_BUFFER_SIZE;
	return 0;
}

