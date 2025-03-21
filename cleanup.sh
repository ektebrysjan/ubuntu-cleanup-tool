#!/bin/bash

# Colors for better UI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display script header
display_header() {
    clear
    echo -e "${BLUE}=================================${NC}"
    echo -e "${GREEN}    Ubuntu Server Cleanup Tool    ${NC}"
    echo -e "${BLUE}=================================${NC}"
    echo ""
}

# Function to check if a command is successful
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Success${NC}"
    else
        echo -e "${RED}✗ Failed${NC}"
    fi
    echo ""
}

# Function to prompt user for confirmation
confirm_action() {
    local message=$1
    local default=${2:-"n"}
    
    if [ "$default" = "y" ]; then
        local prompt="[Y/n]"
    else
        local prompt="[y/N]"
    fi
    
    echo -e -n "${YELLOW}$message $prompt ${NC}"
    read response
    
    case $response in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        [nN][oO]|[nN])
            return 1
            ;;
        "")
            if [ "$default" = "y" ]; then
                return 0
            else
                return 1
            fi
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to pause execution
pause() {
    echo ""
    echo -e "${YELLOW}Press [Enter] key to continue...${NC}"
    read -p ""
}

# 1. Clean Package Management System
clean_package_system() {
    display_header
    echo -e "${BLUE}Cleaning Package Management System...${NC}"
    echo ""
    
    echo -e "${YELLOW}Updating package lists...${NC}"
    sudo apt update
    check_status
    
    if confirm_action "Remove packages that are no longer required?"; then
        echo -e "${YELLOW}Removing unused packages...${NC}"
        sudo apt autoremove -y
        check_status
    fi
    
    if confirm_action "Clean the local repository of retrieved package files?"; then
        echo -e "${YELLOW}Cleaning package cache...${NC}"
        sudo apt clean
        check_status
    fi
    
    if confirm_action "Remove package configuration files of removed packages?"; then
        echo -e "${YELLOW}Purging removed package configs...${NC}"
        sudo apt purge $(dpkg -l | grep '^rc' | awk '{print $2}')
        check_status
    fi
    
    pause
}

# 2. Remove Old Kernels
remove_old_kernels() {
    display_header
    echo -e "${BLUE}Managing Kernel Packages...${NC}"
    echo ""
    
    echo -e "${YELLOW}Listing installed kernels:${NC}"
    dpkg --list | grep linux-image
    echo ""
    
    current_kernel=$(uname -r)
    echo -e "${GREEN}Current kernel: $current_kernel${NC}"
    echo ""
    
    if confirm_action "Remove old kernels (keeping current and previous)?"; then
        echo -e "${YELLOW}Removing old kernels...${NC}"
        sudo apt autoremove --purge
        check_status
    fi
    
    pause
}

# 3. Clean Log Files
clean_logs() {
    display_header
    echo -e "${BLUE}Cleaning Log Files...${NC}"
    echo ""
    
    echo -e "${YELLOW}Current size of log directory:${NC}"
    sudo du -sh /var/log/
    echo ""
    
    if confirm_action "Clean journal logs older than 7 days?"; then
        echo -e "${YELLOW}Cleaning journal logs...${NC}"
        sudo journalctl --vacuum-time=7d
        check_status
    fi
    
    if confirm_action "Remove compressed and rotated log files?"; then
        echo -e "${YELLOW}Removing old log files...${NC}"
        sudo find /var/log -type f -name "*.gz" -delete
        sudo find /var/log -type f -name "*.1" -delete
        check_status
    fi
    
    echo -e "${YELLOW}New size of log directory:${NC}"
    sudo du -sh /var/log/
    
    pause
}

# 4. Find and Remove Large Files
find_large_files() {
    display_header
    echo -e "${BLUE}Finding Large Files...${NC}"
    echo ""
    
    local size="100M"
    echo -e "${YELLOW}Enter minimum file size to search for (default: ${size}):${NC}"
    read -p "Size (e.g., 10M, 1G): " input_size
    
    if [ ! -z "$input_size" ]; then
        size=$input_size
    fi
    
    echo -e "${YELLOW}Searching for files larger than ${size}...${NC}"
    echo -e "${YELLOW}This may take a while...${NC}"
    echo ""
    
    # Create a temporary file for the results
    temp_file=$(mktemp)
    sudo find / -type f -size +${size} -exec ls -lh {} \; 2>/dev/null | sort -k5,5rh > "$temp_file"
    
    # Count lines in the file
    file_count=$(wc -l < "$temp_file")
    
    if [ "$file_count" -eq 0 ]; then
        echo -e "${GREEN}No files larger than ${size} found.${NC}"
    else
        echo -e "${GREEN}Found ${file_count} files larger than ${size}.${NC}"
        echo ""
        
        if confirm_action "View the list of large files?"; then
            # Display top 20 files
            head -20 "$temp_file"
            echo ""
            
            if [ "$file_count" -gt 20 ]; then
                echo -e "${YELLOW}(Showing top 20 of ${file_count} files)${NC}"
                echo ""
                
                if confirm_action "View all files?"; then
                    less "$temp_file"
                fi
            fi
        fi
        
        if confirm_action "Do you want to delete any of these files individually?"; then
            echo -e "${YELLOW}Enter the full path of the file to delete (or leave empty to skip):${NC}"
            read -p "File path: " file_path
            
            while [ ! -z "$file_path" ]; do
                if [ -f "$file_path" ]; then
                    if confirm_action "Are you SURE you want to delete ${file_path}?"; then
                        sudo rm -f "$file_path"
                        echo -e "${GREEN}File deleted.${NC}"
                    else
                        echo -e "${YELLOW}Deletion cancelled.${NC}"
                    fi
                else
                    echo -e "${RED}File not found.${NC}"
                fi
                
                echo -e "${YELLOW}Enter another file path (or leave empty to finish):${NC}"
                read -p "File path: " file_path
            done
        fi
    fi
    
    # Clean up
    rm -f "$temp_file"
    
    pause
}

