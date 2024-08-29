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

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <termios.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <syslog.h>
#include <signal.h>
#include <errno.h>
#include <sys/prctl.h>
#include <pthread.h>
#include <sys/wait.h>
#include <sys/select.h>
#include <dirent.h>
#include <libgen.h>
#include "es-bmc-daemon.h"

#if 1
#define SYSLOG(priority, format, ...) do {    \
	if(priority == LOG_ERR) {               \
	    printf("[es_bmc_daemon][ERROR] " format "\n", ##__VA_ARGS__);     \
	} else if(priority == LOG_INFO) {         \
	    printf("[es_bmc_daemon][INFO] " format "\n", ##__VA_ARGS__);      \
	}                                         \
} while(0)
#else
#define SYSLOG(priority, format, ...) do {    \
	syslog(priority, format "\n", ##__VA_ARGS__);\
} while(0)
#endif

int g_uart_fd = -1;

typedef enum
{
	HAL_OK       = 0x00U,
	HAL_ERROR    = 0x01U,
	HAL_BUSY     = 0x02U,
	HAL_TIMEOUT  = 0x03U
} HAL_StatusTypeDef;

typedef struct {
	uint32_t cpu_temp;
	uint32_t npu_temp;
	uint32_t fan_speed;
} __attribute__((packed)) pvt_info;

typedef struct {
	uint32_t magic;
	uint8_t version;
	uint16_t id;
	uint8_t pcb;
	uint8_t bom_revision;
	uint8_t bom_variant;
	uint8_t sn[18];
	uint8_t status;
	uint32_t crc;
} __attribute__((packed)) som_info;

typedef struct {
	uint32_t consumption;
	uint32_t current;
	uint32_t voltage;
} __attribute__((packed)) power_info;

void dump_message(Message *msg)
{
	SYSLOG(LOG_INFO, "Dumping message content:");
	SYSLOG(LOG_INFO, "Header: 0x%X", msg->header);
	SYSLOG(LOG_INFO, "Command type: 0x%X", msg->cmd_type);
	SYSLOG(LOG_INFO, "Data length: %d", msg->data_len);
	SYSLOG(LOG_INFO, "Checksum: 0x%X", msg->checksum);
	SYSLOG(LOG_INFO, "Tail: 0x%X", msg->tail);
	SYSLOG(LOG_INFO, "Data:");
	for (int i = 0; i < msg->data_len; ++i) {
		SYSLOG(LOG_INFO, "%02X", msg->data[i]);
	}
}

void dump_buffer(char *buf, int len)
{
	for (int i = 0; i < len; ++i) {
		SYSLOG(LOG_INFO, "0x%02X", buf[i]);
		if (i % 20 == 0) {
			SYSLOG(LOG_INFO, "\n");
		}
	}
	SYSLOG(LOG_INFO, "\n");
}

// Function to check message checksum
int check_checksum(Message *msg)
{
	unsigned char checksum = 0;
	checksum ^= msg->msg_type;
	checksum ^= msg->cmd_type;
	checksum ^= msg->data_len;
	for (int i = 0; i < msg->data_len; ++i) {
		checksum ^= msg->data[i];
	}
	return checksum == msg->checksum;
}

void generate_checksum(Message *msg)
{
	unsigned char checksum = 0;
	checksum ^= msg->msg_type;
	checksum ^= msg->cmd_type;
	checksum ^= msg->data_len;
	for (int i = 0; i < msg->data_len; ++i) {
		checksum ^= msg->data[i];
	}
	msg->checksum = checksum;
}

// Function to read data from UART0 with timeout
int read_uart(Message *msg)
{
	char buf[sizeof(Message)] = {0};
	int total_bytes_read = 0;
	fd_set readfds;
	struct timeval timeout;
	int ret;
	int timeout_ms = 100;

	// Set up the file descriptor set for the UART
	FD_ZERO(&readfds);
	FD_SET(g_uart_fd, &readfds);

	// Loop until the entire message is received or timeout occurs
	while (total_bytes_read < sizeof(Message)) {
		int bytes_read = read(g_uart_fd, buf + total_bytes_read, sizeof(Message) - total_bytes_read);
		if (bytes_read < 0) {
			SYSLOG(LOG_ERR, "Failed to read data from UART: %s", strerror(errno));
			return -1;
		} else if (bytes_read == 0) {
			SYSLOG(LOG_ERR, "UART connection closed unexpectedly");
			return -1;
		}
		total_bytes_read += bytes_read;
		if (total_bytes_read == sizeof(Message)) {
			break;
		}
		// Set up the timeout
		timeout.tv_sec = timeout_ms / 1000;
		timeout.tv_usec = (timeout_ms % 1000) * 1000;

		// The remaining data should be received within 2 milliseconds.
		ret = select(g_uart_fd + 1, &readfds, NULL, NULL, &timeout);
		if (ret == -1) {
			SYSLOG(LOG_ERR, "Failed to select on UART: %s", strerror(errno));
			return -1;
		} else if (ret == 0) {
			SYSLOG(LOG_ERR, "Timeout occurred while waiting for UART remaining data");
			return -1;
		}
	}
	// Copy the received data to the message buffer
	memcpy(msg, buf, sizeof(Message));
	return 0;
}

// Function to send data through UART0
void send_uart(Message *msg)
{
	unsigned char buffer[sizeof(Message) + 1]; // Add one for null terminator

	generate_checksum(msg);
	// Prepare data to send
	memcpy(buffer, msg, sizeof(Message)); // Copy msg content to buffer
	buffer[sizeof(Message)] = '\0'; // Null-terminate buffer

	// Write data to UART
	int bytes_written = write(g_uart_fd, buffer, sizeof(Message));
	if (bytes_written != sizeof(Message)) {
		SYSLOG(LOG_ERR, "Failed to write data to UART: %s", strerror(errno));
	}
}

int init_uart(void)
{
	// Open UART device
	g_uart_fd = open("/dev/ttyS2", O_RDWR | O_NOCTTY);
	if (g_uart_fd == -1) {
		SYSLOG(LOG_ERR, "Failed to open UART device: %s", strerror(errno));
		return g_uart_fd;
	}

	// Configure UART
	struct termios options;
	tcgetattr(g_uart_fd, &options);
	cfsetispeed(&options, B115200); // Set input baud rate to 115200
	cfsetospeed(&options, B115200); // Set output baud rate to 115200
	options.c_cflag &= ~CSIZE; // Clear the character size bits
	options.c_cflag |= CS8;    // Set 8 data bits
	options.c_cflag &= ~PARENB; // Disable parity bit
	options.c_cflag &= ~CSTOPB; // Set one stop bit

	// Set raw mode
	options.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG);
	options.c_iflag &= ~(IXON | IXOFF | IXANY);
	options.c_oflag &= ~OPOST; // Disable output processing

	tcsetattr(g_uart_fd, TCSANOW, &options);
	return g_uart_fd;
}

