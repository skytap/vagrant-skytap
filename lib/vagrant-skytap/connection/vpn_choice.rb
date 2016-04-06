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
require 'vagrant-skytap/api/vpn_attachment'

module VagrantPlugins
  module Skytap
    module Connection
      class VpnChoice < Choice
        attr_reader :vm, :vpn, :attachment

        def initialize(env, vpn, vm)
          @env = env
          @vpn = vpn
          @vm = vm
          @iface = select_interface(vm, vpn)
          @execution = VPNAttachmentExecution.make(env, iface, vpn)
        end

        # Finds an interface on the guest VM which is connected to a network
        # which lies inside the VPN's subnet. If the VPN is NAT enabled, this
        # method simply returns the first interface.
        #
        # @param [API::Vm] vm The guest VM
        # @param [API::Vpn] vpn The VPN this VpnChoice will connect to
        # @return [API::Interface] An interface connected to a suitable network
        def select_interface(vm, vpn)
          vm.interfaces.select(&:network).tap do |ifaces|
            unless vpn.nat_enabled?
              ifaces.select! {|i| vpn.subsumes?(i.network) }
            end
          end.first
        end

        def choose
          execution.execute
          @iface = vm.reload.get_interface_by_id(iface.id)
          host = iface.address_for(vpn)
          [host, DEFAULT_PORT]
        end

        # To communicate with the guest VM over a VPN, the guest's network
        # must be both attached and connected to the VPN. The various
        # subclasses perform different REST calls depending on which of these
        # conditions are already met.
        class VPNAttachmentExecution < Execution
          attr_reader :vpn, :attachment

          def self.make(env, iface, vpn)
            attachment = iface.attachment_for(vpn)

            if attachment.try(:connected?)
              UseExecution.new(env, iface, vpn, attachment)
            elsif attachment
              ConnectAndUseExecution.new(env, iface, vpn, attachment)
            else
              AttachConnectAndUseExecution.new(env, iface, vpn)
            end
          end

          def initialize(env, iface, vpn, attachment=nil)
            super
            @vpn = vpn
            @attachment = attachment
          end

          def message
            "#{verb}: #{vpn.name}".tap do |ret|
              if vpn.nat_enabled?
                ret << " " << I18n.t("vagrant_skytap.connections.vpn_attachment.nat_enabled")
              else
                ret << " " << I18n.t("vagrant_skytap.connections.vpn_attachment.local_subnet",
                  local_subnet: vpn.local_subnet)
              end
            end
          end
        end

        class UseExecution < VPNAttachmentExecution
          def verb
            I18n.t("vagrant_skytap.connections.vpn_attachment.verb_use")
          end

          def execute
            # No-op
          end
        end

        class ConnectAndUseExecution < VPNAttachmentExecution
          def verb
            I18n.t("vagrant_skytap.connections.vpn_attachment.verb_connect")
          end

          def execute
            attachment.connect!
          end
        end

        class AttachConnectAndUseExecution < VPNAttachmentExecution
          def verb
            I18n.t("vagrant_skytap.connections.vpn_attachment.verb_attach")
          end

          def execute
            @attachment = API::VpnAttachment.create(iface.network, vpn, env)
            @attachment.connect!
          end
        end
      end
    end
  end
end
