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
require 'vagrant-skytap/connection/vpn_choice'

describe VagrantPlugins::Skytap::Connection::VpnChoice do
  include_context "skytap"

  let(:env)             { {} }
  let(:nat_address)     { '11.0.0.1' }
  let(:port)            { 22 }
  let(:host_port_tuple) { [nat_address, port] }
  let(:environment)     { double(:environment, id: 1) }
  let(:vpn)             { double(:vpn, id: 1, name: "My VPN", :nat_enabled? => true, :subsumes? => true) }
  let(:network)         { double(:network, id: 1, environment: environment) }
  let(:interface)       { double(:interface, id: 1, network: network, attachment_for: vpn_attachment, address_for: nat_address) }
  let(:interfaces)      { [interface] }
  let(:vm)              { double(:vm, id: 1, interfaces: interfaces, get_interface_by_id: interface) }

  let(:disconnected_vpn_attachment) { double(:disconnected_vpn_attachment, :connected? => false, :connect! => connected_vpn_attachment) }
  let(:connected_vpn_attachment)    { double(:connected_vpn_attachment, :connected? => true) }
  let(:vpn_attachment)              { disconnected_vpn_attachment }

  let(:instance) { described_class.new(env, vpn, vm) }

  before do
    allow(vm).to receive(:reload).and_return(vm)
  end

  describe "select_interface" do
    # Pass in a separate vpn to avoid errors when creating the instance
    let(:vpn2) { double(:vpn2, :nat_enabled? => nat_enabled, :subsumes? => subsumes) }
    subject    { instance.select_interface(vm, vpn2) }
    let(:nat_enabled) { true }
    let(:subsumes)    { true }

    context "when vpn is nat_enabled" do
      it { should eq interface }
    end

    context "when vpn is not nat_enabled" do
      let(:nat_enabled) { false }

      context "when vpn subsumes the network" do
        it { should eq interface }
      end

      context "when vpn does not subsume the network" do
        let(:subsumes) { false }
        it { should be nil }
      end
    end
  end

  describe "choose" do
    subject { instance.choose }
    before :each do
      allow(API::VpnAttachment).to receive(:create).and_return(disconnected_vpn_attachment)
    end

    context "when not attached" do
      let(:vpn_attachment) { nil }
      before do
        expect(API::VpnAttachment).to receive(:create)
        expect(disconnected_vpn_attachment).to receive(:connect!)
      end
      it { should == host_port_tuple }
    end

    context "when attached and disconnected" do
      let(:vpn_attachment) {disconnected_vpn_attachment}
      before do
        expect(API::VpnAttachment).to_not receive(:create)
        expect(vpn_attachment).to receive(:connect!)
      end
      it { should == host_port_tuple }
    end

    context "when attached and connected" do
      let(:vpn_attachment) {connected_vpn_attachment}
      before do
        expect(API::VpnAttachment).to_not receive(:create)
        expect(vpn_attachment).to_not receive(:connect!)
      end
      it { should == host_port_tuple }
    end
  end
end

