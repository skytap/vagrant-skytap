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

# We've subclassed the "up" command that ships with Vagrant core to
# implement parallelization with REST calls that operate on multiple
# VMs simultaneously -- since the entire environment is locked while
# VMs are created or run, the multithreaded approach does not work.
# Unfortunately the #execute method contains a lot of duplicate code,
# when all we need to modify is the #batch block which invokes
# action_up. (See #bring_up_machines below.)

require Vagrant.source_root.join("plugins/commands/up/command")

module VagrantPlugins
  module Skytap
    module Command
      class Up < VagrantPlugins::CommandUp::Command

        def execute
          options = {}
          options[:destroy_on_error] = true
          options[:parallel] = true
          options[:provision_ignore_sentinel] = false

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant up [options] [name]"
            o.separator ""
            o.separator "Options:"
            o.separator ""

            build_start_options(o, options)

            o.on("--[no-]destroy-on-error",
                 "Destroy machine if any fatal error happens (default to true)") do |destroy|
              options[:destroy_on_error] = destroy
            end

            o.on("--[no-]parallel",
                 "Enable or disable parallelism if provider supports it") do |parallel|
              options[:parallel] = parallel
            end

            o.on("--provider PROVIDER", String,
                 "Back the machine with a specific provider") do |provider|
              options[:provider] = provider
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv

          # Validate the provisioners
          if method(:validate_provisioner_flags!).arity == 1
            validate_provisioner_flags!(options)
          else
            # Second argument was added in Vagrant 1.8.0
            # https://github.com/mitchellh/vagrant/pull/5981
            validate_provisioner_flags!(options, argv)
          end

          # Go over each VM and bring it up
          @logger.debug("'Up' each target VM...")

          machines = []
          names = argv
          if names.empty?
            autostart = false
            @env.vagrantfile.machine_names_and_options.each do |n, o|
              autostart = true if o.key?(:autostart)
              o[:autostart] = true if !o.key?(:autostart)
              names << n.to_s if o[:autostart]
            end

            # If we have an autostart key but no names, it means that
            # all machines are autostart: false and we don't start anything.
            names = nil if autostart && names.empty?
          end

          # Collect the machines first so we know what their provider
          # is, and decide whether to call the Vagrant core implementation
          # of this command.
          with_target_vms(names, provider: options[:provider]) {|machine| machines << machine}
          unless machines.first.provider_name == :skytap
            @logger.debug("Calling default 'Up' implementation.")
            return super
          end

          @logger.debug("Executing Skytap 'Up' implementation.")
          bring_up_machines(machines, options)

          if machines.empty?
            @env.ui.info(I18n.t("vagrant.up_no_machines"))
            return 0
          end

          # Output the post-up messages that we have, if any
          machines.each do |m|
            next if !m.config.vm.post_up_message
            next if m.config.vm.post_up_message == ""

            # Add a newline to separate things.
            @env.ui.info("", prefix: false)

            m.ui.success(I18n.t(
              "vagrant.post_up_message",
              name: m.name.to_s,
              message: m.config.vm.post_up_message))
          end

          # Success, exit status 0
          0
        end

        # Custom handling for Skytap environments. Creating and
        # running happens in multiple phases:
        # * Compose Skytap environment from groups of VMs, or
        #   add groups of machines to an existing environment,
        #   using optimal number of API calls.
        # * Customize the VMs.
        # * Run the VMs. If parallelized this happens with a
        #   single API call.
        #
        # @param [Array] machines The [Vagrant::Machine] objects to bring up
        # @param [Hash] options
        # @return [Array] The [Vagrant::Machine] objects
        def bring_up_machines(machines, options={})
          return [] unless machines.present?

          # Invoke once for the entire set of machines.
          result = machines.first.action(:create, options.merge(machines: machines))

          # Lets us eliminate some redundant API calls
          cached_objects = {
            api_client:     result[:api_client],
            environment:    result[:environment],
            machines:       machines,
            initial_states: machines.inject({}) {|acc, m| acc[m.id] = m.state.id ; acc },
          }

          machines.each do |machine|
            machine.action(:update_hardware, options.merge(cached_objects))
          end

          machines.each do |machine|
            @env.ui.info(I18n.t(
              "vagrant.commands.up.upping",
              name: machine.name,
              provider: machine.provider_name))
            machine.action(:run_vm, options.merge(cached_objects))
          end
        end
      end
    end
  end
end
