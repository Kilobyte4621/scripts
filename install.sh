#!/bin/bash

# Function to modify /etc/systemd/logind.conf to change laptop close lid behaviour
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
    echo "Editing /etc/dnf/dnf.conf..."
    # Add lines to /etc/dnf/dnf.conf file
    echo "fastestmirror=True" | sudo tee -a /etc/dnf/dnf.conf
    echo "max_parallel_downloads=20" | sudo tee -a /etc/dnf/dnf.conf
    echo "deltarpm=True" | sudo tee -a /etc/dnf/dnf.conf
    echo "defaultyes=True" | sudo tee -a /etc/dnf/dnf.conf
    echo "Lines added to /etc/dnf/dnf.conf successfully."
    # Upgrade packages
    echo "Upgrading packages..."
    sudo dnf upgrade -y --refresh
    echo "Packages upgraded successfully."
}

# Function to install and configure Snapper
setup_snapper() {
    echo "Installing and configuring Snapper..."
    # Install Snapper and its Python plugin
    sudo dnf install -y snapper python3-dnf-plugin-snapper
    # Create Snapper config
    sudo snapper create-config /
    # Set TIMELINE_CREATE to "yes" in Snapper config
    sudo sed -i 's/^TIMELINE_CREATE=.*/TIMELINE_CREATE="yes"/' /etc/snapper/configs/root
    echo "Snapper installed and configured successfully."
}

# Function to install necessary packages
install_packages() {
    echo "Installing necessary packages..."
    # Install dnf plugins
    sudo dnf install -y dnf-plugin-tracer dnf-plugins-core
    # Install Cockpit Navigator
    sudo dnf install -y cockpit-navigator
    # Install Cockpit Machines
    sudo dnf install -y cockpit-machines
    # Install Nano
    sudo dnf install -y nano
    echo "Packages installed successfully."
}

# Function to setup dnf-automatic
setup_dnf_auto() {
    echo "Setting up dnf-automatic..."
    # Configure dnf-automatic
    sudo sed -i 's/^apply_updates =.*/apply_updates = yes/' /etc/dnf/automatic.conf
    sudo sed -i 's/^reboot =.*/reboot = when-needed/' /etc/dnf/automatic.conf
    sudo sed -i "s/^reboot_command =.*/reboot_command = \"shutdown -r +500 'Rebooting after applying package updates'\"/" /etc/dnf/automatic.conf
    echo "dnf-automatic configured successfully."

    # Enable and start dnf-automatic.timer
    echo "Enabling and starting dnf-automatic.timer..."
    sudo systemctl enable --now dnf-automatic.timer
    echo "dnf-automatic.timer enabled and started successfully."
}


# Function to setup Docker
setup_docker() {
    echo "Setting up Docker..."

    # Install Docker and related packages
    sudo dnf -y install dnf-plugins-core
    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose docker-compose-plugin
    echo "Docker and related packages installed successfully."

    # Enable Docker to run on startup
    echo "Enabling Docker to run on startup..."
    sudo loginctl enable-linger "$(whoami)"
    echo "Docker enabled to run on startup."

    # Start and enable Docker service
    echo "Starting and enabling Docker service..."
    sudo systemctl start docker
    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service
    echo "Docker service started and enabled successfully."
}


# Function to install Syncthing, start its service, and add firewall rules
setup_syncthing() {
    echo "Setting up Syncthing..."

    # Increase the number of watches on the OS
    echo "fs.inotify.max_user_watches=204800" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p

    # Install Syncthing
    sudo dnf install syncthing -y
    echo "Syncthing installed successfully."

    # Start Syncthing as a system service
    echo "Starting Syncthing as a system service..."
    sudo systemctl enable --now syncthing@$(whoami).service
    echo "Syncthing service started successfully."

    # Add Syncthing's services to the firewall
    echo "Adding Syncthing's services to the firewall public zone..."
    sudo firewall-cmd --permanent --add-service=syncthing
    sudo firewall-cmd --permanent --add-service=syncthing-gui
    sudo firewall-cmd --reload
    echo "Syncthing's services added to the firewall public zone successfully."
}


# Function to install Portainer
install_portainer() {
    echo "Installing Portainer..."
    # Create the Portainer service files
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

    # Reload firewall to apply the changes
    sudo firewall-cmd --reload    

    # Create firewall rules for Portainer
    sudo firewall-cmd --permanent --add-service=portainer
    sudo firewall-cmd --permanent --add-service=portainer-gui
    sudo firewall-cmd --reload

    # Create volume for Portainer
    sudo docker volume create portainer_data

    # Install Portainer Community Edition
    sudo docker run --privileged=true -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
    echo "Portainer installed and configured successfully."
}


# Main function to execute post-install tasks
main() {
    modify_logind_conf
    edit_dnf_conf
    setup_snapper
    install_packages
    setup_dnf_auto
    setup_docker
    setup_syncthing
    install_portainer

    echo "Post-installation process completed successfully."
}

# Call the main function
main
