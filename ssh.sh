#!/bin/bash

# Backup sshd_config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config_backup

# Set SSH server configuration options
cat <<EOF > /etc/ssh/sshd_config
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

# Disable X11 forwarding
X11Forwarding no

# Disable TCP forwarding
AllowTcpForwarding no

# Set MaxStartups to prevent DoS attacks
MaxStartups 10:30:100

# Set SSH Port (change to desired port, if necessary)
#Port 22

# Allow only specific users to login
AllowUsers user1 user2

# Allow only specific groups to login
#AllowGroups group1 group2

# Disable host-based authentication
#HostbasedAuthentication no

# Set SSH idle timeout for login sessions
#LoginGraceTime 1m

# Enable public key authentication
#PubkeyAuthentication yes

# Disable SSH password hashing
#UsePAM no

# Set GSSAPI authentication
#GSSAPIAuthentication yes
#GSSAPICleanupCredentials no

# Set KbdInteractiveAuthentication
#KbdInteractiveAuthentication no

# Set SSH PermitEmptyPasswords
#PermitEmptyPasswords no

# Set SSH PermitUserEnvironment
#PermitUserEnvironment no

# Set SSH AllowAgentForwarding
#AllowAgentForwarding no

# Set SSH UsePrivilegeSeparation
#UsePrivilegeSeparation sandbox

# Set SSH Compression
#Compression delayed

# Set SSH TCPKeepAlive
#TCPKeepAlive yes

# Set SSH ClientAliveInterval and ClientAliveCountMax
#ClientAliveInterval 300
#ClientAliveCountMax 0

# Set SSH UseDNS
#UseDNS yes

# Set SSH IgnoreRhosts
#IgnoreRhosts yes

# Set SSH PermitRootLogin without-password
#PermitRootLogin without-password

# Set SSH AllowTcpForwarding
#AllowTcpForwarding yes

# Set SSH AllowTcpForwarding with X11Forwarding
#AllowTcpForwarding yes
#X11Forwarding yes

# Set SSH PrintMotd
#PrintMotd no

# Set SSH PrintLastLog
#PrintLastLog yes

# Set SSH UseDNS
#UseDNS yes

# Set SSH PasswordAuthentication
#PasswordAuthentication no

# Set SSH PermitRootLogin
#PermitRootLogin no

# Set SSH Banner
#Banner /etc/issue.net

# Set SSH AllowGroups
#AllowGroups sshusers

# Set SSH AllowUsers
#AllowUsers user1 user2

# Set SSH AuthorizedKeysFile
#AuthorizedKeysFile .ssh/authorized_keys

EOF

# Restart SSH service
service sshd restart

echo "SSH configuration hardened successfully!"
