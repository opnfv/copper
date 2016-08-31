Copper post installation procedures
===================================

This section describes optional procedures for verifying that the Congress
service is operational, and additional test tools developed for the Colorado
release.

Copper functional tests
-----------------------

This release includes the following test cases which are integrated into OPNFV
Functest for the JOID and Apex installers:
  * DMZ Placement: dmz.sh
  * SMTP Ingress: smtp_ingress.sh
  * Reserved Subnet: reserved_subnet.sh

These scripts, related scripts that clean up the OpenStack environment afterward,
and a combined test runner (run.sh) are in the Copper repo under the "tests"
folder. Instructions for using the tests are provided as script comments.

Further description of the tests is provided on the Copper wiki at
https://wiki.opnfv.org/display/copper/testing.


Congress test webapp
--------------------

This release also provides a webapp that can be automatically installed in a
docker container on the jumphost. This script is in the Copper repo at:
  * components/congress/test-webapp/setup/install_congress_testserver.sh

Prerequisites to using this script:
  * OPFNV installed per JOID or Apex installer
  * For Apex installs, on the jumphost, ssh to the undercloud VM and "su stack"

To invoke the procedure, enter the following shell commands, optionally
specifying the branch identifier to use for Copper.

.. code::

   wget https://git.opnfv.org/cgit/copper/plain/components/congress/test-webapp/setup/install_congress_testserver.sh
   bash install_congress_testserver.sh [copper-branch]

Using the test webapp
.....................

Browse to the webapp IP address provided at the end of the install
procedure.

Interactive options are meant to be self-explanatory given a basic familiarity
with the Congress service and data model.

Removing the test webapp
........................

The webapp can be removed by running this script from the Copper repo:
  * components/congress/test-webapp/setup/clean_congress_testserver.sh

