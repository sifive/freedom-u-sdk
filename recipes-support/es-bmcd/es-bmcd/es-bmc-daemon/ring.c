/*
 * Copyright (C) ESWIN Electronics Co.Ltd
 *
 * This software is licensed under the terms of the GNU General Public
 * License version 2, as published by the Free Software Foundation, and
 * may be copied, distributed, and modified under those terms.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 */

#include "es-bmc-daemon.h"

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

