## twincat-bsd-ansible-testing

### Install requirements

* VirtualBox
* TwinCAT BSD image from Beckhoff
* bash
* ansible
* ``gettext`` to interpolate the host inventory template

### Create a VirtualBox VM

1. Download TwinCAT BSD image from Beckhoff
2. Run ``./create_tc_bsd_vm.sh (plcname) [tcbsd.iso]``

This will generate a VM with:

* 8GB OS primary OS (SATA) disk image
* 1GB of RAM
* One network adapter (NAT -> may require reconfiguration)
* The bootable TwinCAT BSD installation media connected as the second SATA drive
    * This will boot until the installation is complete. It can be removed
      after installation is done, but it will not interfere with TC/BSD
      from booting post-installation even if it remains.

### Deploy useful settings with ansible

* Bootstraps the PLC by installing Python 3.9 (required for ansible)
* Installs system packages that I like and find useful to have everywhere
* Installs system packages specified in the host inventory
* Installs TwinCAT tools and a couple libraries
* Lists all of the available libraries I saw in `pkg search`, with easy uncomment-ability
* Sets an AMS Net ID based on the host inventory
* Sets locked memory size in the TcRegistry based on the host inventory
* (Optionally) Sets heap memory size in the TcRegistry based on the host inventory
* (Optionally) Installs C/C++ development tools
* (Optionally) Changes the default shell for Administrator to `bash`
* (Optionally) Configures initial static routes, by default just adding the
  machine from which ansible is being run.
* (Optionally) Configures add or remove a list of static routes with a custom
  ansible module ``tcbsd_route`` (see ``library/``).
* Provides a basic bash configuration, which shows the current TC runtime state:
  ```
  [TCBSD: CONFIG] [Administrator@PC-75972A  ~]$
  [TCBSD: RUN] [Administrator@PC-75972A  ~]$
  ```
* Enable color in ``ls`` and bash tab completion, if using bash.
* Adds a "site" firewall (pf = packet filter) configuration which lets through insecure ADS
* Reloads the packet filter if the configuration was changed
* Restarts the TwinCAT service if any TcRegistry changes were made


### Sample session

1. Install requirements
2. Download TwinCAT BSD image from Beckhoff and put it in the same directory as
   these scripts.
3. Pick a name for the VM: let's choose ``"tcbsd-a"``.
4. Run ``./create_tc_bsd_vm.sh tcbsd-a``
5. Open ``"tcbsd-a.vbox"`` in VirtualBox. Start it and run the installation.
    a. Select "Install"
    b. OK the overwrite of the disk.
    c. Set "1" as the password for Administrator and confirm it. (or better
        yet, set it according to good password standards and change `1` in the
        configuration files)
    d. Reboot
6. Update the VM network settings based on where you want to use it and make note
   of its IP address.
    a. The default setting is NAT, but you should consider switching it to
       host-only (or even bridged to allow usage of the VM on your local network;
       that's up to you).
    b. See also [here](https://infosys.beckhoff.com/english.php?content=../content/1033/twincat_bsd/5620035467.html&id=)
    c. Check the VM IP address (log in and run ``ifconfig``)
7. Edit ``Makefile`` to set appropriate ``PLC_IP`` (192.168.2.232 in our case)
    a. Alternatively, you can just set it in your environment:
    ```
    $ export PLC_IP=192.168.2.232
    $ export PLC_NET_ID=...
    ```
8. Run ``make`` to pre-configure SSH communication with the VM and then the playbook. (*)
    a. Log in to the PLC when asked.  The generated SSH key will be used in the
       remaining steps.
9. Launch TwinCAT XAE and add a route to your PLC (if on Linux/macOS, you can
    also use adstool/ads-async via ``make add-route`` if the auto-generated
    ``StaticRoutes.xml`` is insufficient)
10. You can use the shortcut ``make ssh`` after this point to log into the PLC
    with the generated key.

(*) The ``make`` steps, if too magical, can be broken down a bit further.
Run:

1. ``make ssh-setup`` (SSH key + initial login)
2. ``make host_inventory.yaml`` (create host inventory configuration file)
3. ``make run-bootstrap`` (install Python on the PLC, required for ansible)
4. ``make run-provision`` (provision the PLC)


## Side notes

### ADS

You can download the ADS library source code, which comes with adstool, from
[here](https://github.com/Beckhoff/ADS/).

#### Trouble building adstool on macOS due to clang and C++14 standards being used?

Try:
```bash
$ meson setup build -Dcpp_std=c++14
$ make
```