# 5. Clean User Caches
clean_user_caches() {
    display_header
    echo -e "${BLUE}Cleaning User Caches...${NC}"
    echo ""
    
    echo -e "${YELLOW}Cleaning thumbnail caches...${NC}"
    sudo rm -rf /home/*/.cache/thumbnails/*
    check_status
    
    if confirm_action "Do you want to clean browser caches for all users?"; then
        echo -e "${YELLOW}Cleaning browser caches...${NC}"
        sudo find /home -type d -path "*/cache" -exec du -sh {} \; 2>/dev/null
        
        if confirm_action "Are you SURE you want to delete these caches?"; then
            sudo find /home -type d -path "*/.cache/mozilla" -exec rm -rf {} \; 2>/dev/null
            sudo find /home -type d -path "*/.cache/google-chrome" -exec rm -rf {} \; 2>/dev/null
            sudo find /home -type d -path "*/.cache/chromium" -exec rm -rf {} \; 2>/dev/null
            check_status
        fi
    fi
    
    pause
}

# 6. Clean Temporary Files
clean_temp_files() {
    display_header
    echo -e "${BLUE}Cleaning Temporary Files...${NC}"
    echo ""
    
    echo -e "${YELLOW}Current size of temp directories:${NC}"
    sudo du -sh /tmp/ /var/tmp/
    echo ""
    
    if confirm_action "Clean files in /tmp/?"; then
        echo -e "${YELLOW}Cleaning /tmp/...${NC}"
        sudo rm -rf /tmp/*
        check_status
    fi
    
    if confirm_action "Clean files in /var/tmp/?"; then
        echo -e "${YELLOW}Cleaning /var/tmp/...${NC}"
        sudo rm -rf /var/tmp/*
        check_status
    fi
    
    echo -e "${YELLOW}New size of temp directories:${NC}"
    sudo du -sh /tmp/ /var/tmp/
    
    pause
}

# 7. Analyze Disk Usage
analyze_disk_usage() {
    display_header
    echo -e "${BLUE}Analyzing Disk Usage...${NC}"
    echo ""
    
    if ! command -v ncdu &> /dev/null; then
        echo -e "${YELLOW}ncdu tool is not installed.${NC}"
        if confirm_action "Install ncdu for interactive disk usage analysis?"; then
            sudo apt install ncdu -y
            check_status
        else
            echo -e "${YELLOW}Using du command instead...${NC}"
            echo ""
            sudo du -sh /* | sort -rh
            pause
            return
        fi
    fi
    
    echo -e "${YELLOW}Starting interactive disk usage analyzer (ncdu)...${NC}"
    echo -e "${YELLOW}Use arrow keys to navigate, press 'd' to delete files/directories${NC}"
    echo -e "${YELLOW}Press 'q' to quit ncdu${NC}"
    echo ""
    
    sudo ncdu /
    pause
}

# 8. Docker Cleanup
cleanup_docker() {
    display_header
    echo -e "${BLUE}Docker Cleanup...${NC}"
    echo ""
    
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}Docker is not installed on this system.${NC}"
        pause
        return
    fi
    
    echo -e "${YELLOW}Docker disk usage before cleanup:${NC}"
    docker system df
    echo ""
    
    if confirm_action "Remove unused containers, networks, and images?"; then
        echo -e "${YELLOW}Cleaning up Docker resources...${NC}"
        docker system prune -a
        check_status
    fi
    
    if confirm_action "Remove unused Docker volumes?"; then
        echo -e "${YELLOW}Cleaning up Docker volumes...${NC}"
        docker volume prune
        check_status
    fi
    
    echo -e "${YELLOW}Docker disk usage after cleanup:${NC}"
    docker system df
    
    pause
}

# 9. Uninstall Unnecessary Applications
uninstall_apps() {
    display_header
    echo -e "${BLUE}Uninstall Unnecessary Applications...${NC}"
    echo ""
    
    echo -e "${YELLOW}Listing top 20 installed packages by size:${NC}"
    dpkg-query -W --showformat='${Installed-Size} ${Package}\n' | sort -nr | head -20
    echo ""
    
    while true; do
        echo -e "${YELLOW}Enter package name to remove (or leave empty to return to menu):${NC}"
        read -p "Package: " package_name
        
        if [ -z "$package_name" ]; then
            break
        fi
        
        # Check if the package exists
        if dpkg -l | grep -q "^ii.*$package_name"; then
            if confirm_action "Are you sure you want to remove $package_name?"; then
                echo -e "${YELLOW}Removing $package_name...${NC}"
                sudo apt remove $package_name
                check_status
            fi
        else
            echo -e "${RED}Package $package_name not found.${NC}"
        fi
    done
    
    pause
}

# Function to run all cleanup operations
run_all_cleanup() {
    display_header
    echo -e "${BLUE}Running All Cleanup Operations...${NC}"
    echo ""
    
    echo -e "${YELLOW}This will run through all cleanup operations with confirmation prompts.${NC}"
    echo -e "${YELLOW}You can choose which operations to perform.${NC}"
    echo ""
    
    if confirm_action "Continue with full system cleanup?"; then
        clean_package_system
        remove_old_kernels
        clean_logs
        find_large_files
        clean_user_caches
        clean_temp_files
        analyze_disk_usage
        cleanup_docker
        uninstall_apps
        
        display_header
        echo -e "${GREEN}All cleanup operations completed!${NC}"
        echo ""
        echo -e "${YELLOW}System cleanup summary:${NC}"
        echo -e "${YELLOW}Disk usage before cleanup: $(df -h / | grep / | awk '{print $5}')${NC}"
        echo -e "${YELLOW}Disk usage after cleanup: $(df -h / | grep / | awk '{print $5}')${NC}"
        pause
    fi
}

# Function to display system information
display_system_info() {
    display_header
    echo -e "${BLUE}System Information${NC}"
    echo ""
    
    echo -e "${YELLOW}Hostname:${NC} $(hostname)"
    echo -e "${YELLOW}Operating System:${NC} $(lsb_release -ds 2>/dev/null || cat /etc/*release 2>/dev/null | head -n1 || uname -om)"
    echo -e "${YELLOW}Kernel:${NC} $(uname -r)"
    echo -e "${YELLOW}Uptime:${NC} $(uptime -p)"
    echo ""
    
    echo -e "${YELLOW}CPU:${NC} $(grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | sed 's/^ *//')"
    echo -e "${YELLOW}Memory:${NC} $(free -h | grep Mem | awk '{print $3 " used of " $2 " total"}')"
    echo ""
    
    echo -e "${YELLOW}Disk Usage:${NC}"
    df -h | grep '^/dev/'
    echo ""
    
    pause
}

