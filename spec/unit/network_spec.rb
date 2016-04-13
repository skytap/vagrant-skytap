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

describe VagrantPlugins::Skytap::API::Network do
  include_context "rest_api"

  let(:json_path)      { File.join(File.expand_path('..', __FILE__), 'support', 'api_responses') }
  let(:network1_attrs) { read_json(json_path, 'network1.json') }
  let(:network2_attrs) { network1_attrs.merge("id" => "2") }
  let(:network3_attrs) { network1_attrs.merge("id" => "3") }
  let(:nat_subnet)     { "11.0.0.0/24" }
  let(:tunnelable)     { true }

  let(:tunnel1_attrs)  { read_json(json_path, 'tunnel1.json').merge("source_network" => network1_attrs, "target_network" => network2_attrs) }
  let(:tunnel2_attrs)  { tunnel1_attrs.merge("target_network" => network3_attrs) }
  let(:tunnels_attrs)  { [tunnel1_attrs] }

  let(:env)         { { ui: ui } }
  let(:attrs)       { network1_attrs.merge("tunnels" => tunnels_attrs) }
  let(:instance)    { described_class.new(attrs, nil, env) }

  describe "nat_enabled?" do
    subject     {instance.nat_enabled?}
    let(:attrs) {network1_attrs.merge("nat_subnet" => nat_subnet)}

    context "when nat subnet is set" do
      it {should be true}
    end

    context "when nat subnet is unset" do
      let(:nat_subnet) {nil}
      it {should be false}
    end
  end

  describe "tunnelable?" do
    subject     {instance.tunnelable?}
    let(:attrs) {network1_attrs.merge("tunnelable" => tunnelable)}

    context "when tunnelable" do
      it {should be true}
    end

    context "when not tunnelable" do
      let(:tunnelable) {false}
      it {should be false}
    end
  end

  describe "tunnels" do
    subject {instance.tunnels}

    context "when no tunnels exist" do
      let(:tunnels_attrs) { [] }
      it {should eq []}
    end

    context "when a tunnel exists" do
      its("count") {should eq 1}
      its("first") {should be_a(API::Tunnel)}
    end
  end

  describe "connected_to_network?" do
    subject {instance.connected_to_network?(network2)}

    before do
      allow(instance).to receive(:tunnels).and_return(tunnels)
    end

    let(:network2)      { double(:network2, id: 2) }
    let(:network3)      { double(:network3, id: 3) }
    let(:tunnel_to_2)   { double(:tunnel_to_2, source_network: instance, target_network: network2) }
    let(:tunnel_to_3)   { double(:tunnel_to_3, source_network: instance, target_network: network3) }

    context "when not connected to anything" do
      let(:tunnels) { [] }
      it {should eq false}
    end

    context "when connected to the specified network" do
      let(:tunnels) { [tunnel_to_2] }
      it {should eq true}
    end

    context "when connected to a different network" do
      let(:tunnels) { [tunnel_to_3] }
      it {should eq false}
    end

    context "when connected to both networks" do
      let(:tunnels) { [tunnel_to_2, tunnel_to_3] }
      it {should eq true}
    end

    context "when the endpoints are reversed" do
      let(:tunnel_to_2_reversed) { double(:tunnel_to_2_reversed, source_network: network2, target_network: instance) }
      let(:tunnels)              { [tunnel_to_2_reversed] }
      it {should eq true}
    end
  end
end
