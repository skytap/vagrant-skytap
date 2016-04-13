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
require 'vagrant-skytap/api/vpn_attachment'
require 'vagrant-skytap/api/tunnel'
require 'vagrant-skytap/util/subnet'
require 'vagrant-skytap/api/connectable'

module VagrantPlugins
  module Skytap
    module API
      class Network < Resource
        include Connectable

        attr_reader :environment

        reads :id, :subnet, :nat_subnet, :vpn_attachments, :name

        def initialize(attrs, environment, env)
          super
          @environment = environment
        end

        def url
          "/configurations/#{environment.id}/networks/#{id}"
        end

        def refresh(attrs)
          @vpn_attachments = nil
          @tunnels = nil
          super
        end

        def vpn_attachments
          @vpn_attachments ||= (get_api_attribute('vpn_attachments') || []).collect do |att_attrs|
            VpnAttachment.new(att_attrs, self, env)
          end
        end

        def subnet
          Util::Subnet.new(get_api_attribute('subnet'))
        end

        def attachment_for(vpn)
          vpn = vpn.id unless vpn.is_a?(String)
          vpn_attachments.detect {|att| att.vpn['id'] == vpn}
        end

        # Indicates whether this network is NAT-enabled.
        #
        # @return [Boolean]
        def nat_enabled?
          nat_subnet.present?
        end

        # Indicates whether networks in other environments may connect
        # to this one.
        #
        # @return [Boolean]
        def tunnelable?
          get_api_attribute('tunnelable')
        end

        # The set of ICNR tunnels connecting this network to networks in other
        # environments.
        #
        # @returns [Array] of [API::Tunnel]
        def tunnels
          @tunnels ||= (get_api_attribute('tunnels') || []).collect do |tunnel_attrs|
            Tunnel.new(tunnel_attrs, env)
          end
        end

        # Connects to a network in another environment via an ICNR tunnel.
        #
        # @param [API::Network] other_network The network to connect to.
        def connect_to_network(other_network)
          API::Tunnel.create!(env, self, other_network)
          updated_network = environment.reload.networks.find{|n| n.id == id}
          refresh(updated_network.attrs)
        end

        # Indicates whether an ICNR tunnel exists between this network and the
        # given network in another environment. (For networks within the same
        # environment, check the environment's #routable? flag instead.)
        #
        # @return [Boolean]
        def connected_to_network?(other_network)
          tunnels.any? do |tunnel|
            tunnel.target_network.id == other_network.id || tunnel.source_network.id == other_network.id
          end
        end

        def connection_choice_class
          require "vagrant-skytap/connection/tunnel_choice"
          Class.const_get("VagrantPlugins::Skytap::Connection::TunnelChoice")
        end
      end
    end
  end
end
