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

require 'vagrant-skytap/api/resource'
require 'vagrant-skytap/api/public_ip'
require 'vagrant-skytap/api/published_service'
require_relative 'busyable'

module VagrantPlugins
  module Skytap
    module API
      class Interface < Resource
        include Busyable

        attr_reader :vm

        reads :id, :ip, :nat_addresses, :network_id, :public_ips, :services

        def initialize(attrs, vm, env)
          super
          @vm = vm
        end

        def network
          if network_id
            vm.environment.networks.detect do |network|
              network.id == network_id
            end
          end
        end

        def public_ips
          @public_ips ||= (get_api_attribute('public_ips') || []).collect do |ip_attrs|
            PublicIp.new(ip_attrs, self, env)
          end
        end

        def published_services
          @published_services ||= (get_api_attribute('services') || []).collect do |service_attrs|
            PublishedService.new(service_attrs, self, env)
          end
        end

        def url
          "/configurations/#{vm.environment.id}/vms/#{vm.id}/interfaces/#{id}"
        end

        def available_ips
          resp = api_client.get("#{url}/ips/available")
          ip_attrs = JSON.load(resp.body)
          ip_attrs.collect do |attrs|
            PublicIp.new(attrs, nil, env)
          end
        end

        def attachment_for(vpn)
          network.try(:attachment_for, vpn)
        end

        def address_for(vpn)
          if vpn.nat_enabled?
            if info = vpn_nat_addresses.detect {|aa| aa['vpn_id'] == vpn.id}
              info['ip_address']
            end
          elsif vpn_attachments.any? {|aa| aa.vpn['id'] == vpn.id}
            ip
          end
        end

        def vpn_attachments
          if network
            network.vpn_attachments
          else
            []
          end
        end

        def vpn_nat_addresses
          nat_addresses['vpn_nat_addresses'] || []
        end

        def nat_addresses
          get_api_attribute('nat_addresses') || {}
        end

        def attach_public_ip(ip)
          address = ip.is_a?(PublicIp) ? ip.address : ip.to_s
          begin
            resp = api_client.post("#{url}/ips", JSON.dump(ip: address))
          rescue Errors::OperationFailed => ex
            raise Errors::OperationFailed, err: 'Failed to attach public IP'
          end
        end

        def published_service_choices
          [uncreated_published_service_choice] +
            published_services.collect(&:choice_for_setup)
        end

        def uncreated_published_service_choice
          PublishedServiceChoice.uncreated_choice(env, self)
        end

        def create_published_service(internal_port)
          begin
            resp = api_client.post("#{url}/services", JSON.dump(internal_port: internal_port))
          rescue Errors::OperationFailed => ex
            raise Errors::OperationFailed, err: 'Failed to create published service'
          end

          service_attrs = JSON.load(resp.body)
          PublishedService.new(service_attrs, self, env).tap do |service|
            published_services << service
          end
        end

        def refresh(attrs)
          @public_ips = nil
          @published_services = nil
          super
        end
      end
    end
  end
end
