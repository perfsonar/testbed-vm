# Vagrant Testbed VM

This directory contains files to build a single VM for use as a testbed host.


## Prerequisites and Setup

You will need the following:

 * An operating system that complies with POSIX.  Linux has been the development and test environment and is therefore recommended.
 * Vagrant 2.1.0 or later
 * VirtualBox 5.0 or later  (Other Vagrant-supported environments may work but have not been tested.)


Run the following command(s) to configure Vagrant:

 * `vagrant plugin install netaddr`


## Understanding Networking

The VMs built will have a minimum of two network interfaces.

The first is NATted and is a requirement for Vagrant to function.
This is assigned to the first interface on the VM when Vagrant creates
it.

The second and subsequent are bridged to interfaces on the host and
given IPs on the subnet where the host interface resides.  IP
addressing for these interfaces is governed by a combination of the IP
block specified in the testbed configuration (mentioned in
_Installation_, below) and the host number in the VM configuration
(also covered below).  On the VM side, if a default route is provided
for an interface, routing policy will be installed to force all
traffic originating on that interface's address be sent out on that
interface.  Additionally, the default route provided with the first of
these interfaces will be installed as the default route in the global
routing table.


## Installation

 * Select a name for the new VM.  `testbed1` will be used as an example.

 * Create a directory to hold the Vagrant configurations for each VM you plan to build.  (This is optional but recommended.  `/testbed` will be used as an example.`

 * `cd /testbed`
 * `git clone https://github.com/perfsonar/testbed-vm`
 * `mv testbed-vm testbed1`
 * `cd testbed1`
 * Edit `config.yaml` and adjust the contents according to the instructions.
 * If your site's testbed configuration is not present in the `testbeds` directory, create one using `sample.yaml` as an example.
 * `make`

If necessary, root access to the VM can be gained by running `make
ssh`.  Note that direct SSH access for root has been disabled, so any
outside-facing interfaces will reject such login attempts.

The VM can be shut down and destroyed with `make destroy` or `make
clean`.  The latter will remove all files that were not part of the
distribution.
