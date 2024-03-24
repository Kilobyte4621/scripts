#!/bin/bash

# Backup sshd_config
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config_backup

# Prompt for users
read -p "Enter the list of users to allow SSH access (separated by spaces): " users

# Set SSH server configuration options
cat <<EOF >> /etc/ssh/sshd_config
# Hardened SSH Configuration

# Disable root login
PermitRootLogin no

# Disable password authentication (use SSH keys)
PasswordAuthentication no

# Allow only SSH Protocol 2
Protocol 2

# Set SSH key exchange algorithms
KexAlgorithms curve25519-sha256@libssh.org,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256

# Set SSH MAC algorithms
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com

# Set SSH Ciphers
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr

# Set SSH Key Exchange Algorithms for DH key exchange
HostKeyAlgorithms ssh-ed25519,ssh-rsa,rsa-sha2-512,rsa-sha2-256

# Set SSH LogLevel to INFO
LogLevel INFO

# Disable empty passwords
PermitEmptyPasswords no

# Disable SSH access via DNS resolution
UseDNS no

# Set SSH client alive interval (disconnect after 10 minutes of inactivity)
ClientAliveInterval 600
ClientAliveCountMax 3

# Set SSH idle timeout
IdleTimeout 5m

# Set maximum authentication attempts
MaxAuthTries 3

# Set SSH login grace time
LoginGraceTime 20s

# Set banner message
Banner /etc/issue.net

# Enable strict modes
StrictModes yes

# Enable TCP forwarding
AllowTcpForwarding yes

# Disable X11 forwarding
X11Forwarding no

# Set MaxStartups to prevent DoS attacks
MaxStartups 10:30:100

# Allow only specific users to login
AllowUsers $users

EOF

echo "Hardened SSH configuration lines appended to sshd_config file."

# Exit root user
exit

# Restart SSH service
sudo systemctl restart sshd

echo "SSH configuration hardened successfully!"
