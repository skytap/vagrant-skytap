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

require 'vagrant-skytap/util/subnet'
require 'vagrant-skytap/api/resource'
require 'vagrant-skytap/api/vpn_attachment'

class VpnChoice
  attr_reader :env, :vpn, :vm, :iface, :attachment, :execution

  def initialize(env, vpn, vm)
    @env = env
    @vpn = vpn
    @vm = vm
    @iface = vm.interfaces.select(&:network).tap do |ifaces|
      unless vpn.nat_enabled?
        ifaces.select! {|i| vpn.subsumes?(i.network) }
      end
    end.first
    @execution = AttachmentExecution.make(env, vpn, iface)
  end

  def to_s
    "#{execution.verb} VPN: #{vpn.name}".tap do |ret|
      if vpn.nat_enabled?
        ret << " (NAT-enabled)"
      else
        ret << " (local subnet: #{vpn.local_subnet})"
      end
    end
  end

  def choose
    execution.execute

    @iface = vm.reload.interfaces.detect{|i| i.id == iface.id }
    host = iface.address_for(vpn)
    port = 22

    [host, port]
  end

  def valid?
    true
  end

  class AttachmentExecution
    attr_reader :env, :vpn, :iface, :attachment

    def self.make(env, vpn, iface)
      attachment = iface.attachment_for(vpn)

      if attachment.try(:connected?)
        UseAttachmentExecution.new(env, vpn, iface, attachment)
      elsif attachment
        ConnectAttachmentExecution.new(env, vpn, iface, attachment)
      else
        CreateAttachmentExecution.new(env, vpn, iface)
      end
    end

    def initialize(env, vpn, iface, attachment=nil)
      @env = env
      @vpn = vpn
      @iface = iface
      @attachment = attachment
    end

    def verb
      raise NotImplementedError.new('Must override')
    end

    def execute
      raise NotImplementedError.new('Must override')
    end
  end

  class UseAttachmentExecution < AttachmentExecution
    def verb
      'Use'
    end

    def execute
      # No-op
    end
  end

  class ConnectAttachmentExecution < AttachmentExecution
    def verb
      'Connect to and use'
    end

    def execute
      attachment.connect!
    end
  end

  class CreateAttachmentExecution < AttachmentExecution
    def verb
      'Attach to and use'
    end

    def execute
      @attachment = VagrantPlugins::Skytap::API::VpnAttachment.create(iface.network, vpn, env)
      @attachment.connect!
    end
  end
end

module VagrantPlugins
  module Skytap
    module API
      class Vpn < Resource

        class << self
          def all(env, options = {})
            resp = env[:api_client].get('/vpns', options)
            vpn_attrs = JSON.load(resp.body)
            vpn_attrs.collect {|attrs| new(attrs, env)}
          end

          def fetch(env, url, options = {})
            resp = env[:api_client].get(url, options)
            new(JSON.load(resp.body), env)
          end
        end

        reads :id, :local_subnet, :name, :nat_local_subnet

        def choice_for_setup(vm)
          VpnChoice.new(env, self, vm)
        end

        def nat_enabled?
          !!nat_local_subnet
        end

        def subsumes?(network)
          subnet.subsumes?(network.subnet)
        end

        def subnet
          Util::Subnet.new(local_subnet)
        end
      end
    end
  end
end
