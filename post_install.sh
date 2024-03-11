#!/bin/bash

# Function to add lines to /etc/dnf/dnf.conf file
edit_dnf_conf() {
    echo "Editing /etc/dnf/dnf.conf..."
    # Add lines to /etc/dnf/dnf.conf file
    echo "fastestmirror=True" | sudo tee -a /etc/dnf/dnf.conf
    echo "max_parallel_downloads=20" | sudo tee -a /etc/dnf/dnf.conf
    echo "deltarpm=True" | sudo tee -a /etc/dnf/dnf.conf
    echo "defaultyes=True" | sudo tee -a /etc/dnf/dnf.conf
    echo "Lines added to /etc/dnf/dnf.conf successfully."
}

# Function to install necessary packages
install_packages() {
    echo "Installing necessary packages..."
    # Install necessary packages
    sudo dnf update -y
    sudo dnf install -y dnf-plugin-tracer snapper python3-dnf-plugin-snapper dnf-automatic cockpit cockpit-machines cockpit-navigator dnf-plugins-core
    echo "Packages installed successfully."
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

# Function to setup dnf-automatic
setup_dnf_automatic() {
    echo "Setting up dnf-automatic..."
    # Configure dnf-automatic
    sudo sed -i 's/^apply_updates =.*/apply_updates = yes/' /etc/dnf/automatic.conf
    sudo sed -i 's/^reboot =.*/reboot = when-needed/' /etc/dnf/automatic.conf
    sudo sed -i 's/^reboot_command =.*/reboot_command = "shutdown -r +500 'Rebooting after applying package updates'"/' /etc/dnf/automatic.conf
    echo "dnf-automatic configured successfully."
}

# Function to enable and start dnf-automatic.timer
enable_dnf_automatic_timer() {
    echo "Enabling and starting dnf-automatic.timer..."
    # Enable and start dnf-automatic.timer
    sudo systemctl enable --now dnf-automatic.timer
    echo "dnf-automatic.timer enabled and started successfully."
}

# Function to modify /etc/systemd/logind.conf
modify_logind_conf() {
    echo "Modifying /etc/systemd/logind.conf..."
    # Modify logind.conf file
    sudo sed -i 's/^#HandleSuspendKey=suspend/HandleSuspendKey=ignore/' /etc/systemd/logind.conf
    sudo sed -i 's/^#HandleLidSwitch=suspend/HandleLidSwitch=ignore/' /etc/systemd/logind.conf
    sudo sed -i 's/^#HandleLidSwitchDocked=ignore/HandleLidSwitchDocked=ignore/' /etc/systemd/logind.conf
    echo "logind.conf modified successfully."
}

# Function to install Docker and related packages
install_docker() {
    echo "Installing Docker and related packages..."
    # Install Docker and related packages
    sudo dnf -y install dnf-plugins-core
    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose docker-compose-plugin
    echo "Docker and related packages installed successfully."
}

# Function to start and enable Docker service
start_docker_service() {
    echo "Starting and enabling Docker service..."
    # Start and enable Docker service
    sudo systemctl start docker
    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service
    echo "Docker service started and enabled successfully."
}

# Function to enable linger for user to start Docker on boot
enable_docker_on_startup() {
    echo "Enabling Docker to run on startup..."
    sudo loginctl enable-linger "$(whoami)"
    echo "Docker enabled to run on startup."
}

# Function to install Syncthing
install_syncthing() {
    echo "Installing Syncthing..."
    # Increase the number of watches on the OS
    echo "fs.inotify.max_user_watches=204800" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
    # Install Syncthing
    sudo dnf install syncthing -y
    echo "Syncthing installed successfully."
}

# Function to start Syncthing as a system service
start_syncthing_service() {
    echo "Starting Syncthing as a system service..."
    sudo systemctl enable --now syncthing@$(whoami).service
    echo "Syncthing service started successfully."
}

# Function to add Syncthing's services to the firewall
add_syncthing_to_firewall() {
    echo "Adding Syncthing's services to the firewall public zone..."
    sudo firewall-cmd --permanent --add-service=syncthing --add-port=22000/tcp --add-port=22000/udp --add-port=21027/udp
    sudo firewall-cmd --permanent --add-service=syncthing-gui --add-port=8384/tcp
    sudo firewall-cmd --reload
    echo "Syncthing's services added to the firewall public zone successfully."
}

# Function to install Portainer
install_portainer() {
    echo "Installing Portainer..."
    # Create firewall rule for Portainer
    sudo firewall-cmd --permanent --add-service=portainer --add-port=9443/tcp --add-port=8000/tcp
    sudo firewall-cmd --reload
    # Create volume for Portainer
    sudo docker volume create portainer_data
    # Install Portainer Community Edition
    sudo docker run --privileged=true -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
    echo "Portainer installed and configured successfully."
}

# Main function to execute post-install tasks
main() {
    edit_dnf_conf
    install_packages
    create_snapper_config
    set_timeline_create
    setup_dnf_automatic
    enable_dnf_automatic_timer
    modify_logind_conf
    install_docker
    enable_docker_on_startup
    start_docker_service
    install_syncthing
    start_syncthing_service
    add_syncthing_to_firewall
    install_portainer

    echo "Post-installation process completed successfully."
}

# Call the main function
main
