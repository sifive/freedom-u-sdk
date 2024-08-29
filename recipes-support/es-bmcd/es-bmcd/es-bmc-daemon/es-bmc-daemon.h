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

#ifndef _ES_BMC_DEAMON_H_
#define _ES_BMC_DEAMON_H_

#include <stdint.h>

// Define frame header and frame tail
#define FRAME_HEADER    0xA55AAA55
#define FRAME_TAIL      0xBDBABDBA
#define FRAME_DATA_MAX 250

// Define command types
typedef enum {
	MSG_REQUEST = 0x01,
	MSG_REPLY,
	MSG_NOTIFLY,
} MsgType;

// Define command types
typedef enum {
	CMD_POWER_OFF = 0x01,
	CMD_REBOOT,
	CMD_READ_BOARD_INFO,
	CMD_CONTROL_LED,
	CMD_PVT_INFO,
	CMD_BOARD_STATUS,
	CMD_POWER_INFO,
	CMD_RESTART,    //cold reboot with power off/on
	// You can continue adding other command types
} CommandType;

// Message structure
typedef struct {
	uint32_t header;	// Frame heade
	uint32_t xTaskToNotify; // id
	uint8_t msg_type; 	// Message type
	uint8_t cmd_type; 	// Command type
	uint8_t cmd_result;  // command result
	uint8_t data_len; 	// Data length
	uint8_t data[FRAME_DATA_MAX]; // Data
	uint8_t checksum; 	// Checksum
	uint32_t tail;			// Frame tail
} __attribute__((packed)) Message;

// Define the size for the ring buffer
#define RING_BUFFER_SIZE 256

// Ring buffer structure
typedef struct {
	Message buffer[RING_BUFFER_SIZE];
	volatile int head;  // Next position to write to
	volatile int tail;  // Next position to read from
} RingBuffer;

// Ring buffer operations
void ring_init(RingBuffer *ring);
int ring_push(RingBuffer *ring, Message *msg);
int ring_pop(RingBuffer *ring, Message *msg);

#endif
