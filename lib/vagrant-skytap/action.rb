# Copyright (c) 2014-2016 Skytap, Inc.
#
# The MIT License (MIT)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

require "pathname"
require "vagrant/action/builder"

module VagrantPlugins
  module Skytap
    module Action
      include Vagrant::Action::Builtin

      # This action is called to halt the remote machine.
      def self.action_halt
        Vagrant::Action::Builder.new.tap do |b|
          b.use action_fetch_environment
          b.use Call, ExistenceCheck do |env1, b1|
            case result = env1[:result]
            when :missing_environment, :missing_vm, :no_vms
              b1.use MessageNotCreated
            else
              b1.use ClearForwardedPorts
              # May not halt suspended machines without --force flag
              b1.use Call, IsSuspended do |env2, b2|
                if env2[:result]
                  b2.use Call, IsEnvSet, :force_halt do |env3, b3|
                    if env3[:result]
                      b3.use StopVm
                    else
                      b3.use Message, I18n.t("vagrant_skytap.commands.halt.not_allowed_if_suspended")
                    end
                  end
                else
                  b2.use StopVm
                end
              end
            end
          end
        end
      end

      # This action is called to suspend the remote machine.
      def self.action_suspend
        Vagrant::Action::Builder.new.tap do |b|
          b.use action_fetch_environment
          b.use Call, ExistenceCheck do |env1, b1|
            case result = env1[:result]
            when :missing_environment, :missing_vm, :no_vms
              b1.use MessageNotCreated
            else
              b1.use Call, IsRunning do |env2, b2|
                if env2[:result]
                  b2.use ClearForwardedPorts
                  b2.use SuspendVm
                else
                  b2.use Message, I18n.t("vagrant_skytap.commands.suspend.only_allowed_if_running")
                end
              end
            end
          end
        end
      end

      # This action is called to terminate the remote machine.
      def self.action_destroy
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use action_fetch_environment
          b.use Call, ExistenceCheck do |env, b1|
            case existence_state = env[:result]
            when :missing_environment, :no_vms
              b1.use MessageNotCreated
              b1.use DeleteEnvironment
              next
            when :missing_vm
              b1.use MessageNotCreated
              b1.use DeleteVm
              next
            end
            b1.use Call, DestroyConfirm do |env2, b2|
              if env2[:result]
                case existence_state
                when :one_of_many_vms
                  b2.use DeleteVm
                else
                  b2.use DeleteEnvironment
                end
                b2.use ProvisionerCleanup if defined?(ProvisionerCleanup)
              else
                b2.use MessageWillNotDestroy
              end
            end
          end
          b.use ClearForwardedPorts
          b.use PrepareNFSValidIds
          b.use SyncedFolderCleanup
        end
      end

      # This action is called when `vagrant provision` is called.
      def self.action_provision
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use action_fetch_environment
          b.use Call, ExistenceCheck do |env, b1|
            case result = env[:result]
            when :missing_environment, :missing_vm, :no_vms
              b1.use MessageNotCreated
              next
            end
            b1.use Call, IsStopped do |env2, b2|
              b2.use Call, IsRunning do |env3, b3|
                unless env3[:result]
                  b3.use RunVm
                  b3.use WaitForCommunicator
                end
              end

              was_stopped = env2[:result]
              if was_stopped
                b2.use PrepareNFSSettings
                b2.use PrepareNFSValidIds
              end
              b2.use Provision
              if was_stopped
                b2.use SyncedFolders
              end
            end
          end
        end
      end

      # This action is called to read the SSH info of the machine. The
      # resulting state is expected to be put into the `:machine_ssh_info`
      # key.
      def self.action_read_ssh_info
        Vagrant::Action::Builder.new.tap do |b|
          b.use action_fetch_environment
          b.use ReadSSHInfo
        end
      end

      # This action is called to read the state of the machine. The
      # resulting state is expected to be put into the `:machine_state_id`
      # key.
      def self.action_read_state
        Vagrant::Action::Builder.new.tap do |b|
          b.use action_fetch_environment
          b.use ReadState
        end
      end

      # This action is called to SSH into the machine.
      def self.action_ssh
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckCreated
          b.use CheckRunning
          b.use SSHExec
        end
      end

      def self.action_ssh_run
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckCreated
          b.use CheckRunning
          b.use SSHRun
        end
      end

      # Note: Provision and SyncedFolders perform actions before and after
      # calling the next middleware in the sequence. Both require that
      # the machine be booted before those calls return. This requirement
      # can be satisfied by putting the WaitForCommunicator middleware
      # later in the sequence.
      def self.action_prepare_boot
        Vagrant::Action::Builder.new.tap do |b|
          b.use GetHostVM
          b.use PrepareNFSSettings
          b.use PrepareNFSValidIds
          b.use Provision
          b.use SyncedFolderCleanup
          b.use SyncedFolders
        end
      end

      def self.action_resume
        Vagrant::Action::Builder.new.tap do |b|
          b.use action_fetch_environment
          b.use Call, IsSuspended do |env, b1|
            if env[:result]
              b1.use MessageResuming
              b1.use RunVm
              b1.use WaitForCommunicator
              b1.use action_forward_ports
            end
          end
        end
      end

      # This is the action that the default "vagrant up" invokes.
      # Since we don't call action_up, this will only be called
      # if the user attempts to install the Skytap provider using
      # the --install-provider flag.
      def self.action_up
        Vagrant::Action::Builder.new.tap do |b|
          b.use Message, "You are seeing this message because the Skytap "\
            "provider currently does not fully support the --install-provider "\
            "flag. The provider has been installed successfully. Please run " \
            "'vagrant up' again to continue."
        end
      end

      # The Skytap provider has a modified "vagrant up" command which
      # takes advantage of parallel runstate operations on Skytap
      # environments. The create and update_hardware actions are
      # separated from the run_vm action, so we can pass in the ids
      # and initial states for all machines to be run, potentially
      # with a single REST call.

      def self.action_create
        Vagrant::Action::Builder.new.tap do |b|
          b.use HandleBox
          b.use ConfigValidate
          b.use action_fetch_environment
          b.use ComposeEnvironment
        end
      end

      def self.action_update_hardware
        Vagrant::Action::Builder.new.tap do |b|
          b.use StoreExtraData
          b.use GetHostVM
          b.use SetUpVm
          b.use Call, IsStopped do |env, b1|
            if env[:result]
              b1.use UpdateHardware
              b1.use SetHostname
            end
          end
        end
      end

      def self.action_run_vm
        Vagrant::Action::Builder.new.tap do |b|

          # The "up" command stores the pre-run states to
          # avoid a race condition when running multiple
          # VMs in parallel -- we need to know which VMs
          # are actually being powered on and need to
          # have folders synced and provisioning run.
          b.use Call, InitialState do |env, b1|
            case env[:result]
            when :running
              b1.use MessageAlreadyRunning
              next
            when :suspended
              b1.use MessageResuming
            else
              b1.use action_prepare_boot
            end
            b1.use Call, IsParallelized do |env2, b2|
              if env2[:result]
                # Note: RunEnvironment is a no-op after
                # the first invocation.
                b2.use RunEnvironment
              else
                b2.use RunVm
              end
            end
          end
          b.use WaitForCommunicator
          b.use action_forward_ports
        end
      end

      def self.action_reload
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use action_fetch_environment
          b.use Call, ExistenceCheck do |env, b1|
            case env[:result]
            when :missing_environment, :missing_vm, :no_vms
              b1.use MessageNotCreated
            else
              b1.use action_halt
              b1.use action_update_hardware
              # We don't need to store the initial states
              # before calling run_vm, because the default
              # behavior is to treat the VMs as powered off.
              b1.use action_run_vm
            end
          end
        end
      end

      def self.action_fetch_environment
        Vagrant::Action::Builder.new.tap do |b|
          b.use InitializeAPIClient
          b.use FetchEnvironment
        end
      end

      def self.action_forward_ports
        Vagrant::Action::Builder.new.tap do |b|
          b.use ClearForwardedPorts
          b.use EnvSet, port_collision_repair: true
          b.use PrepareForwardedPortCollisionParams
          b.use HandleForwardedPortCollisions
          b.use ForwardPorts
        end
      end

      # The autoload farm
      action_root = Pathname.new(File.expand_path("../action", __FILE__))
      autoload :StoreExtraData, action_root.join("store_extra_data")
      autoload :AddVmToEnvironment, action_root.join("add_vm_to_environment")
      autoload :CheckCreated, action_root.join("check_created")
      autoload :CheckRunning, action_root.join("check_running")
      autoload :ClearForwardedPorts, action_root.join("clear_forwarded_ports")
      autoload :ComposeEnvironment, action_root.join("compose_environment")
      autoload :CreateEnvironment, action_root.join("create_environment")
      autoload :DeleteEnvironment, action_root.join("delete_environment")
      autoload :DeleteVm, action_root.join("delete_vm")
      autoload :ExistenceCheck, action_root.join("existence_check")
      autoload :FetchEnvironment, action_root.join("fetch_environment")
      autoload :ForwardPorts, action_root.join("forward_ports")
      autoload :GetHostVM, action_root.join("get_host_vm")
      autoload :InitializeAPIClient, action_root.join("initialize_api_client")
      autoload :InitialState, action_root.join("initial_state")
      autoload :IsParallelized, action_root.join("is_parallelized")
      autoload :IsRunning, action_root.join("is_running")
      autoload :IsStopped, action_root.join("is_stopped")
      autoload :IsSuspended, action_root.join("is_suspended")
      autoload :MessageAlreadyCreated, action_root.join("message_already_created")
      autoload :MessageAlreadyRunning, action_root.join("message_already_running")
      autoload :MessageNotCreated, action_root.join("message_not_created")
      autoload :MessageEnvironmentUrl, action_root.join("message_environment_url")
      autoload :MessageResuming, action_root.join("message_resuming")
      autoload :MessageWillNotDestroy, action_root.join("message_will_not_destroy")
      autoload :PrepareForwardedPortCollisionParams, action_root.join("prepare_forwarded_port_collision_params")
      autoload :PrepareNFSSettings, action_root.join("prepare_nfs_settings")
      autoload :PrepareNFSValidIds, action_root.join("prepare_nfs_valid_ids")
      autoload :ReadSSHInfo, action_root.join("read_ssh_info")
      autoload :ReadState, action_root.join("read_state")
      autoload :RunEnvironment, action_root.join("run_environment")
      autoload :RunVm, action_root.join("run_vm")
      autoload :SetHostname, action_root.join("set_hostname")
      autoload :SetUpVm, action_root.join("set_up_vm")
      autoload :StopVm, action_root.join("stop_vm")
      autoload :SuspendVm, action_root.join("suspend_vm")
      autoload :TimedProvision, action_root.join("timed_provision") # some plugins now expect this action to exist
      autoload :UpdateHardware, action_root.join("update_hardware")
      autoload :WaitForCommunicator, action_root.join("wait_for_communicator")
    end
  end
end
