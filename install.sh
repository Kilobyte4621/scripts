#!/bin/bash

# Define variables to choose which software to install
INSTALL_SNAPPER="yes"
INSTALL_DNF_PLUGINS="yes"
INSTALL_DNF_AUTOMATIC="yes"
INSTALL_NETWORK_MANAGER_TUI="yes"
INSTALL_COCKPIT_NAVIGATOR="yes"
INSTALL_COCKPIT_MACHINES="no"
INSTALL_NANO="yes"
INSTALL_PORTAINER_DOCKER="yes"
INSTALL_SYNCTHING="yes"

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

# Function to add lines to /etc/dnf/dnf.conf file
edit_dnf_conf() {
    local dnf_conf="/etc/dnf/dnf.conf"
    echo "Editing $dnf_conf..."
    # Add lines to /etc/dnf/dnf.conf file
    add_to_file "$dnf_conf" "fastestmirror=True" "max_parallel_downloads=20" "deltarpm=True" "defaultyes=True"
    echo "Configuration updated successfully in $dnf_conf."
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

# Function to execute post-install tasks for basic packages
install_basic_packages() {
    declare -a basic_packages_to_install=()

    if [ "$INSTALL_SNAPPER" == "yes" ]; then
        basic_packages_to_install+=( "snapper" "python3-dnf-plugin-snapper" )
    fi
    
    if [ "$INSTALL_DNF_PLUGINS" == "yes" ]; then
        basic_packages_to_install+=( "dnf-plugin-tracer" "dnf-plugins-core" "dnf-automatic" "NetworkManager-tui" )
    fi
    
    if [ "$INSTALL_COCKPIT_NAVIGATOR" == "yes" ]; then
        basic_packages_to_install+=( "cockpit-navigator" )
    fi
    
    if [ "$INSTALL_COCKPIT_MACHINES" == "yes" ]; then
        basic_packages_to_install+=( "cockpit-machines" "libguestfs-tools" )
    fi
    
    if [ "$INSTALL_NANO" == "yes" ]; then
        basic_packages_to_install+=( "nano" )
    fi

    install_packages "${basic_packages_to_install[@]}"

    sudo snapper create-config /
    
    setup_dnf_auto
    
    echo "Basic packages installed and configured successfully."
}

# Main function to execute post-install tasks
main() {
    # Edit dnf_conf
    edit_dnf_conf
    # Install basic packages
    install_basic_packages
    # Upgrade system
    sudo dnf upgrade -y

    # Install additional software suites
    if [ "$INSTALL_SYNCTHING" == "yes" ]; then
        install_syncthing && setup_services "syncthing@$(whoami).service" && setup_firewall "syncthing" "syncthing-gui"
    fi
    
    if [ "$INSTALL_PORTAINER_DOCKER" == "yes" ]; then
        echo "Adding Docker repository..."
        sudo dnf -y install dnf-plugins-core
        sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
        install_packages "docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin" "docker-compose" "docker-compose-plugin" && sudo loginctl enable-linger "$(whoami)" && setup_services "docker" "containerd" && install_portainer
    fi

    echo "Installation completed."
}

# Call the main function
main