int readFileAndReturnNumber(const char *directory, const char *filename)
{
	char path[1024];
	char content[256];

	snprintf(path, sizeof(path), "%s/%s", directory, filename);

	FILE *file = fopen(path, "r");
	if (!file) {
		//SYSLOG(LOG_ERR, "Could not open file: %s\n", path);
		return -1;
	}

	if(fgets(content, sizeof(content), file) == NULL) {
		//SYSLOG(LOG_ERR, "Could not read from file: %s\n", path);
		fclose(file);
		return -1;
	}
	int number = atoi(content);
	fclose(file);

	return number;
}

#define ES_BMC_MAX_PATH_LEN 1024
int compare_file_content(const char *file_path, const char *target_content)
{
	FILE *file = fopen(file_path, "r");
	if (file == NULL) {
		//SYSLOG(LOG_ERR, "Cannot open file: %s\n", file_path);
		return 0;
	}

	fseek(file, 0, SEEK_END);
	long file_size = ftell(file);
	rewind(file);

	char *buffer = (char *)malloc(file_size + 1);
	if (buffer == NULL) {
		SYSLOG(LOG_ERR, "Memory allocation error\n");
		fclose(file);
		return 0;
	}

	fread(buffer, 1, file_size, file);
	buffer[file_size] = '\0';

	int result = strncmp(buffer, target_content, strlen(target_content)) == 0;

	free(buffer);
	fclose(file);

	return result;
}

