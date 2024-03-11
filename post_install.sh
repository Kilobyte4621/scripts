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
    sudo dnf install -y dnf-plugin-tracer snapper python3-dnf-plugin-snapper
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

# Main function to execute post-install tasks
main() {
    edit_dnf_conf
    install_packages
    configure_system
    setup_environment

    echo "Post-installation process completed successfully."
}

# Call the main function
main
