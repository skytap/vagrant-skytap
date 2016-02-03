
# Skytap Provider for Vagrant (Beta)
The Skytap Vagrant provider is a [Vagrant](http://vagrantup.com) plugin for creating, provisioning, and controlling  VMs on the [Skytap](http://www.skytap.com) cloud computing platform. It allows you to:

*   Create multi-VM environments using source VMs from Skytap environments and templates
*   SSH into the instances
*   Customize hardware settings via the Vagrantfile
*   Sync folders between your local machine and Skytap VMs via NFS
*   Publish an environment, allowing revokable, password-protected access to environments with the Skytap UI.

**NOTE:** This plugin requires Vagrant 1.2+ and Ruby 2.0 or greater.

## Concepts

Skytap [environments](http://help.skytap.com/#Getting_Started_with_Environments.html) map neatly onto Vagrant multi-machine environments. An environment contains one or more VMs, and may also contain networks for the VMs to connect to. Environments may be snapshotted as [templates](http://help.skytap.com/#Templates.html), which can then be used to create new environments. The Skytap [public template library](http://help.skytap.com/#Public_Templates.html) is a collection of templates containing a variety of pre-configured VMs.

## Before You Begin

Before you begin, make sure you have:

*   Ruby 2.0 or higher installed on your local machine
*   The latest version of Vagrant installed on your local machine (available from [https://www.vagrantup.com/](https://www.vagrantup.com/))
*   A Skytap username and API token from the "My Account" page
*   A Skytap VPN in the region where you'll be creating environments; a NAT-enabled VPN is recommended.

    To check if a VPN is available, navigate to a Skytap environment in the region and open the network settings. If the **VPN** section is visible in the network settings, a VPN is available. If you do not have a Skytap VPN, work with your Skytap administrator to create one. For instructions, see [Creating a VPN Connection to an External Network](http://help.skytap.com/#Vpns.html).

## Installing the Skytap Provider and Starting Your First Environment

1. Ensure that your local machine is on one of your Skytap VPN's remote subnets.
1. To install the provider, type the following at the command line:
    `vagrant plugin install vagrant-skytap`
1. Create a new directory.
1. Create a file called Vagrantfile (with no file extension) containing the following. This Vagrantfile describes a Skytap environment containing a single VM, using the source VM indicated by the `vm_url` setting (a generic Ubuntu 14.04 server in the US-West region) and upgrading it to 2 CPUs.

    ```ruby
    Vagrant.configure(2) do |config|
      config.vm.box = "skytap/empty"

      config.vm.provider :skytap do |skytap, override|
        skytap.username = "<username>"
        skytap.api_token = "<api_token>"
      end

      config.vm.define "web" do |server|
        server.vm.provider :skytap do |box|
          box.vm_url = "https://cloud.skytap.com/vms/3157858"
          box.cpus = 2
        end
      end
    end
    ```

1. Update the `username` and `api_token` settings and save the file.
    If you don't want to store your username and API token in the Vagrantfile, you can set them in the environment variables `VAGRANT_SKYTAP_USERNAME` and `VAGRANT_SKYTAP_API_TOKEN`.
1. Navigate to the directory containing the Vagrantfile and enter the following at the command line:
    `vagrant up --provider skytap`
    Vagrant will create a new Skytap environment containing the VM,.
1.  When prompted by Vagrant, select the VPN for the region you want to connect to.
1.  Choose "skytap" as the user login for the VM.
1. Wait for `vagrant up` to complete, then do `vagrant ssh` to verify that you can access the new VM.

## Multi-machine Example
The following defines two VMs in a single environment. Both are based on the same Ubuntu template as above, but have different hardware settings. Since the source VM in the public library template is connected to a network, both of the VMs in the new environment will be connected to a single network.

```ruby
config.vm.define "web" do |server|
  server.vm.provider :skytap do |box|
    box.vm_url = "https://cloud.skytap.com/vms/3157858"
    box.cpus = 2
    box.cpuspersocket = 1
    box.ram = 1024
  end
  server.vm.synced_folder "~/web_files", "/synced", type: :nfs
end

config.vm.define "db" do |server|
  server.vm.provider :skytap do |box|
    box.vm_url = "https://cloud.skytap.com/vms/3157858"
    box.cpus = 8
    box.cpuspersocket = 4
    box.ram = 8192
  end
  server.vm.synced_folder "~/db_files", "/synced", type: :nfs
end
```

## Supported Commands

For the most part these behave identically to the builtin Vagrant commands.

| Vagrant Command                               | Skytap Action  |
|:----------------------------------------------|----------------|
| `vagrant destroy [<vm_name>, <vm_name>]`      | Delete an environment or VM(s)|
| `vagrant global-status`                       | Show the status of all Vagrant-managed VMs on the host machine; this includes VMs from other Vagrant providers|
| `vagrant halt [<vm_name>, <vm_name>]`         | Shut down an environment or VM(s). Any VMs which do not shut down gracefully will be powered off.|
| `vagrant halt [<vm_name>, <vm_name>] --force` | Power off an environment or VM(s) without performing a graceful shutdown|
| `vagrant help`                                | Display the standard help information|
| `vagrant publish-url [action] [<vm_name>, ...]`| Share an environment via the Skytap UI. See below for specifics. |
| `vagrant reload [<vm_name>, <vm_name>]`       | Shut down and then run an environment or VM(s); this is equivalent to `vagrant halt` followed by `vagrant up.`|
| `vagrant resume [<vm_name>, <vm_name>]`       | Runs one or more suspended VM(s)|
| `vagrant share [<vm_name>]`                   | Shares a VM through HashiCorp Atlas.|
| `vagrant ssh [<vm_name>]`                     | Begin an SSH session with a VM|
| `vagrant ssh-config [<vm_name>, <vm_name>]`   | Generate an OpenSSH configuration file based on the VM settings |
| `vagrant status [<vm_name>, <vm_name>]`       | Show the runstate of one or more VM(s)|
| `vagrant suspend [<vm_name>, <vm_name>]`      | Suspend an environment or VM(s)|
| `vagrant up [<vm_name>, <vm_name>]`           | Run an environment or VM(s), creating them from settings in the Vagrantfile if they do not already exist.|

Notes:

* When the first VM is created, a Skytap environment will be created; when all VMs are deleted, the containing environment will also be deleted.
* The timeout for graceful shutdown is currently set to 5 minutes.
* Changes to hardware settings of an existing VM will take effect when the VM is being powered on; that is, when doing `vagrant reload`, or `vagrant up` when the machine is halted.
* The `--install-provider` option for `vagrant up` is unsupported. The provider will be installed, but it will be necessary to run `vagrant up` again.

will install the provider only. It will be necess

## Additional Supported Actions

### Sharing Environments via Published URLs
The  Skytap Vagrant provider has basic support for [published URLs](http://help.skytap.com/#Published_URLs.html). Publishing an environment gives full anonymous access to the Skytap environment to anyone with the URL (and optional password). This feature differs from [Vagrant Share](https://www.vagrantup.com/docs/share/index.html) in that the user will have browser-based access to a shared view of all VMs in the environment, including details at a glance, thumbnails, and desktop access using SmartClient.


A password may be specified. Anonymous access may be revoked by deleting the published URL, using the `vagrant publish-url delete` subcommand. (Skytap users with appropriate
permissions may still access the environment through the UI if desired.)

| Vagrant Command and Subcommand                | Skytap Action  |
|:----------------------------------------------|----------------|
| `vagrant publish-url create [<vm_name>, <vm_name>] [options]` | Expose the given VMs through the Skytap UI, and output the URL. See options below|
| `vagrant publish-url show` | Show the published URL, the VMs included, and whether the URL is password-protected.|
| `vagrant publish-url delete [--force]` | Delete the published URL. Users will no longer be able to access the environment through the URL.|

Notes:
* At this time, the only supported options for `vagrant publish-url create` are `--password [password]` and `--no-password`. These options are mutually exclusive. If neither option is specified, Vagrant will prompt for the password (a blank password will be accepted, meaning the URL will not be password protected).
* `vagrant publish-url create` will not create a published URL if one already exists. (Additional published URLs may be created through the Skytap UI.)
*  If multiple published URLs exist for an environment, `vagrant publish-url show` will list them all, and `vagrant publish-url delete` will delete them all.

### Sync Local Folders with the VM's Folders using NFS

The Skytap Vagrant provider supports Vagrant's built-in NFS sharing facility. In the following example, a local directory `~/web_files` will be visible on the VM at the path `/synced`.

```ruby
config.vm.define "web" do |server|
  server.vm.provider :skytap do |box|
    box.vm_url = "https://cloud.skytap.com/vms/3157858"
    # ...
  end
  server.vm.synced_folder "~/web_files", "/synced", type: :nfs
end
```

For more information, see [https://docs.vagrantup.com/v2/synced-folders](https://docs.vagrantup.com/v2/synced-folders).

### Port Forwarding
The Skytap Vagrant provider supports Vagrant's port forwarding feature using [AutoSSH](http://www.harding.motd.ca/autossh), an open-source utility for managing ssh tunnels.  The `up` and `resume` commands will start a separate autossh process for each forwarded port. The `halt` and `suspend` commands will terminate the autossh processes, which will cause the ssh tunnels to be killed. `vagrant reload` kills the autossh processes and recreates them. (Only autossh processes created by Vagrant will be killed, and only for the VMs being halted, suspended, or reloaded.)

An example from the Vagrant documentation:

```ruby
Vagrant.configure("2") do |config|
  config.vm.network "forwarded_port", guest: 80, host: 8080,
    auto_correct: true
end
```
Note:  This feature is currently not supported on Windows hosts.

For more information, see [https://www.vagrantup.com/docs/networking/forwarded_ports.html](https://www.vagrantup.com/docs/networking/forwarded_ports.html).


##  Skytap-specific Vagrantfile Settings

|Setting               |Required?|Description|
|----------------------|:-------:|-----------|
|vm_url                | yes     | The URL of the source VM to use when creating a new VM.|
|cpus                  | no      | Number of CPUs (more specifically, the number of virtual cores).|
|cpuspersocket         | no      | Number of virtual cores per processor.|
|ram                   | no      | RAM (megabytes).|
|guestos               | no      | The VMware guest OS for the virtual machine.|
|vpn_url               | no      | The URL of the Skytap VPN to use when connecting to the VM.|

Notes:

* Source VMs cannot be used unless they are in the powered off state.
* Multi-machine environments may use source VMs from multiple environments and templates, from your customer account and/or the public template library, as long as all are in the same region. Your user account must have permissions to see the source VMs.
* `cpus` must be evenly divisible by `cpuspersocket`. E.g., two quad-core processors have a total of 8 virtual cores, so the `cpus` value would be 8. (Most VMs in the public template library are single-core.)
* The `guestos` setting is distinct from from Vagrant's `config.vm.guest` setting.
* If you do not know the URL for the VPN you wish to use, contact your Skytap administrator.


## Login Credentials
In addition to setting username and password in the Vagrantfile with `config.ssh.username` and `config.ssh.password`, the Skytap Vagrant provider also supports [VM Credentials](http://help.skytap.com/#VM_Settings_Credentials.html) stored with the Skytap VM. Credentials are a free-form field; if formatted as "username / password", the Skytap provider will parse the credentials and present them to the user when the VM is first created.

**NOTE:** Regardless of how the login is obtained, it will be stored in cleartext in the environment's data directory (`.vagrant`).

## Troubleshooting and Known Issues

To enable logging while troubleshooting, see [https://docs.vagrantup.com/v2/other/debugging.html](https://docs.vagrantup.com/v2/other/debugging.html). When reporting issues with the Skytap Vagrant provider, please include the output when using `VAGRANT_LOG=debug` . **NOTE:** make sure to *edit out your API token* before sending or posting the log output!

### Known issues

* Vagrant must be able to connect to the new VM over the selected Skytap VPN.
* The source VM must have an SSH service configured to run on startup, or (for Windows VMs) be configured for WinRM access. For more information about WinRM configuration, see [https://docs.vagrantup.com/v2/boxes/base.html](https://docs.vagrantup.com/v2/boxes/base.html), under "Windows Boxes".
* At this time, WinRM credentials stored in Skytap VMs will be ignored. The username and password for WinRM connections must be stored in the Vagrantfile (`config.winrm.username` and `config.winrm.password`).
* Running, reloading, or destroying a Skytap VM can result in "stale NFS file handle" errors on other providers' VMs. This is a known issue when using multiple providers on the same host machine.  The workaround is to use `vagrant reload` on the affected VM to refresh that VM's NFS mount(s).
* Public and private networks are not supported.
* Port forwarding is supported for TCP only.
* Port forwarding is currently unsupported on Windows.
* Although several Skytap public library VMs include credentials for the `root` login, its use is not recommended.
* Once a VM has been created, it is not possible to change its connection method (i.e., connect using a different VPN). This is the case whether the VPN is specified in the Vagrantfile with the `vpn_url` setting, or selected interactively.
* Installing the Skytap provider using the `--install-provider` flag is not supported.
* The `vagrant port` command is currently not supported.


## Changelog
See [CHANGELOG.md](CHANGELOG.md)

## License
MIT; see [LICENSE](LICENSE) for details.
