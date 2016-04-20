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

module VagrantPlugins
  module Skytap
    module API
      class VpnAttachment < Resource
        attr_reader :network

        reads :connected, :network, :vpn

        def self.create(network, vpn, env)
          path = "#{base_url(network.id, network.environment.id)}?id=#{vpn.id}"
          resp = env[:api_client].post(path)
          body = JSON.load(resp.body)
          new(body, network, env)
        end

        def self.base_url(network_id, environment_id)
          "/configurations/#{environment_id}/networks/#{network_id}/vpns"
        end

        def initialize(attrs, network, env)
          super
          @network = network
        end

        def url
          environment_id = network['configuration_id']
          network_id = network['id']
          vpn_id = vpn['id']
          "#{self.class.base_url(network_id, environment_id)}/#{vpn_id}"
        end

        def nat_enabled?
          vpn['nat_enabled']
        end

        def connected?
          !!connected
        end

        def connect!
          update(connected: true)
          raise Errors::VpnConnectionFailed unless connected?
        end

        def vpn_name
          vpn['name']
        end
      end
    end
  end
end

