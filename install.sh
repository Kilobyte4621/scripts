#!/bin/bash

# Function to interactively redefine environment variables
redefine_environment_variables() {
    echo "Do you want to redefine environment variables interactively? (no/yes)"
    read -r choice
    if [ "$choice" = "yes" ]; then
        echo "Enter new values for the environment variables (leave blank to keep default):"
        read -rp "MOD_LID (default: yes): " MOD_LID
        read -rp "MOD_DNF (default: yes): " MOD_DNF
        read -rp "REPLACE_MCELOG_RAS (default: yes): " REPLACE_MCELOG_RAS
        read -rp "INSTALL_SNAPPER (default: yes): " INSTALL_SNAPPER
        read -rp "INSTALL_DNF_PLUGINS (default: yes): " INSTALL_DNF_PLUGINS
        read -rp "INSTALL_DNF_AUTO (default: yes): " INSTALL_DNF_AUTO
        read -rp "INSTALL_NETWORK_MANAGER_TUI (default: yes): " INSTALL_NETWORK_MANAGER_TUI
        read -rp "INSTALL_COCKPIT_NAVIGATOR (default: yes): " INSTALL_COCKPIT_NAVIGATOR
        read -rp "INSTALL_NANO (default: yes): " INSTALL_NANO
        read -rp "INSTALL_PORTAINER_DOCKER (default: yes): " INSTALL_PORTAINER_DOCKER
        read -rp "INSTALL_SYNCTHING (default: yes): " INSTALL_SYNCTHING
        read -rp "ENABLE_VIRTUALIZATION (default: no): " ENABLE_VIRTUALIZATION
        read -rp "INSTALL_COCKPIT_MACHINES (default: yes): " INSTALL_COCKPIT_MACHINES
    fi
}

# Call the function to redefine environment variables interactively
redefine_environment_variables


# Default values for environment variables
MOD_LID="${MOD_LID:-yes}"
MOD_DNF="${MOD_DNF:-yes}"
REPLACE_MCELOG_RAS="${REPLACE_MCELOG_RAS:-yes}"
INSTALL_SNAPPER="${INSTALL_SNAPPER:-yes}"
INSTALL_DNF_PLUGINS="${INSTALL_DNF_PLUGINS:-yes}"
INSTALL_DNF_AUTO="${INSTALL_DNF_AUTO:-yes}"
INSTALL_NETWORK_MANAGER_TUI="${INSTALL_NETWORK_MANAGER_TUI:-yes}"
INSTALL_COCKPIT_NAVIGATOR="${INSTALL_COCKPIT_NAVIGATOR:-yes}"
INSTALL_NANO="${INSTALL_NANO:-yes}"
INSTALL_PORTAINER_DOCKER="${INSTALL_PORTAINER_DOCKER:-yes}"
INSTALL_SYNCTHING="${INSTALL_SYNCTHING:-yes}"
ENABLE_VIRTUALIZATION="${ENABLE_VIRTUALIZATION:-no}"
INSTALL_COCKPIT_MACHINES="${INSTALL_COCKPIT_MACHINES:-yes}"

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


# Function to modify /etc/systemd/logind.conf
modify_logind_conf() {
    echo "Modifying /etc/systemd/logind.conf..."
    # Modify logind.conf file
    sudo sed -i 's/^#HandleSuspendKey=suspend/HandleSuspendKey=ignore/' /etc/systemd/logind.conf
    sudo sed -i 's/^#HandleLidSwitch=suspend/HandleLidSwitch=ignore/' /etc/systemd/logind.conf
    sudo sed -i 's/^#HandleLidSwitchDocked=ignore/HandleLidSwitchDocked=ignore/' /etc/systemd/logind.conf
    echo "logind.conf modified successfully."
    # Restart the login service
    echo "Restarting systemd-logind.service..."
    sudo systemctl restart systemd-logind.service
    echo "systemd-logind.service restarted successfully."
}