int find_and_compare_in_directory(const char *dir, const char *target_content, int depth, char *result_path)
{
	char file_path[ES_BMC_MAX_PATH_LEN];
	char *dir_path;

	if (depth > 1) {
		return 0; // Stop searching if depth exceeds 1
	}

	DIR *dp;
	struct dirent *entry;
	struct stat statbuf;

	if ((dp = opendir(dir)) == NULL) {
		SYSLOG(LOG_ERR, "Cannot open directory: %s\n", dir);
		return 0;
	}

	chdir(dir);
	while ((entry = readdir(dp)) != NULL) {
		memset(file_path, 0, sizeof(file_path));
		snprintf(file_path, sizeof(file_path), "%s/%s", dir, entry->d_name);
		if (stat(file_path, &statbuf) == -1) {
			continue;
		}
		if (S_ISDIR(statbuf.st_mode)) {
			// Skip "." and ".." directories
			if (strcmp(".", entry->d_name) == 0 || strcmp("..", entry->d_name) == 0) {
				continue;
			}
			// Recursively search in subdirectories
			if (find_and_compare_in_directory(file_path, target_content, depth + 1, result_path)) {
				chdir("..");
				closedir(dp);
				return 1;
			}
		} else {
			// Check file content
			if (strstr(file_path, "label") == NULL) {
				continue;
			}
			if (compare_file_content(file_path, target_content)) {
				dir_path = dirname(file_path);
				memcpy(result_path, dir_path, strlen(dir_path));
				chdir("..");
				closedir(dp);
				return 1;
			}
		}
	}
	chdir("..");
	closedir(dp);
	return 0;
}

char* find_and_compare(const char *start_dir, const char *target_content)
{
	static char result_path[ES_BMC_MAX_PATH_LEN];

	memset(result_path, 0, ES_BMC_MAX_PATH_LEN);
	if (find_and_compare_in_directory(start_dir, target_content, 0, result_path)) {
		return result_path;
	} else {
		return NULL;
	}
}

#define HW_MONITOR_DIR			"/sys/class/hwmon"

int get_pvt_info(pvt_info *pvt_info)
{
	int value = 0;
	char *src_dir = NULL;

	/*FAN*/
	value = -1;
	src_dir = find_and_compare(HW_MONITOR_DIR, "FAN");
	if (src_dir) {
		value = readFileAndReturnNumber(src_dir, "fan1_input");
	}
	pvt_info->fan_speed = value;

	/*NPU*/
	src_dir = find_and_compare(HW_MONITOR_DIR, "npu_vdd");
	if (src_dir) {
		value = readFileAndReturnNumber(src_dir, "temp1_input");
	}
	pvt_info->npu_temp = value;

	/*CPU*/
	value = -1;
	src_dir = find_and_compare(HW_MONITOR_DIR, "CPU Core Temperature");
	if (src_dir) {
		value = readFileAndReturnNumber(src_dir, "temp1_input");
	}
	pvt_info->cpu_temp = value;
	return 0;
}

int get_power_info(power_info *power_info)
{
	int value = 0;
	char *src_dir = NULL;

	/*consumption*/
	value = -1;
	src_dir = find_and_compare(HW_MONITOR_DIR, "sys_power");
	if (src_dir) {
		value = readFileAndReturnNumber(src_dir, "power1_input");
	}
	power_info->consumption = value;

	/*current*/
	value = -1;
	src_dir = find_and_compare(HW_MONITOR_DIR, "sys_power");
	if (src_dir) {
		value = readFileAndReturnNumber(src_dir, "curr1_input");
	}
	power_info->current = value;

	/*voltage*/
	value = -1;
	src_dir = find_and_compare(HW_MONITOR_DIR, "sys_power");
	if (src_dir) {
		value = readFileAndReturnNumber(src_dir, "in1_input");
	}
	power_info->voltage = value;
	return 0;
}

const static uint32_t SPI_FLASH_OFFSET = (16 * 1024 * 1024 - 512 * 1024);

// Function to read SOM information from SPI flash device
int read_som_info(som_info *info, off_t offset)
{
	int fd;
	ssize_t bytes_read;

	// Open SPI flash device for reading
	fd = open("/dev/mtd0", O_RDONLY);
	if (fd == -1) {
		SYSLOG(LOG_ERR,"Failed to open SPI flash device: %s\n", strerror(errno));
		return -1;
	}

	// Seek to the specified offset
	if (lseek(fd, offset, SEEK_SET) == -1) {
		SYSLOG(LOG_ERR, "Failed to seek to the specified offset: %s\n", strerror(errno));
		close(fd);
		return -1;
	}

	// Read SOM information into the structure
	bytes_read = read(fd, info, sizeof(som_info));
	if (bytes_read == -1) {
		SYSLOG(LOG_ERR,"Failed to read SOM information: %s\n", strerror(errno));
		close(fd);
		return -1;
	} else if (bytes_read < sizeof(som_info)) {
		SYSLOG(LOG_ERR,"Incomplete read of SOM information\n");
		close(fd);
		return -1;
	}

	// Close the SPI flash device
	close(fd);

	return 0;
}