# Main menu function
main_menu() {
    while true; do
        display_header
        echo -e "${YELLOW}Main Menu:${NC}"
        echo ""
        echo -e "1) ${GREEN}Clean Package Management System${NC}"
        echo -e "2) ${GREEN}Remove Old Kernels${NC}"
        echo -e "3) ${GREEN}Clean Log Files${NC}"
        echo -e "4) ${GREEN}Find and Remove Large Files${NC}"
        echo -e "5) ${GREEN}Clean User Caches${NC}"
        echo -e "6) ${GREEN}Clean Temporary Files${NC}"
        echo -e "7) ${GREEN}Analyze Disk Usage${NC}"
        echo -e "8) ${GREEN}Docker Cleanup${NC}"
        echo -e "9) ${GREEN}Uninstall Unnecessary Applications${NC}"
        echo -e "10) ${BLUE}Run All Cleanup Operations${NC}"
        echo -e "11) ${BLUE}Display System Information${NC}"
        echo -e "0) ${RED}Exit${NC}"
        echo ""
        echo -e "${YELLOW}Please enter your choice [0-11]:${NC}"
        read -p "" choice
        
        case $choice in
            1) clean_package_system ;;
            2) remove_old_kernels ;;
            3) clean_logs ;;
            4) find_large_files ;;
            5) clean_user_caches ;;
            6) clean_temp_files ;;
            7) analyze_disk_usage ;;
            8) cleanup_docker ;;
            9) uninstall_apps ;;
            10) run_all_cleanup ;;
            11) display_system_info ;;
            0) 
                echo -e "${GREEN}Thank you for using the Ubuntu Server Cleanup Tool.${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}Note: Some operations may require sudo privileges.${NC}"
    echo -e "${YELLOW}You will be prompted for your password when needed.${NC}"
    echo ""
    sleep 2
fi

# Start the main menu
main_menu
