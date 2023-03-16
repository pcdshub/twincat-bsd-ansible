## twincat-bsd-ansible-testing

### Install requirements

* VirtualBox
* TwinCAT BSD image from Beckhoff
* bash
* ansible
* ``gettext`` to interpolate the host inventory template

### Create a VirtualBox VM

### Deploy useful settings with ansible

* Bootstraps the PLC by installing Python 3.9 (required for ansible)
* Installs system packages that I like
* Installs system packages specified in the host inventory
* Installs TwinCAT tools and a couple libraries
* Lists all of the available libraries I saw in `pkg search`, with easy uncomment-ability
* Sets an AMS Net ID based on the host inventory
* Sets locked memory size in the TcRegistry based on the host inventory
* (Optionally) Changes the default shell for Administrator to `bash`
* Provides a basic bash configuration, which shows the current TC runtime state:
  ```
  [TCBSD: RUN] [Administrator@PC-75972A  ~]$
  ```
* Adds a "site" firewall (pf = packet filter) configuration which lets through insecure ADS
* Reloads the packet filter if the configuration was changed
* Restarts the TwinCAT service if any TcRegistry changes were made


### Sample session

1. Install requirements
2. Download TwinCAT BSD image from Beckhoff and put it in the same directory as
   these scripts.
3. Pick a name for the VM: ``"tcbsd-a"``.
4. Run ``./create_tc_bsd_vm.sh tcbsd-a``
5. Open "tcbsd-a.vbox" in VirtualBox. Start it and run the installation.
    a. Select "Install"
    b. OK the overwrite of the disk.
    c. Set "1" as the password for Administrator and confirm it.
    d. Reboot
6. Check VM IP address. Our example is ``192.168.2.232``
7. Edit ``Makefile`` to set appropriate ``PLC_HOSTNAME`` (192.168.2.232 in our case)
8. Run ``make`` to pre-configure SSH communication with the VM and then the playbook. (*)
    a. Log in to the PLC when asked.  The generated SSH key will be used in the
       remaining steps.
9. Launch TwinCAT and add a route to your PLC (or use adstool/ads-async)


(*) The ``make`` steps, if too magical, can be broken down a bit further.
Run:

1. ``make ssh-setup`` (SSH key + initial login)
2. ``make host_inventory.yaml`` (create host inventory configuration file)
3. ``make run-bootstrap`` (install Python on the PLC, required for ansible)
4. ``make run-provision`` (provision the PLC)
