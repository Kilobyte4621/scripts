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
    sudo dnf install -y dnf-plugin-tracer snapper python3-dnf-plugin-snapper dnf-automatic cockpit-navigator cockpit-machines
    echo "Packages installed successfully."
}

# Function to configure system settings
configure_system() {
    echo "Configuring system settings..."
    # Add your system configuration commands here
    echo "System configured successfully."
}

# Function to set up environment
setup_environment() {
    echo "Setting up environment..."
    # Add commands to set up your environment (e.g., environment variables, directories)
    echo "Environment set up successfully."
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

# Main function to execute post-install tasks
main() {
    edit_dnf_conf
    install_packages
    create_snapper_config
    set_timeline_create
    setup_dnf_automatic
    enable_dnf_automatic_timer
    modify_logind_conf
    configure_system
    setup_environment

    echo "Post-installation process completed successfully."
}

# Call the main function
main
