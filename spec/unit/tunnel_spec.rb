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

require_relative 'base'

describe VagrantPlugins::Skytap::API::Tunnel do
  include_context "rest_api"

  let(:json_path)      { File.join(File.expand_path('..', __FILE__), 'support', 'api_responses') }
  let(:tunnel1_attrs)  { read_json(json_path, 'tunnel1.json') }
  let(:network1_attrs) { read_json(json_path, 'network1.json').merge("id" => "1") }
  let(:network2_attrs) { network1_attrs.merge("id" => "2", "tunnelable" => true) }

  # TODO is this backward or not???
  let(:tunnel_attrs)   { tunnel1_attrs.merge("source_network" => network2_attrs, "target_network" => network1_attrs)}

  let(:source_network) { API::Network.new(network1_attrs, nil, env) }
  let(:target_network) { API::Network.new(network2_attrs, nil, env) }

  let(:nat_subnet)     { "11.0.0.0/24" }
  let(:tunnelable)     { false }

  let(:provider_config) do
    double(:provider_config, vm_url: "/vms/1", username: "jsmith", api_token: "123123", base_url: base_url)
  end
  let(:api_client) { API::Client.new(provider_config) }

  let(:environment) {nil}
  let(:env) { { environment: environment, api_client: api_client, provider_config: provider_config } }

  let(:attrs)       { tunnel_attrs }
  let(:instance)    { described_class.new(attrs, environment, env) }

  describe "create!" do
    subject { API::Tunnel.create!(env, source_network, target_network) }

    it "should have a source and target network" do
      expect(subject.source_network).to be_a_kind_of(API::Network)
      expect(subject.source_network).to be_a_kind_of(API::Network)
      expect(a_request(:post, %r{/tunnels})).to have_been_made.once
    end
  end
end
