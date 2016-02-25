Copper configuration
====================
This release focused on use of the OpenStack Congress service for managing
configuration policy. The Congress install procedure described here is largely
manual. This procedure, as well as the longer-term goal of automated installer
support, is a work in progress. The procedure is further specific to one OPNFV
installer (JOID, i.e. MAAS/JuJu) based environment. Support for other OPNFV
installer deployed environments is also a work in progress.

Pre-configuration activities
----------------------------
This procedure assumes OPNFV has been installed via the JOID installer.

Hardware configuration
----------------------
There is no specific hardware configuration required for the Copper project.

Feature configuration
---------------------
Following are instructions for installing Congress on an Ubuntu 14.04 LXC
container in the OPNFV Controller node, as installed by the JOID installer.
This guide uses instructions from the
`Congress intro guide on readthedocs <http://congress.readthedocs.org/en/latest/readme.html#installing-congress|Congress>`_.
Specific values below will need to be modified if you intend to repeat this
procedure in your JOID-based install environment.

Install Procedure
.................
The install currently occurs via four bash scripts provided in the copper repo. See these files for the detailed steps:
  * `install_congress_1.sh <https://git.opnfv.org/cgit/copper/tree/components/congress/joid/install_congress_1.sh>`_
    * creates and starts the linux container for congress on the controller node
    * copies install_congress_2.sh to the controller node and invokes it via ssh
  * `install_congress_2.sh <https://git.opnfv.org/cgit/copper/tree/components/congress/joid/install_congress_2.sh>`_
    * installs congress on the congress server.

Cleanup Procedure
.................
If there is an error during installation, use the bash script
`clean_congress.sh <https://git.opnfv.org/cgit/copper/tree/components/congress/joid/clean_congress.sh>`_
which stops the congress server if running, and removes the congress user and
service from the controller database.

Restarting after server power loss etc
......................................

Currently this install procedure is manual. Automated install and restoral after host
recovery is TBD. For now, this procedure will get the Congress service running again.

.. code::

  # On jumphost, SSH to Congress server
  source ~/env.sh
  juju ssh ubuntu@$CONGRESS_HOST
  # If that fails
    # On jumphost, SSH to controller node
    juju ssh ubuntu@node1-control
    # Start the Congress container
    sudo lxc-start -n juju-trusty-congress -d
    # Verify the Congress container status
    sudo lxc-ls -f juju-trusty-congress
    NAME                  STATE    IPV4            IPV6  GROUPS  AUTOSTART
    ----------------------------------------------------------------------
    juju-trusty-congress  RUNNING  192.168.10.117  -     -       NO
    # exit back to the Jumphost, wait a minute, and go back to the "SSH to Congress server" step above
  # On the Congress server that you have logged into
  source ~/admin-openrc.sh
  cd ~/git/congress
  source bin/activate
  bin/congress-server &
  disown -h  %1

