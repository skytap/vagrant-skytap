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

require 'vagrant-skytap/connection'

# An ICNR tunnel connects networks in two different Skytap environments.
# In the case where the host is a Skytap VM, a tunnel is the most convenient
# way of establishing communication with the guest VM.

module VagrantPlugins
  module Skytap
    module Connection
      class TunnelChoice < Choice
        attr_reader :host_network, :guest_network

        def initialize(env, host_network, iface)
          @env = env
          @iface = iface
          @host_network = host_network
          @guest_network = iface.network
          @execution = TunnelExecution.make(env, iface, host_network)
        end

        def choose
          execution.execute
          @iface = iface.vm.reload.get_interface_by_id(iface.id)
          @host_network = host_network.environment.reload.networks.find{|n| n.id == host_network.id}
          nat_address = iface.nat_address_for_network(host_network)
          [nat_address, DEFAULT_PORT]
        end

        def valid?
          @validation_error_message = nil

          unless host_network.tunnelable? && host_network.nat_enabled?
            @validation_error_message = I18n.t("vagrant_skytap.connections.tunnel.errors.host_network_not_connectable")
            return false
          end

          unless guest_network.nat_enabled?
            if guest_network.subnet.overlaps?(host_network.subnet)
              @validation_error_message = I18n.t("vagrant_skytap.connections.tunnel.errors.guest_network_overlaps",
                                                 guest_subnet: guest_network.subnet, host_subnet: host_network.subnet,
                                                 environment_url: iface.vm.environment.url)
              return false
            end
          end

          true
        end

        class TunnelExecution < Execution
          attr_reader :host_network, :guest_network

          def self.make(env, iface, host_network)
            if host_network.try(:connected_to_network?, iface.network)
              UseExecution.new(env, iface, host_network)
            else
              CreateAndUseExecution.new(env, iface, host_network)
            end
          end

          def initialize(env, iface, host_network)
            super
            @host_network = host_network
            @guest_network = iface.network
          end

          def message
            "#{verb}: #{host_network.name}"
          end
        end

        class UseExecution < TunnelExecution
          def verb
            I18n.t("vagrant_skytap.connections.tunnel.verb_use")
          end

          def execute
            # No-op
          end
        end

        class CreateAndUseExecution < TunnelExecution
          def verb
            I18n.t("vagrant_skytap.connections.tunnel.verb_create_and_use")
          end

          def execute
            guest_network.connect_to_network(host_network)
          end
        end
      end
    end
  end
end
