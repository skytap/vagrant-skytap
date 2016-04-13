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
require 'vagrant-skytap/api/network'

# Represents an inter-configuration network routing (ICNR) tunnel,
# allowing connections between networks in two different environments.

module VagrantPlugins
  module Skytap
    module API
      class Tunnel < Resource
        reads :status
        attr_reader :source_network, :target_network

        class << self
          # Creates a tunnel between two networks in different environments.
          # The API response includes information about both networks, but
          # omits their tunnel collections, so no attempt is made to update
          # the network objects automatically.
          #
          # @param [Hash] env The environment hash
          # @param [API::Network] network The network making the connection
          # @param [API::Network] other_network The tunnelable network being
          #   connected to
          # @return [API::Tunnel]
          def create!(env, network, other_network)
            params = {source_network_id: network.id, target_network_id: other_network.id}
            resp = env[:api_client].post("/tunnels", JSON.dump(params))
            new(JSON.load(resp.body), env)
          end
        end

        def initialize(attrs, env)
          super
          @source_network = Network.new(get_api_attribute('source_network'), env[:environment], env)
          @target_network = Network.new(get_api_attribute('target_network'), env[:environment], env)
        end

        # Indicates whether the tunnel is busy.
        #
        # @return [Boolean]
        def busy?
          status == "busy"
        end
      end
    end
  end
end
