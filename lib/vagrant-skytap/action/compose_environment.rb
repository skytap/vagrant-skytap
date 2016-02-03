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

require 'log4r'
require 'vagrant-skytap/api/environment'
require 'vagrant-skytap/api/vm'

module VagrantPlugins
  module Skytap
    module Action
      # Creates a multi-VM Skytap environment, or adds VMs to an existing
      # environment. The source VMs (analogous to "images") may come from
      # various other environments and templates. We can parallelize this
      # somewhat by adding multiple VMs per REST call, subject to the
      # restriction that all source VMs added in a single call must be unique
      # and must belong to the same containing environment/template.
      # If creating a new environment from scratch, write the environment
      # URL into the project data directory.
      class ComposeEnvironment
        attr_reader :env

        def initialize(app, env)
          @app = app
          @env = env
          @logger = Log4r::Logger.new("vagrant_skytap::action::compose_environment")
        end

        def call(env)
          environment = env[:environment]
          new_environment = !environment
          machines = env[:machines].reject(&:id)
          environment = add_vms(environment, machines)

          if new_environment
            env[:environment] = environment
            env[:ui].info(I18n.t("vagrant_skytap.environment_url", url: environment.url))
          elsif machines.present?
            env[:ui].info("Added VMs to #{environment.url}.")
          else
            env[:ui].info("No new VMs added to #{environment.url}.")
          end

          @app.call(env)
        end

        # Create Skytap VMs for the given machines (if they do not exist)
        # within the given Skytap environment.
        #
        # @param [API::Environment] environment The Skytap environment, if it exists
        # @param [Array] machines Set of [Vagrant::Machine] objects
        # @return [API::Environment] The new or existing environment
        def add_vms(environment, machines)
          source_vms_map = fetch_source_vms(machines)

          get_groupings(source_vms_map, parallel: @env[:parallel]).each do |names|
            vms_for_pass = names.collect{|name| source_vms_map[name]}

            if !environment
              @logger.debug("Creating environment from source vms: #{vms_for_pass.collect(&:id)}")
              environment = API::Environment.create!(env, vms_for_pass)
              environment.properties.write('url' => environment.url)
              vms = environment.vms
            else
              @logger.debug("Adding source vms: #{vms_for_pass.collect(&:id)}")
              vms = environment.add_vms(vms_for_pass)
            end

            machines.select{|m| names.include?(m.name)}.each_with_index do |machine, i|
              machine.id = vms[i].id
            end
          end

          environment
        end

        # Fetch the source VMs for the given machines.
        #
        # @param [Array] machines Set of [Vagrant::Machine] objects
        # @return [Hash] mapping of machine names to [API::Vm] objects
        def fetch_source_vms(machines)
          machines.inject({}) do |acc, machine|
            acc[machine.name] = API::Vm.fetch(env, machine.provider_config.vm_url)
            acc
          end
        end

        # Group the machines to minimize calls to the REST API --
        # unique VMs from the same environment or template can be
        # added in a single call. The return value is a nested
        # array of machine names, e.g.:
        # [ [:vm1, :vm4, :vm5], [:vm3], [:vm2] ]
        #
        # However, if the :parallel option is false, just return one
        # machine per grouping, e.g.:
        # [ [:vm1], [:vm2], [:vm3], [:vm4], [:vm5] ]
        #
        # @param [Hash] vms_map Mapping of machine names to [API::Vm] objects
        # @param [Hash] options
        # @return [Array] groupings (arrays) of machine names
        def get_groupings(vms_map, options={})
          parallel = true
          parallel = options[:parallel] if options.has_key?(:parallel)
          return vms_map.keys.collect{|name| [name]} unless parallel

          # Produces nested hash, mapping configuration/template urls to
          # a map of machine names to the source VM id. (We discard the
          # parent urls -- they are just used to group the VMs.)
          groupings = vms_map.inject(Hash.new{|h,k| h[k] = {}}) do |acc, (name, vm)|
            acc[vm.parent_url][name] = vm.id
            acc
          end.values

          # If the same source VM appears more than once, the API
          # requires us to make multiple calls. For simplicity,
          # if a particular grouping includes such, just create a single
          # call for each vm in the group. (Could be optimized further)
          groupings2 = []
          groupings.each_with_index do |grouping, i|
            if grouping.values.uniq.count == grouping.values.count
              groupings2 << grouping.keys
            else
              groupings2.concat(grouping.keys.map{|v| [v]})
            end
          end

          groupings2.sort_by{|grouping| grouping.count}.reverse
        end
      end
    end
  end
end
