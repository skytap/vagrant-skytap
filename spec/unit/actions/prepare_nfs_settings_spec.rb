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

  let(:app) { lambda { |env| } }
  let(:env) { { machine: machine} }

  let(:machine)         { double(:machine, config: config, provider_config: provider_config, ssh_info: {host: guest_ip}) }
  let(:config)          { double(:config, vm: vm_config) }
  let(:vm_config)       { double(:vm_config, synced_folders: synced_folders) }
  let(:provider_config) { double(:provider_config) }
  let(:host_ip)         { '10.0.0.1' }
  let(:guest_ip)        { '192.168.0.1' }
  let(:using_nfs)       { false }

  let(:default_folder_props) do
    {guestpath: "/vagrant", hostpath: ".", disabled: false}
  end
  let(:synced_folders)  { { "/vagrant" => default_folder_props } }

  let(:instance)        { described_class.new(app, env) }

  before do
    allow(instance).to receive(:machine).and_return(machine)
    allow(subject).to receive(:using_nfs?).and_return(using_nfs)
    allow(subject).to receive(:read_host_ip).and_return(host_ip)
  end

  describe "#call" do
    subject {instance}

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
        let(:default_folder_props) do
          {guestpath: "/vagrant", hostpath: ".", disabled: false, type: :rsync}
        end
        it {should be false }
      end

      context "when its type is nfs" do
        let(:default_folder_props) do
          {guestpath: "/vagrant", hostpath: ".", disabled: false, type: :nfs}
        end
        it {should be true }

        context "when it is disabled" do
          let(:default_folder_props) do
            {guestpath: "/vagrant", hostpath: ".", disabled: true, type: :nfs}
          end
          it {should be false }
        end
      end
    end
  end
end
