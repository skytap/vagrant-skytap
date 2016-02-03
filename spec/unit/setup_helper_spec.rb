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
require "vagrant-skytap/setup_helper"
require "vagrant-skytap/api/environment"
require "vagrant-skytap/api/vpn"
require "vagrant-skytap/api/vpn_attachment"
require "vagrant-skytap/config"

describe VagrantPlugins::Skytap::SetupHelper do
  include_context "rest_api"

  let(:instance) { described_class.new }
  let(:json_path) { File.join(File.expand_path('..', __FILE__), 'support', 'api_responses') }

  let(:vm1_attrs) { read_json(json_path, 'vm1.json') }
  let(:network1_attrs) { read_json(json_path, 'network1.json') }
  let(:vpn1_attrs) { read_json(json_path, 'vpn1.json') }
  let(:vpn_attachment1_attrs) { read_json(json_path, 'vpn_attachment1.json') }
  let(:empty_environment_attrs) { read_json(json_path, 'empty_environment.json')}

  let(:network_attrs) do
    network1_attrs.dup.tap do |ret|
      ret['vpn_attachments'] = [vpn_attachment1_attrs]
    end
  end

  let(:vm_attrs) do
    vm1_attrs.dup.tap do |ret|
      ret['interfaces'].first['nat_addresses']['vpn_nat_addresses'] = {}
    end
  end

  let(:environment_attrs) do
    empty_environment_attrs.dup.tap do |ret|
      ret['vms'] = [vm_attrs]
      ret['networks'] = [network1_attrs]
    end
  end

  let(:environment) { VagrantPlugins::Skytap::API::Environment.new(environment_attrs, env) }

  let(:vpn_attrs) do
    vpn1_attrs.dup.tap do |ret|
      ret['network_attachments'] = [vpn_attachment1_attrs]
    end
  end

  let(:vpn) {VagrantPlugins::Skytap::API::Vpn.new(vpn_attrs, env)}

  let(:ssh_config) do
    double(:ssh, username: "foo", password: "bar", host: nil, port: nil)
  end
  let(:machine_config) do
    double(:machine_config, ssh: ssh_config)
  end
  let(:provider_config) do
    double(:provider_config, vm_url: "/vms/1", username: "jsmith", api_token: "123123", base_url: base_url)
  end
  let(:api_client) { API::Client.new(provider_config) }
  let(:machine)    { double(:machine, name: "vm1", id: "6981850", config: machine_config, provider_config: provider_config) }
  let(:env)        { { machine: machine, api_client: api_client, ui: ui } }
  let(:instance)   { described_class.new(env, environment) }

  before :each do
    # Ensure tests are not affected by Skytap credential environment variables
    ENV.stub(:[] => nil)
    stub_request(:get, /.*/).to_return(body: '{}', status: 200)
    stub_request(:get, %r{/configurations/\d+}).to_return(body: JSON.dump(environment_attrs), status: 200)
    stub_request(:get, %r{/vpns$}).to_return(body: JSON.dump([vpn_attrs]), status: 200)
  end

  describe "ask_routing" do
    subject do
      instance
    end

    before :each do
      allow(subject).to receive(:vpns).and_return([vpn])
    end

    after(:each) do
      allow_any_instance_of(VpnChoice).to receive(:choose).and_call_original
    end

    it "has connection_choices" do
      interface = subject.current_vm.interfaces.first
      choices = subject.send(:connection_choices, interface)
      expect(choices.count).to eq 1
      expect(choices.first.vpn).to_not be_nil
    end

    it "does not show choices if vpn_url specified" do
      allow(provider_config).to receive(:vpn_url).and_return(vpn.url)
      vpn_choice = double(:choice, vpn: vpn, choose: ['1.2.3.4', 22], :valid? => true)
      allow(vpn).to receive(:choice_for_setup).and_return(vpn_choice)
      expect(subject).not_to receive(:ask_from_list)
      subject.send(:ask_routing)
    end

    it "raises DoesNotExist if non-existent vpn_url specified" do
      allow(provider_config).to receive(:vpn_url).and_return("bogus")
      expect{subject.send(:ask_routing)}.to raise_error(Errors::DoesNotExist)
    end

    it "shows choices if vpn_url unspecified" do
      allow(provider_config).to receive(:vpn_url).and_return(nil)
      expect(subject).to receive(:ask_from_list)
      subject.send(:ask_routing)
    end
  end
end
