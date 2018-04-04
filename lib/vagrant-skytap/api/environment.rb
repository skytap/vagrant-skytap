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

require 'json'
require 'yaml'
require 'vagrant-skytap/environment_properties'
require 'vagrant-skytap/api/resource'
require 'vagrant-skytap/api/vm'
require 'vagrant-skytap/api/network'
require 'vagrant-skytap/api/publish_set'

require_relative 'runstate_operations'

module VagrantPlugins
  module Skytap
    module API
      class Environment < Resource
        include RunstateOperations

        RESOURCE_ROOT = '/configurations'
        class << self
          # Makes the REST call to create a new environment, using
          # the provided VMs as sources.
          #
          # @param [Hash] env The environment hash passed in from the action
          # @param [Array] vms The source [API::Vm] objects
          # @return [API::Environment]
          def create!(env, vms)
            check_vms_before_adding(vms)
            vm = vms.first

            provider_config = env[:machine].provider_config
            args = {vm_ids: vms.collect(&:id)}.tap do |ret|
              if vm.from_template?
                ret[:template_id] = vm.template_id
              else
                ret[:configuration_id] = vm.configuration_id
              end
              unless provider_config.environment_name.nil?
                ret[:name] = provider_config.environment_name
              end
            end

            resp = env[:api_client].post(RESOURCE_ROOT, JSON.dump(args))
            new(JSON.load(resp.body), env)
          end

          # Makes the REST call to retrieve an existing environment.
          #
          # @param [Hash] env The environment hash passed in from the action
          # @param [String] url The url of the remote resource.
          # @return [API::Environment]
          def fetch(env, url)
            resp = env[:api_client].get(url)
            new(JSON.load(resp.body), env)
          end

          def properties(env)
            EnvironmentProperties.read(env[:machine].env.local_data_path)
          end

          # Validates that a set of VMs can be used together in a REST call to
          # create a new environment, or to add to an existing environment.
          #
          # @param [Array] vms The [API::Vm] objects to validate
          # @param [API::Environment] environment to validate against (optional)
          # @return [Boolean] true, if no exceptions were raised
          def check_vms_before_adding(vms, environment = nil)
            vms.each do |vm|
              raise Errors::SourceVmNotStopped, url: vm.url unless vm.stopped?
            end

            raise Errors::VmParentMismatch, vm_ids: vms.collect(&:id).join(', ') unless vms.collect(&:parent_url).uniq.count == 1

            if environment
              parent = vms.first.parent
              unless parent.region == environment.region
                raise Errors::RegionMismatch, environment_region: environment.region, vm_region: parent.region
              end
            end
            true
          end
        end

        attr_reader :provider_config
        attr_reader :vms, :networks

        reads :id, :name, :vms, :networks, :region, :runstate, :url, :routable

        def initialize(attrs, env)
          super
          @provider_config = env[:machine].provider_config
        end

        def vms
          @vms ||= (get_api_attribute('vms') || []).collect do |vm_attrs|
            Vm.new(vm_attrs, self, env)
          end
        end

        def get_vms_by_id(ids)
          vms.select{|vm| ids.include?(vm.id)}
        end

        def get_vm_by_id(id)
          get_vms_by_id([id]).first
        end

        def networks
          @networks ||= (get_api_attribute('networks') || []).collect do |network_attrs|
            Network.new(network_attrs, self, env)
          end
        end

        def publish_sets
          @publish_sets ||= (get_api_attribute('publish_sets') || []).collect do |ps_attrs|
            PublishSet.new(ps_attrs, self, env)
          end
        end

        def refresh(attrs)
          @vms = nil
          @networks = nil
          @publish_sets = nil
          super
        end

        def run!(vm_ids = nil)
          set_runstate :running, vm_ids: vm_ids
        end

        # Makes the REST call to add VMs to this environment, using
        # the provided VMs as sources.
        #
        # @param [Array] vms The source [API::Vm] objects
        # @return [Array] The new [API::Vm] objects
        def add_vms(vms)
          return unless vms.present?
          self.class.check_vms_before_adding(vms, self)

          args = {vm_ids: vms.collect(&:id)}.tap do |ret|
            if vms.first.from_template?
              ret[:template_id] = vms.first.template_id
            else
              ret[:merge_configuration] = vms.first.configuration_id
            end
          end

          existing_vm_ids = self.vms.collect(&:id)
          update(args)
          get_vms_by_id(self.vms.collect(&:id) - existing_vm_ids)
        end

        def create_publish_set(attrs={})
          resp = api_client.post("#{url}/publish_sets", JSON.dump(attrs))
          PublishSet.new(JSON.load(resp.body), self, env)
        end

        def properties
          @properties ||= EnvironmentProperties.new(env[:machine].env.local_data_path)
        end

        # Indicates whether traffic will be routed between networks within this
        # environment. (This is different from routing traffic to/from a network
        # within another environment, which requires an ICNR tunnel.)
        #
        # @return [Boolean]
        def routable?
          !!routable
        end
      end
    end
  end
end
