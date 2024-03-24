# scripts
 scripts for linux desktops and servers

# install.sh

This is a post-installation script that optimizes Fedora Server installations. What does it do?

- Changes laptop lid closing behaviour, so that the symtem does not stop or hibernate once the laptop screen lid is closed, in case your bare metal machine is a laptop.
- Optimizes DNF to increase the number o max paralel downloads to 20, use fastest mirror, use delta rpm (for faster transactions), and changes the default type of answering dnf to yes.
- Installs and configures snapper and phyton3-dnf-plugin-snapper for the root directory. Enables Timeline snapshoting creation with the default values.
- Installs aditional modules for Cockpit: Navigator and Machines
- Installs dnf-plugin-tracer, dnf-plugins-core, and dnf-automatic, configuring the latter to install updates and restart the server when needed.
- Installs nano
- Installs Syncthing and configure firewall
- Installs Docker root and Portainer and configure firewall

## Stable branch:
```
curl -sSL https://raw.githubusercontent.com/Kilobyte4621/scripts/stable/install.sh | bash
```
## Testing branch:
```
curl -sSL https://raw.githubusercontent.com/Kilobyte4621/scripts/testing/install.sh | bash
```
