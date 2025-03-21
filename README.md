# Ubuntu Server Cleanup Tool

An interactive bash script for cleaning up and maintaining Ubuntu servers by removing unnecessary files, packages, and freeing disk space.


## Features

- **Package Management**: Clean apt cache, remove unused packages and configurations
- **Kernel Management**: Safely remove old kernels while preserving the current one
- **Log File Cleanup**: Manage and rotate system logs to save space
- **Large File Analysis**: Find and manage oversized files consuming disk space
- **Cache Management**: Clean user and system caches
- **Temporary File Cleanup**: Remove unnecessary temporary files
- **Disk Usage Analysis**: Interactive filesystem examination with ncdu
- **Docker Cleanup**: Remove unused containers, images, and volumes
- **Application Management**: Identify and remove unnecessary packages

## Requirements

- Ubuntu Server (tested on Ubuntu 18.04, 20.04, 22.04)
- Bash shell
- Root privileges (sudo)

## Installation

```bash
# Clone this repository
git clone https://github.com/username/ubuntu-server-cleanup.git

# Enter directory
cd ubuntu-server-cleanup

# Make the script executable
chmod +x ubuntu-cleanup.sh
```

## Usage

Run the script:

```bash
./ubuntu-cleanup.sh
```

The main menu provides options to:
1. Clean Package Management System
2. Remove Old Kernels
3. Clean Log Files
4. Find and Remove Large Files
5. Clean User Caches
6. Clean Temporary Files
7. Analyze Disk Usage
8. Docker Cleanup
9. Uninstall Unnecessary Applications
10. Run All Cleanup Operations
11. Display System Information

## Safety Features

- Confirmation prompts before potentially destructive actions
- Clear display of current system state before and after operations
- Detailed feedback during operations
- Minimal risk approach with carefully selected cleanup operations


