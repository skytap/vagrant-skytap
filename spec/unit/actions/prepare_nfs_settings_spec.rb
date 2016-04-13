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
require "vagrant-skytap/action/prepare_nfs_settings"

describe VagrantPlugins::Skytap::Action::PrepareNFSSettings do
  include_context "skytap"

  let(:json_path)       { File.join(File.expand_path('..', __FILE__), 'support', 'api_responses') }
  let(:vm1_attrs)       { read_json(json_path, 'vm1.json') }

  let(:app)             { lambda { |env| } }
  let(:host_vm)         { nil }
  let(:env)             { { machine: machine, ui: ui, host_vm: host_vm} }

  let(:machine)         { double(:machine, config: config, provider_config: provider_config, ssh_info: {host: guest_ip}) }
  let(:config)          { double(:config, vm: vm_config) }
  let(:vm_config)       { double(:vm_config, synced_folders: synced_folders) }
  let(:provider_config) { double(:provider_config) }
  let(:host_ip)         { '10.0.0.1' }
  let(:guest_ip)        { '192.168.0.1' }
  let(:using_nfs)       { false }

  let(:udpsocket)       { double("UDPSocket") }
  let(:addresses)       { ["AF_INET", 99999, '127.0.0.1', host_ip] }
  let(:socket)          { double(:socket, connect: nil, addr: addresses) }

  let(:nat_host_ip)     { '10.0.4.1' }
  let(:nat_guest_ip)    { '14.0.0.1' }
  let(:guest_network)   { double(:guest_network, id: "2", attrs: {}, :nat_enabled? => false) }
  let(:guest_iface)     { double(:guest_iface, network: guest_network) }
  let(:guest_vm)        { double(:guest_vm, interfaces: [guest_iface]) }

  let(:default_hostpath) {"."}
  let(:default_disabled) { false }
  let(:default_type)     { nil }
  let(:default_folder_props) do
    {guestpath: "/vagrant", hostpath: default_hostpath, disabled: default_disabled, type: default_type}
  end
  let(:synced_folders)  { { "/vagrant" => default_folder_props } }

  let(:instance) do
    described_class.new(app, env).tap do |instance|
      allow(instance).to receive(:machine).and_return(machine)
      allow(instance).to receive(:host_vm).and_return(host_vm)
      allow(instance).to receive(:current_vm).and_return(guest_vm)
    end
  end

  before do
    stub_const("UDPSocket", udpsocket)
    allow(udpsocket).to receive(:open).and_yield(socket)
  end

  describe "#call" do
    subject {instance}
    before do
      allow(subject).to receive(:using_nfs?).and_return(using_nfs)
    end

    context "when not using nfs" do
      it "does not set the host and guest ip addresses" do
        expect(app).to receive(:call).with(env)
        subject.call(env)
        expect(env[:nfs_host_ip]).to be nil
        expect(env[:nfs_machine_ip]).to be nil
      end
    end

    context "when using nfs" do
      let(:using_nfs) { true }
      it "sets the host and guest ip addresses" do
        expect(app).to receive(:call).with(env)
        subject.call(env)
        expect(env[:nfs_host_ip]).to eq host_ip
        expect(env[:nfs_machine_ip]).to eq guest_ip
      end
    end
  end

  describe "using_nfs?" do
    subject {instance.using_nfs?}

    context "when there is only the default folder" do
      context "when its type is unset" do
        it {should be true }
      end

      context "when its type is rsync" do
        let(:default_type) { :rsync }
        it {should be false }
      end

      context "when its type is nfs" do
        let(:default_type) { :nfs }
        it {should be true }

        context "when it is disabled" do
          let(:default_disabled) { true }
          it {should be false }
        end
      end
    end
  end

  describe "read_host_ip" do
    subject { instance.read_host_ip }

    context "when not running in a VM" do
      it { should eq host_ip }
    end

    context "when running in a VM" do
      let(:host_iface) { double(:host_iface, nat_address_for_network: nat_host_ip) }
      let(:host_vm)    { double(:host_vm, interfaces: [host_iface]) }

      before do
        allow(host_vm).to receive(:reload).and_return(host_vm)
      end

      context "when guest network is not NAT enabled" do
        it { should eq host_ip }
      end

      context "when guest network is NAT enabled" do
        before do
          allow(guest_network).to receive(:nat_enabled?).and_return(true)
        end
        it { should eq nat_host_ip }
      end
    end
  end
end