// Function to execute commands
int execute_command(Message *msg)
{
	pvt_info pvt_info;
	som_info som_info;
	power_info power_info;
	int ret = HAL_ERROR;

	//dump_message(msg);

	switch (msg->cmd_type) {
		case CMD_POWER_OFF:
			ret = HAL_OK;
			system("poweroff");  // Power off the system
			break;
		case CMD_REBOOT:
			ret = system("echo \"warm\" > /sys/kernel/reboot/mode");
			if (ret != 0) {
				ret = HAL_ERROR;
				break;
			}
			ret = system("reboot");    // Reboot the system
			if (ret == -1) {
				ret = HAL_ERROR;
				break;
			}
			ret = HAL_OK;
			break;
		case CMD_RESTART:
			ret = system("echo \"cold\" > /sys/kernel/reboot/mode");
			if (ret != 0) {
				ret = HAL_ERROR;
				break;
			}
			ret = system("reboot");    // Restart the system
			if (ret == -1) {
				ret = HAL_ERROR;
				break;
			}
			ret = HAL_OK;
			break;
		case CMD_READ_BOARD_INFO:
			/*
			  Read board information from SPI Flash device.
			  Note that the value of SPI_FLASH_OFFSET is temporary and
			  may need to change later based on the location where som_info is stored
			*/
			if (read_som_info(&som_info, SPI_FLASH_OFFSET)) {
				ret = HAL_ERROR;
			} else {
				memcpy(msg->data, &som_info, sizeof(som_info));
				ret = HAL_OK;
			}
			break;
		case CMD_CONTROL_LED:
			// Control LED light via PWM interface
			// This part needs to be implemented based on actual code
			break;
		case CMD_PVT_INFO:
			if (get_pvt_info(&pvt_info)) {
				ret = HAL_ERROR;
			} else {
				memcpy(msg->data, &pvt_info, sizeof(pvt_info));
				ret = HAL_OK;
			}
			break;
		case CMD_BOARD_STATUS:
			ret = HAL_OK;
			break;
		case CMD_POWER_INFO:
			if (get_power_info(&power_info)) {
				ret = HAL_ERROR;
			} else {
				memcpy(msg->data, &power_info, sizeof(power_info));
				ret = HAL_OK;
			}
			break;
		default:
			// Unknown command type
			SYSLOG(LOG_INFO, "Unknown command type: %d", msg->cmd_type);
			ret = HAL_ERROR;
			break;
	}
	return ret;
}

// Function to handle signal
void signal_handler(int sig)
{
		switch(sig) {
		case SIGHUP:
			// Handle SIGHUP signal
			// Here you can reload configuration file or do other actions
			break;
		case SIGTERM:
			// Handle SIGTERM signal
			// Here you can do cleanup work before termination
			closelog();
			exit(EXIT_SUCCESS);
		case SIGCHLD:
			// Handle SIGCHLD signal (child process terminated)
			// Reap the child process and restart it
			while (waitpid(-1, NULL, WNOHANG) > 0);
			// Fork a new child process
			pid_t pid = fork();
			if (pid < 0) {
				SYSLOG(LOG_ERR, "Failed to fork new child process: %s", strerror(errno));
				exit(EXIT_FAILURE);
			}
			if (pid > 0) {
				// Parent process
				SYSLOG(LOG_INFO, "Child process %d exited unexpectedly, restarted as %d", getpid(), pid);
				exit(EXIT_SUCCESS);
			}
			// Child process
			break;
		default:
			break;
		}
}

// Function to handle signal
void child_signal_handler(int sig)
{
		switch(sig) {
		case SIGHUP:
			// Handle SIGHUP signal
			// Here you can reload configuration file or do other actions
			break;
		case SIGINT:
			break;
		case SIGTERM:
			// Handle SIGTERM signal
			// Here you can do cleanup work before termination
			closelog();
			exit(EXIT_SUCCESS);
		default:
			break;
		}
}

