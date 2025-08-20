
# ======================================================
# Makefile for C Web Server Project
# ======================================================

# ======================================================
# --- Compiler and flags ---
# ======================================================
CC = gcc
CFLAGS = -Wall -Wextra -pedantic -std=c11 -g -O2
CFLAGS += -I$(SRCDIR) -MMD -MP

# Additional flags for web server (networking, threading)
LDFLAGS = -lpthread

# ======================================================
# --- Folder and file configuration ---
# ======================================================
SRCDIR = src
OBJDIR = obj
BINDIR = bin
TARGET = $(BINDIR)/webserver
LOG_FILE = $(OBJDIR)/webserver.log
PID_FILE = $(OBJDIR)/webserver.pid

# ======================================================
# --- Test specific ---
# ======================================================
TEST_DIR = tests
TEST_OBJDIR = $(OBJDIR)/tests

# Test source files
TEST_SOURCES = $(wildcard $(TEST_DIR)/*.c)
TEST_OBJECTS = $(patsubst $(TEST_DIR)/%.c, $(TEST_OBJDIR)/%.o, $(TEST_SOURCES))
TEST_EXECUTABLES = $(patsubst $(TEST_DIR)/%.c, $(TEST_OBJDIR)/%, $(TEST_SOURCES))

# ======================================================
# --- Source and object files ---
# ======================================================

# Main source files
SOURCES = $(wildcard $(SRCDIR)/*.c)
OBJECTS = $(patsubst $(SRCDIR)/%.c, $(OBJDIR)/%.o, $(SOURCES))

# Auto-generated dependency files
DEPS = $(OBJECTS:.o=.d)
TEST_DEPS = $(TEST_OBJECTS:.o=.d)

# ======================================================
# --- Build rules ---
# ======================================================

# Main target - builds web server
$(TARGET): $(OBJECTS)
	@mkdir -p $(BINDIR)
	$(CC) $(OBJECTS) $(LDFLAGS) -o $(TARGET)
	@echo "Web server built successfully: $(TARGET)"

# Compile .c to .o
$(OBJDIR)/%.o: $(SRCDIR)/%.c
	@mkdir -p $(OBJDIR)
	$(CC) $(CFLAGS) -c $< -o $@

# Compile test sources
$(TEST_OBJDIR)/%.o: $(TEST_DIR)/%.c
	@mkdir -p $(TEST_OBJDIR)
	$(CC) $(CFLAGS) -c $< -o $@

# Build individual test executables
$(TEST_OBJDIR)/%: $(TEST_OBJDIR)/%.o $(filter-out $(OBJDIR)/main.o, $(OBJECTS))
	$(CC) $^ $(LDFLAGS) -o $@

# Include dependency files
-include $(DEPS)
-include $(TEST_DEPS)

# ======================================================
# --- Test targets ---
# ======================================================

# Build all tests
build-tests: $(TEST_EXECUTABLES)
	@echo "All tests built successfully"

# Run all tests
test: build-tests
	@echo "Running unit tests..."
	@for test in $(TEST_EXECUTABLES); do \
		echo "Running $$test..."; \
		$$test || exit 1; \
	done
	@echo "All tests passed!"

# ======================================================
# --- Server Control Targets ---
# ======================================================

# Start server in background
start: $(TARGET)
	@echo "Starting web server..."
	@mkdir -p $(OBJDIR)
	@if [ -f $(PID_FILE) ] && kill -0 `cat $(PID_FILE)` 2>/dev/null; then \
		echo "Server is already running (PID: `cat $(PID_FILE)`)"; \
	else \
		$(TARGET) > $(LOG_FILE) 2>&1 & \
		echo $$! > $(PID_FILE); \
		echo "Server started (PID: $$!)"; \
		echo "Logs: $(LOG_FILE)"; \
	fi

# Stop server
stop:
	@if [ -f $(PID_FILE) ]; then \
		if kill -0 `cat $(PID_FILE)` 2>/dev/null; then \
			kill `cat $(PID_FILE)`; \
			rm -f $(PID_FILE); \
			echo "Server stopped"; \
		else \
			echo "Server was not running"; \
			rm -f $(PID_FILE); \
		fi \
	else \
		echo "No PID file found, server may not be running"; \
	fi

# Restart server
restart: stop start

# Check server status
status:
	@if [ -f $(PID_FILE) ] && kill -0 `cat $(PID_FILE)` 2>/dev/null; then \
		echo "Server is running (PID: `cat $(PID_FILE)`)"; \
	else \
		echo "Server is not running"; \
	fi

# View server logs
logs:
	@if [ -f $(LOG_FILE) ]; then \
		tail -f $(LOG_FILE); \
	else \
		echo "No log file found at $(LOG_FILE)"; \
	fi

# ======================================================
# --- Install / Uninstall Targets ---
# ======================================================

# Default installation prefix
PREFIX ?= /usr/local
SYSTEM_BINDIR = $(PREFIX)/bin
SYSTEM_CONFDIR = $(PREFIX)/etc/webserver

# Install server and configuration files
install: $(TARGET)
	@echo "Installing webserver to $(SYSTEM_BINDIR)"
	@mkdir -p $(SYSTEM_BINDIR)
	@mkdir -p $(SYSTEM_CONFDIR)
	cp $(TARGET) $(SYSTEM_BINDIR)
	@if [ -f config/webserver.conf ]; then \
		cp config/webserver.conf $(SYSTEM_CONFDIR)/; \
		echo "Configuration installed to $(SYSTEM_CONFDIR)"; \
	fi
	@echo "Installation complete. You can now run 'webserver' from anywhere."

# Uninstall server
uninstall:
	@echo "Removing webserver from system..."
	rm -f $(SYSTEM_BINDIR)/webserver
	rm -rf $(SYSTEM_CONFDIR)
	@echo "Uninstall complete"

# ======================================================
# --- Development Targets ---
# ======================================================

# Run server in foreground (for development)
dev: $(TARGET)
	@echo "Starting server in development mode..."
	$(TARGET)

# Run server with debugging
debug: CFLAGS += -DDEBUG -g3
debug: clean $(TARGET)
	@echo "Starting server in debug mode..."
	gdb $(TARGET)

# Run server with valgrind for memory checking
memcheck: $(TARGET)
	@echo "Running server with Valgrind memory checking..."
	valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes $(TARGET)

# ======================================================
# --- Utility Targets ---
# ======================================================

.PHONY: all clean dev debug memcheck rebuild test build-tests help
.PHONY: start stop restart status logs install uninstall

help:
	@echo "C Web Server - Build and Control"
	@echo ""
	@echo "=== Quick Start ==="
	@echo "  make dev         - Build and run server in foreground (development mode)"
	@echo "  make start       - Build and start server in background"
	@echo "  make stop        - Stop background server"
	@echo "  make status      - Check if server is running"
	@echo ""
	@echo "=== Build Targets ==="
	@echo "  make             - Build the web server (same as 'make all')"
	@echo "  make all         - Compile all source files and create binary"
	@echo "  make clean       - Remove all build artifacts"
	@echo "  make rebuild     - Clean and build from scratch"
	@echo ""
	@echo "=== Server Control ==="
	@echo "  make start       - Start server in background"
	@echo "  make stop        - Stop background server"
	@echo "  make restart     - Restart server"
	@echo "  make status      - Check server status"
	@echo "  make logs        - View server logs (tail -f)"
	@echo ""
	@echo "=== Development ==="
	@echo "  make dev         - Run server in foreground with console output"
	@echo "  make debug       - Build with debug symbols and run in GDB"
	@echo "  make memcheck    - Run server with Valgrind memory checking"
	@echo "  make test        - Run all unit tests"
	@echo ""
	@echo "=== Installation ==="
	@echo "  sudo make install   - Install server system-wide"
	@echo "  sudo make uninstall - Remove server from system"
	@echo ""
	@echo "Build configuration:"
	@echo "  Target: $(TARGET)"
	@echo "  Source: $(SRCDIR)/"
	@echo "  Objects: $(OBJDIR)/"
	@echo "  Logs: $(LOG_FILE)"

all: $(TARGET)

clean:
	rm -rf $(OBJDIR) $(BINDIR)
	@echo "Clean complete."

rebuild: clean all