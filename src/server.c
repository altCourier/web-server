/**
 * @file server.c
 * @brief Basic HTTP Web Server
 *
 * Minimal web server implementation
 */

// --- Includes ---
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

// --- Defines ---
#define BUFFER_SIZE 1024

/**
 * @brief Initialize and configure the server socket
 * @param port The port number to bind to
 * @return Server file descriptor on success, -1 on failure
 */
int init_server(int port) {
	
	int server_fd = socket(AF_INET, SOCK_STREAM, 0);
	
	if (server_fd == -1) {
		perror("Socket creation failed.");
		return -1;
	}
	
	// Allow port reuse
	int opt = -1;
	
	if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt)) < 0) {
		perror("setsockopt failed.");
		close(server_fd);
		return -1;
	}
	
	struct sockaddr_in socket_addr;
	
	memset(&socket_addr, 0, sizeof(socket_addr));
	
	socket_addr.sin_family = AF_INET;
	socket_addr.sin_addr.s_addr = INADDR_ANY;
	socket_addr.sin_port = htons(port);
	
	if (bind(server_fd, (struct sockaddr*)&socket_addr, sizeof(socket_addr)) == -1) {
		perror("Bind failed.");
		close(server_fd);
		return -1;
	}
	
	if (listen(server_fd, 5) == -1) {
		perror("Listen failed.");
		close(server_fd);
		return -1;
	}
	
	printf("Server initialized on port %d\n", port);
	
	return server_fd;
}

void handle_client(int client_fd) {
	char buffer[BUFFER_SIZE];
	
	ssize_t bytes_read = recv(client_fd, buffer, BUFFER_SIZE - 1, 0);
	
	if (bytes_read > 0) {
		buffer[bytes_read] = '\0';
		printf("Request received (%ld bytes)\n", bytes_read);
	}
	
	// For debug hardcoded response
	const char *response = 
        "HTTP/1.1 200 OK\r\n"
        "Content-Type: text/html\r\n"
        "Connection: close\r\n"
        "\r\n"
        "<html>\r\n"
        "<head><title>My Web Server</title></head>\r\n"
        "<body>\r\n"
        "<h1>Hello, World!</h1>\r\n"
        "<p>Phase 1 server is working!</p>\r\n"
        "</body>\r\n"
        "</html>\r\n";
		
	ssize_t bytes_sent = send(client_fd, response, strlen(response), 0);
	
	if (bytes_sent > 0) {
		printf("Response sent (%ld bytes)\n", bytes_sent);
	}
}

/**
 * @brief Main server loop
 * @param server_fd Server socket file descriptor
 */
void run_server(int server_fd) {
	struct sockaddr_in client_addr;
	socklen_t client_addr_len = sizeof(client_addr);
	
	printf("Server listening... Press Ctrl+C to stop\n\n");
	
	while(1) {
		printf("Waiting for connection...\n");
		
		int client_fd = accept(server_fd, (struct sockaddr*)&client_addr, &client_addr_len);
		
		if (client_fd == -1) {
			perror("Accept failed.");
			continue;
		}
		
		printf("Client connected: %s:%d\n", 
			inet_ntoa(client_addr.sin_addr),
			ntohs(client_addr.sin_port));
			
		handle_client(client_fd);
		
		close(client_fd);
		printf("Connection closed.\n\n");
	}
}

/**
 * @brief Main function
 */
int main(void) {
	const int port = 8080;
	
	int server_fd = init_server(port);
	
	if (server_fd == -1) {
		exit(EXIT_FAILURE);
	}
	
	run_server(server_fd);
	
	close(server_fd);
	return 0;
}