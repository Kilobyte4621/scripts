#!/bin/bash

# Script to perform post-installation tasks on Fedora/CentOS systems

set -e  # Exit immediately if any command fails

# Function to modify a file
modify_file() {
    local file="$1"
    local pattern="$2"
    local replacement="$3"
    
    echo "Modifying $file..."
    if ! sudo sed -i "s/$pattern/$replacement/" "$file"; then
        echo "Error: Failed to modify $file"
        exit 1
    fi
    echo "$file modified successfully."
}

# Function to add lines to a file if they don't already exist
add_to_file() {
    local file="$1"
    local lines=("${@:2}")
    
    echo "Adding lines to $file..."
    for line in "${lines[@]}"; do
        if ! grep -qF "$line" "$file"; then
            echo "$line" | sudo tee -a "$file" > /dev/null
        fi
    done
    echo "Lines added to $file successfully."
}

# Function to install packages
install_packages() {
    local packages=("$@")
    
    echo "Installing necessary packages..."
    sudo dnf install -y "${packages[@]}"
    echo "Packages installed successfully."
}

# Function to setup dnf-automatic
setup_dnf_auto() {
    echo "Setting up dnf-automatic..."
    modify_file /etc/dnf/automatic.conf "^apply_updates =.*" "apply_updates = yes"
    modify_file /etc/dnf/automatic.conf "^reboot =.*" "reboot = when-needed"
    modify_file /etc/dnf/automatic.conf "^reboot_command =.*" "reboot_command = \"shutdown -r +500 'Rebooting after applying package updates'\""

    echo "Enabling and starting dnf-automatic.timer..."
    sudo systemctl enable --now dnf-automatic.timer
    echo "dnf-automatic.timer enabled and started successfully."
}

# Function to setup services
setup_services() {
    local services=("$@")
    
    for service in "${services[@]}"; do
        echo "Setting up $service..."
        sudo systemctl enable --now "$service"
        echo "$service configured successfully."
    done
}

# Function to setup firewall
setup_firewall() {
    local services=("$@")
    
    echo "Adding services to the firewall public zone..."
    for service in "${services[@]}"; do
        sudo firewall-cmd --permanent --add-service="$service"
    done
    sudo firewall-cmd --reload
    echo "Services added to the firewall public zone successfully."
}

# Main function to execute post-install tasks
main() {
    modify_file /etc/systemd/logind.conf "#HandleSuspendKey=suspend" "HandleSuspendKey=ignore"
    modify_file /etc/systemd/logind.conf "#HandleLidSwitch=suspend" "HandleLidSwitch=ignore"
    modify_file /etc/systemd/logind.conf "#HandleLidSwitchDocked=ignore" "HandleLidSwitchDocked=ignore"

    add_to_file /etc/dnf/dnf.conf "fastestmirror=True" "max_parallel_downloads=20" "deltarpm=True" "defaultyes=True"
    sudo dnf upgrade --refresh -y

    echo "Choose additional software suites to install:"
    echo "1. Syncthing"
    echo "2. Docker and Portainer"
    echo "3. None (Continue without installing additional software)"
    read -p "Enter your choice (comma-separated, e.g., 1,2,3): " additional_choices
    IFS=',' read -ra additional_packages <<< "$additional_choices"

    for choice in "${additional_packages[@]}"; do
        case $choice in
            1) install_packages "syncthing" && setup_services "syncthing@$(whoami).service" && setup_firewall "syncthing" "syncthing-gui" ;;
            2) install_packages "docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin" "docker-compose" "docker-compose-plugin" && sudo loginctl enable-linger "$(whoami)" && setup_services "docker" "containerd" && install_portainer ;;
            3) echo "No additional software selected." ;;
            *) echo "Invalid choice: $choice" ;;
        esac
    done
}

# Call the main function
main