# Function to add lines to /etc/dnf/dnf.conf file
edit_dnf_conf() {
    local dnf_conf="/etc/dnf/dnf.conf"
    echo "Editing $dnf_conf..."
    # Add lines to /etc/dnf/dnf.conf file
    add_to_file "$dnf_conf" "fastestmirror=True" "max_parallel_downloads=20" "deltarpm=True" "defaultyes=True"
    echo "Configuration updated successfully in $dnf_conf."
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

# Function to replace mcelog by rasdaemon
replace_mcelog() {
    echo "Replacing MCE log by RAS daemon..."
    # Disable mcelog service
    sudo systemctl disable --now mcelog.service

    # Install rasdaemon
    sudo dnf install rasdaemon -y

    # Enable rasdaemon service
    sudo systemctl enable --now rasdaemon.service

    echo "MCE log replaced by RAS daemon successfully"

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

# Function to modify Syncthing configuration
modify_syncthing_config() {
    local config_file="$HOME/.local/state/syncthing/config.xml"
    
    echo "Modifying Syncthing configuration file: $config_file"
    
    # Check if the config file exists
    if [ ! -f "$config_file" ]; then
        echo "Error: Syncthing configuration file not found: $config_file"
        return 1
    fi
    
    # Modify the configuration
    if ! sudo sed -i 's/<address>127.0.0.1:8384<\/address>/<address>0.0.0.0:8384<\/address>/' "$config_file"; then
        echo "Error: Failed to modify Syncthing configuration."
        return 1
    fi
    
    echo "Syncthing configuration modified successfully."
}

# Function to install Syncthing
install_syncthing() {
    echo "Installing Syncthing..."
    # Increase the number of watches on the OS
    echo "fs.inotify.max_user_watches=204800" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
    install_packages "syncthing"
    sudo systemctl enable --now syncthing@$(whoami).service
    setup_firewall "syncthing" "syncthing-gui"
    modify_syncthing_config
    sudo systemctl restart syncthing@$(whoami).service
    echo "Syncthing installed successfully."
}

# Function to create snapper config
create_snapper_config() {
    echo "Creating Snapper config..."
    # Run snapper command to create config
    sudo snapper create-config /
    echo "Snapper config created successfully."
}

# Function to ensure TIMELINE_CREATE is set to "yes" in snapper config
set_timeline_create() {
    echo "Setting TIMELINE_CREATE to \"yes\" in snapper config..."
    # Add or replace TIMELINE_CREATE option in /etc/snapper/configs/root
    sudo sed -i 's/^TIMELINE_CREATE=.*/TIMELINE_CREATE="yes"/' /etc/snapper/configs/root
    echo "TIMELINE_CREATE set to \"yes\" in snapper config."
}


# Function to install Snapper and its plugin
install_snapper() {
    echo "Installing Snapper and its plugin..."
    install_packages "snapper" "python3-dnf-plugin-snapper"
    create_snapper_config
    set_timeline_create
    echo "Snapper installed and configured successfully."
}

# Function to install DNF Automatic
install_dnf_auto() {
    echo "Installing DNF Automatic..."
    install_packages "dnf-automatic"
    setup_dnf_auto
    echo "DNF Automatic installed and configured successfully."
}


# Function to install virtualization packages
install_virtualization_packages() {
    echo "Installing virtualization packages..."
    sudo dnf group install --with-optional virtualization -y
    echo "Virtualization packages installed successfully."
}

# Function to start libvirtd service
start_libvirtd_service() {
    echo "Starting libvirtd service..."
    sudo systemctl start libvirtd
    echo "libvirtd service started successfully."
}

# Function to enable libvirtd service on boot
enable_libvirtd_service_on_boot() {
    echo "Enabling libvirtd service on boot..."
    sudo systemctl enable libvirtd
    echo "libvirtd service enabled on boot successfully."
}

# Function to verify KVM kernel modules
verify_kvm_kernel_modules() {
    echo "Verifying KVM kernel modules..."
    lsmod | grep kvm
}

# Function to edit libvirtd configuration
edit_libvirtd_configuration() {
    echo "Editing libvirtd configuration..."
    sudo sed -i '/^#unix_sock_group = "libvirt"/{s/^#//;}' /etc/libvirt/libvirtd.conf
    sudo sed -i '/^#unix_sock_ro_perms = "0777"/{s/^#//;}' /etc/libvirt/libvirtd.conf
    sudo sed -i '/^#unix_sock_group = "libvirt"/{s/^#//;}' /etc/libvirt/libvirtd.conf
    sudo sed -i '/^unix_sock_ro_perms/s/^/#/' /etc/libvirt/libvirtd.conf
    sudo sed -i '/^unix_sock_group/s/^/#/' /etc/libvirt/libvirtd.conf
    sudo tee -a /etc/libvirt/libvirtd.conf > /dev/null <<EOF
unix_sock_group = "libvirt"
unix_sock_rw_perms = "0770"
EOF
    echo "Libvirtd configuration updated successfully."
}


# Function to add user to libvirt group
add_user_to_libvirt_group() {
    echo "Adding user to libvirt group..."
    sudo usermod -a -G libvirt "$(whoami)"
    sudo systemctl daemon-reload
    echo "User added to libvirt group successfully."
}

# Virtualization function to execute all steps related to libvirt
virt() {
    install_virtualization_packages
    start_libvirtd_service
    enable_libvirtd_service_on_boot
    verify_kvm_kernel_modules
    edit_libvirtd_configuration
    add_user_to_libvirt_group
    if [ "$INSTALL_COCKPIT_MACHINES" == "yes" ]; then
        install_packages "cockpit-machines" "libguestfs-tools" 
    fi
}

# Function to execute post-install tasks for basic packages
install_basic_packages() {
    declare -a basic_packages_to_install=()
    
    if [ "$INSTALL_DNF_PLUGINS" == "yes" ]; then
        basic_packages_to_install+=( "dnf-plugin-tracer" "dnf-plugins-core" "NetworkManager-tui" )
    fi
    
    if [ "$INSTALL_COCKPIT_NAVIGATOR" == "yes" ]; then
        basic_packages_to_install+=( "cockpit-navigator" )
    fi
    
    if [ "$INSTALL_NANO" == "yes" ]; then
        basic_packages_to_install+=( "nano" )
    fi

    install_packages "${basic_packages_to_install[@]}"

    echo "Basic packages installed and configured successfully."
}



# Main function to execute post-install tasks
main() {

    
    # Modify logind_conf
    if [ "$MOD_LID" == "yes" ]; then
        modify_logind_conf
    fi
        
    # Edit dnf_conf
    if [ "$MOD_DNF" == "yes" ]; then
        edit_dnf_conf
    fi

    # Install additional software suites
    if [ "$INSTALL_SNAPPER" == "yes" ]; then
        install_snapper
    fi

    # Install additional software suites
    if [ "$INSTALL_DNF_AUTO" == "yes" ]; then
        install_dnf_auto
    fi
    
    # Install basic packages
    install_basic_packages
    # Upgrade system
    sudo dnf upgrade -y

    # Replace MCE Log by RAS Daemon
    if [ "$REPLACE_MCELOG_RAS" == "yes" ]; then
        replace_mcelog
    fi

    # Install additional software suites
    if [ "$INSTALL_SYNCTHING" == "yes" ]; then
        install_syncthing
    fi
    
    if [ "$INSTALL_PORTAINER_DOCKER" == "yes" ]; then
        echo "Adding Docker repository..."
        sudo dnf -y install dnf-plugins-core
        sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
        install_packages "docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin" "docker-compose" "docker-compose-plugin" && sudo loginctl enable-linger "$(whoami)" && setup_services "docker" "containerd" && install_portainer
    fi

    if [ "$ENABLE_VIRTUALIZATION" == "yes" ]; then
        virt
    fi

    # Reload any pending config changes
    sudo systemctl daemon-reload

    echo "Installation completed."
}



# Call the main function
main
