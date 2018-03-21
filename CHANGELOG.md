# 0.3.7 (March 21, 2018)

* Add disks to a VM if provided.
* Apply custom name to new environmeht if provided.
* Add new environment to Project ID if provided.

# 0.3.6 (August 2, 2017)

* Parameterize some Gemfile entries for testing purposes.
* Fix bug which limited the number of guest VMs to 3 when the host is also a
  Skytap VM.
* Fix a bug in timeout error handling.

# 0.3.5 (January 3, 2017)

* Increase metadata service timeout, improve logging, handle still more errors (actually
  rescue all system call errors)

# 0.3.4 (April 27, 2016)

* Add handling for additional network errors when fetching Skytap VM metadata.

# 0.3.3 (April 25, 2016)

* Improve error messaging for network tunnels.
* Change default timeout value.
* Update Vagrantfile for example box file.

# 0.3.2 (April 19, 2016)

* Retry all operations on 423 response (previously this was not happening when attaching to a VPN).

# 0.3.1 (April 15, 2016)

* Add support for running in a Skytap VM when the VM's network is using a custom DNS.
* Clean up SSH tunnels on `vagrant destroy` (port forwarding bug).

# 0.3.0 (April 13, 2016)

* New functionality to support running Vagrant from within a Skytap VM. The connection between host and
  guest will be made over a network tunnel between the two Skytap environments.
* `vagrant ssh` now shows the expected error when the machine is not running.
* Support unattended `vagrant up` by automatically choosing the only available connection option.

# 0.2.10 (March 17, 2016)

* Fix bug in port forwarding messaging.

# 0.2.9 (February 26, 2016)

* Re-add User-Agent string.
* Set NFS host/guest IP addresses for synced folders of unspecified type
  (Vagrant can choose NFS as the default type, which resulted in an
  error).
* Don't allow suspending stopped VMs. Don't allow halting suspended VMs
  without the --force flag.

# 0.2.8 (February 24, 2016)

* Revert change to User-Agent string, which contained a bug.

# 0.2.7 (February 19, 2016)

* Add User-Agent string with the plugin version and Vagrant version.

* Fix bug which could cause machines to be mapped to the wrong VMs.

# 0.2.6 (February 16, 2016)

* Changes to support logging in to base boxes with the default `vagrant` user and
  insecure keypair. Previously, if the SSH username and password were omitted
  from the `Vagrantfile`, the user was prompted to enter them. We now default
  to the `vagrant` login. If the source VM (image) has saved credentials
  (a Skytap-specific feature; see [Accessing and Saving VM Credentials](http://help.skytap.com/#VM_Settings_Credentials.html))
  then the user will be shown a menu of the stored credentials,
  as well as an option for the default `vagrant` login.

# 0.2.5 (February 3, 2016)

* Initial push to GitHub. Random cleanup, including getting rid of some unused test files.

# 0.2.4 (February 3, 2016)

* Fix bug which caused updating hardware to take effect for the first VM only.

# 0.2.3 (January 28, 2016)

* Optimizations to REST calls in `vagrant up`.

# 0.2.2 (January 26, 2016)

* Bug fix: `vagrant add` would create but not start a new VM if
  the first existing VM was already running.

# 0.2.1 (January 26, 2016)

* Handle error when the user tries to use --install-provider flag.

# 0.2.0 (January 20, 2016)

* Add support for port forwarding on Linux and BSD hosts using AutoSSH
  (TCP only).

# 0.1.12 (December 23, 2015)

* Backward-compatibility fix.

# 0.1.11 (December 22, 2015)

* Fix breakage caused by fix to --provision-with argument in Vagrant 1.8.0
  (Vagrant GH-5139).

# 0.1.10 (December 21, 2015)

* Update README/CHANGELOG.

# 0.1.9 (December 21, 2015)

* Add `vagrant publish-url` command. This is a Skytap-specific
  Vagrant command which allows granting anonymous access to Skytap
  environments, or specific VMs within those environments, via the Skytap
  UI. See the Published URLs documentation for more details.

# 0.1.8 (December 2, 2015)

* Fixed an issue with the custom "up" command breaking `vagrant up` for
  other providers.

# 0.1.7 (November 30, 2015)

* Added parallelization support with a custom "up" command. VMs are
  created and customized separately, and then all are run with a single
  REST call.

# 0.1.6 (November 13, 2015)

* Add `vpn_url` setting to specify the method for connecting to the
  Skytap VM. If not present, the user will select the VPN interactively.
* Handle "network unreachable" errors while waiting for machines to boot.
* Add more validation logic prior to creating VMs.

# 0.1.5 (November 6, 2015)

* Initial beta release.
