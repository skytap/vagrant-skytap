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

require File.expand_path("../../base", __FILE__)
require 'vagrant-skytap/connection/tunnel_choice'

describe VagrantPlugins::Skytap::Connection::TunnelChoice, tc: true do
  include_context "skytap"

  let(:env)             { {} }
  let(:nat_address)     { '11.0.0.1' }
  let(:port)            { 22 }
  let(:host_port_tuple) { [nat_address, port] }
  let(:network)         { double(:network) }
  let(:networks)        { [guest_network] }
  let(:environment)     { double(:environment, id: 1, networks: networks) }

  let(:host_network) do
    double(:host_network, id: 1, environment: environment, :connected_to_network? => connected,
           :tunnelable? => tunnelable, :nat_enabled? => host_nat_enabled)
  end
  let(:guest_network)     { double(:guest_network, id: 2, :nat_enabled? => guest_nat_enabled, connect_to_network: nil) }
  let(:connected)         { false }
  let(:tunnelable)        { false }
  let(:host_nat_enabled)  { false }
  let(:guest_nat_enabled) { false }

  let(:host_subnet)     { double(:host_subnet) }
  let(:guest_subnet)    { double(:guest_subnet, :overlaps? => overlaps) }
  let(:overlaps)        { true }

  let(:tunnel)          { double(:tunnel, source_network: guest_network, target_network: host_network, :busy? => false) }
  let(:tunnels)         { [tunnel] }
  let(:interface)       { double(:interface, id: 1, network: guest_network, nat_address_for_network: nat_address) }
  let(:interfaces)      { [interface] }
  let(:vm)              { double(:vm, id: 1, interfaces: interfaces, get_interface_by_id: interface) }

  let(:instance)        { described_class.new(env, host_network, interface) }

  before do
    allow(interface).to receive(:vm).and_return(vm)
    allow(vm).to receive(:reload).and_return(vm)
    allow(environment).to receive(:reload).and_return(environment)
    allow(host_network).to receive(:subnet).and_return(host_subnet) if host_network
    allow(guest_network).to receive(:subnet).and_return(guest_subnet) if guest_network
  end

  describe "valid?" do
    subject {instance.valid?}

    context "when the guest is not connected to a network" do
      let(:guest_network) {nil}
      it {should be false}
    end

    context "when the host network is not tunnelable" do
      it {should be false}
    end

    context "when the host network is not NAT enabled" do
      it {should be false}
    end

    context "when the host network is tunnelable and NAT enabled" do
      let(:tunnelable)       { true }
      let(:host_nat_enabled) { true }

      context "when the guest network is not NAT enabled" do
        context "when the host and guest subnets overlap" do
          it {should be false}
        end

        context "when the host and guest subnets do not overlap" do
          let(:overlaps) { false }
          it {should be true}
        end
      end

      context "when the guest network is NAT enabled" do
        let(:guest_nat_enabled) { true }
        it {should be true}
      end
    end
  end

  describe "choose" do
    subject { instance.choose }

    context "when not connected" do
      before do
        expect(guest_network).to receive(:connect_to_network)
      end
      it { should == host_port_tuple }
    end

    context "when connected" do
      let(:connected) { true }
      before do
        expect(guest_network).to_not receive(:connect_to_network)
      end
      it { should == host_port_tuple }
    end
  end
end

