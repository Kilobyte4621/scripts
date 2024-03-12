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

# Function to install Portainer
install_portainer() {
    echo "Installing Portainer..."
    sudo tee /etc/firewalld/services/portainer.xml > /dev/null <<EOF
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>Portainer</short>
  <description>Portainer service</description>
  <port protocol="tcp" port="8000"/>
</service>
EOF

    sudo tee /etc/firewalld/services/portainer-gui.xml > /dev/null <<EOF
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>Portainer GUI</short>
  <description>Portainer GUI service</description>
  <port protocol="tcp" port="9443"/>
</service>
EOF

    sudo firewall-cmd --reload    

    setup_firewall "portainer" "portainer-gui"

    sudo docker volume create portainer_data

    sudo docker run --privileged=true -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
    echo "Portainer installed and configured successfully."
}

# Function to install Syncthing
install_syncthing() {
    echo "Installing Syncthing..."
    install_packages "syncthing"
    echo "Syncthing installed successfully."
}


# Main function to execute post-install tasks
main() {
    modify_file /etc/systemd/logind.conf "#HandleSuspendKey=suspend" "HandleSuspendKey=ignore"
    modify_file /etc/systemd/logind.conf "#HandleLidSwitch=suspend" "HandleLidSwitch=ignore"
    modify_file /etc/systemd/logind.conf "#HandleLidSwitchDocked=ignore" "HandleLidSwitchDocked=ignore"

    add_to_file /etc/dnf/dnf.conf "fastestmirror=True" "max_parallel_downloads=20" "deltarpm=True" "defaultyes=True"
    sudo dnf upgrade --refresh -y

    echo "Choose the basic packages to install:"
    echo "1. Snapper"
    echo "2. DNF plugins"
    echo "3. Cockpit"
    echo "4. Nano"
    read -p "Enter your choice (comma-separated, e.g., 1,2,3): " basic_choices
    IFS=',' read -ra basic_packages <<< "$basic_choices"

    declare -a basic_packages_to_install=()
    for choice in "${basic_packages[@]}"; do
        case $choice in
            1) basic_packages_to_install+=( "snapper" "python3-dnf-plugin-snapper" );;
            2) basic_packages_to_install+=( "dnf-plugin-tracer" "dnf-plugins-core" "dnf-automatic" );;
            3) basic_packages_to_install+=( "cockpit-navigator" "cockpit-machines" );;
            4) basic_packages_to_install+=( "nano" );;
            *) echo "Invalid choice: $choice" ;;
        esac
    done

    install_packages "${basic_packages_to_install[@]}"

    setup_dnf_auto

    setup_services "cockpit"  # Cockpit service

    echo "Basic packages installed and configured successfully."
}

# Main function to execute post-install tasks
main() {
    install_basic_packages



    echo "Choose additional software suites to install:"
    echo "1. Syncthing"
    echo "2. Docker and Portainer"
    echo "3. None (Continue without installing additional software)"
    read -p "Enter your choice (comma-separated, e.g., 1,2,3): " additional_choices
    IFS=',' read -ra additional_packages <<< "$additional_choices"

    for choice in "${additional_packages[@]}"; do
        case $choice in
            1) install_packages "syncthing" && setup_services "syncthing@$(whoami).service" && setup_firewall "syncthing" "syncthing-gui" ;;
            2) install_packages "docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin" "docker-compose" "docker-compose-plugin" && sudo loginctl enable-linger "$(whoami)" && sudo systemctl start docker && setup_services "docker" "containerd" && install_portainer ;;
            3) echo "No additional software selected." ;;
            *) echo "Invalid choice: $choice" ;;
        esac
    done
}

# Call the main function
main