// Function to handle signal
void parent_signal_handler(int sig)
{
		switch(sig) {
		case SIGCHLD:
			// Handle SIGCHLD signal (child process terminated)
			// Reap the child process and restart it
			while (waitpid(-1, NULL, WNOHANG) > 0);
			// Fork a new child process
			pid_t pid = fork();
			if (pid < 0) {
				SYSLOG(LOG_ERR, "Failed to fork new child process: %s", strerror(errno));
				exit(EXIT_FAILURE);
			}
			if (pid > 0) {
				// Parent process
				SYSLOG(LOG_INFO, "Child process %d exited unexpectedly, restarted as %d", getpid(), pid);
				exit(EXIT_SUCCESS);
			}
			// Child process
			break;
		default:
			break;
		}
}

void* uart_read_thread(void *arg)
{
	RingBuffer *ring = (RingBuffer *)arg;
	Message msg;
	int retry_count = 0;

	while (1) {
		if (read_uart(&msg) == 0) {
			// Attempt to push message to the ring buffer
			while (retry_count < 10) {
				if (ring_push(ring, &msg) == -1) {
					SYSLOG(LOG_INFO, "Ring buffer is full! Retry count: %d", retry_count);
					usleep(200000); // 200ms delay
					retry_count++;
				} else {
					retry_count = 0; // Reset retry count upon successful push
					break; // Exit retry loop
				}
			}
			if (retry_count == 10) {
				// Max retry reached, give up and continue
				SYSLOG(LOG_INFO, "Failed to push message to ring buffer after 10 retries");
			}
		}
	}
	return NULL;
}

void *message_process_thread(void *arg)
{
	RingBuffer *ring = (RingBuffer *)arg;
	Message msg;
	int ret;

	while (1) {
		if (ring_pop(ring, &msg) != -1) {
			// Check if message is valid
			if (msg.header == FRAME_HEADER && msg.tail == FRAME_TAIL) {
				// Check checksum
				if (check_checksum(&msg)) {
					// Execute command
					ret = execute_command(&msg);
					msg.cmd_result = ret;
				} else {
					SYSLOG(LOG_INFO, "Checksum error!");
					dump_buffer((char *)&msg, sizeof(msg));
					dump_message(&msg);
					msg.cmd_result = HAL_ERROR;
				}
			} else {
				SYSLOG(LOG_INFO, "Invalid message format!");
				dump_buffer((char *)&msg, sizeof(msg));
				dump_message(&msg);
				msg.cmd_result = HAL_ERROR;
			}
			// Return execution result
			msg.msg_type = MSG_REPLY;
			send_uart(&msg);
		}
		usleep(10); // 10us delay to reduce CPU usage
	}
	return NULL;
}

// Main function
int main()
{
	// Daemonize the process
	pid_t pid, sid;
	RingBuffer ring;
	pthread_t thread_read, thread_process;

	// Create child process
	pid = fork();

	// Error, exit
	if (pid < 0) {
		exit(EXIT_FAILURE);
	}

	// Parent process wait
	if (pid > 0) {
		prctl(PR_SET_NAME, "es-bmc", 0, 0, 0);
		signal(SIGCHLD, parent_signal_handler);
		exit(EXIT_SUCCESS);
	}
	prctl(PR_SET_NAME, "es-bmcd", 0, 0, 0);
	// Run in a new session
	sid = setsid();
	if (sid < 0) {
		exit(EXIT_FAILURE);
	}

	// Change working directory
	if ((chdir("/")) < 0) {
		exit(EXIT_FAILURE);
	}

	// Close standard input, output, and error streams
	//close(STDIN_FILENO);
	//close(STDOUT_FILENO);
	//close(STDERR_FILENO);

	// Set signal handlers
	signal(SIGHUP, child_signal_handler);
	signal(SIGTERM, child_signal_handler);
	signal(SIGINT, child_signal_handler);

	// Open system log
	openlog("es_bmc_daemon", LOG_CONS | LOG_PID | LOG_NDELAY, LOG_LOCAL1);

	if (init_uart() < 0) {
		SYSLOG(LOG_INFO, "Uart init error!");
	}

	// Initialize the ring buffer
	ring_init(&ring);

	// Create the UART read and message process threads
	pthread_create(&thread_read, NULL, uart_read_thread, (void*)&ring);
	pthread_create(&thread_process, NULL, message_process_thread, (void*)&ring);

	SYSLOG(LOG_INFO, "Start sucess!");

	// Wait for the threads to finish (in this case, they run indefinitely)
	pthread_join(thread_read, NULL);
	pthread_join(thread_process, NULL);

	closelog();
	return 0;
}
