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

describe VagrantPlugins::Skytap::SetupHelper do
  include_context "rest_api"

  let(:json_path)      { File.join(File.expand_path('..', __FILE__), 'support', 'api_responses') }
  let(:vpn_attachment_attrs)   { read_json(json_path, 'vpn_attachment1.json') }

  let(:vm_attrs) do
    read_json(json_path, 'vm1.json').tap do |ret|
      ret['interfaces'].first['nat_addresses']['vpn_nat_addresses'] = {}
    end
  end

  let(:network_attrs) do
    read_json(json_path, 'network1.json').tap do |ret|
      ret['vpn_attachments'] = [vpn_attachment_attrs]
    end
  end

  let(:environment_attrs) do
    read_json(json_path, 'empty_environment.json').tap do |ret|
      ret['vms']      = [vm_attrs]
      ret['networks'] = [network_attrs]
    end
  end

  let(:environment) do
    API::Environment.new(environment_attrs, env)
  end

  let(:vpn_attrs) do
    read_json(json_path, 'vpn1.json').dup.tap do |ret|
      ret['network_attachments'] = [vpn_attachment_attrs]
    end
  end

  let(:vpn)          {API::Vpn.new(vpn_attrs, env)}
  let(:vpns)         {[vpn]}
  let(:vpn_choice)   {double(:vpn_choice, vpn: vpn, choose: ["1.2.3.4", 22], :valid? => true)}
  let(:icnr_choice)  {double(:icnr_choice, choose: ["10.0.0.1", 22], :valid? => icnr_valid, validation_error_message: icnr_err_msg)}
  let(:icnr_valid)   { true }
  let(:icnr_err_msg) { nil }
  let(:user_input)   { "" }
  let(:running_in_skytap_vm) {false}

  let(:ssh_config) do
    double(:ssh_config, username: nil, password: nil, host: nil, port: nil)
  end
  let(:machine_config) do
    double(:machine_config, ssh: ssh_config)
  end
  let(:vpn_url) {"/vpns/vpn-123"}
  let(:provider_config) do
    double(:provider_config, vm_url: "/vms/1", username: "jsmith", api_token: "123123", base_url: base_url, vpn_url: vpn_url)
  end
  let(:api_client) { API::Client.new(provider_config) }
  let(:machine)    { double(:machine, name: "vm1", id: "6981850", config: machine_config, provider_config: provider_config) }
  let(:env)        { { machine: machine, api_client: api_client, ui: ui } }
  let(:instance)   { described_class.new(env, environment) }

  before :each do
    # Ensure tests are not affected by Skytap credential environment variables
    ENV.stub(:[] => nil)
    allow(ui).to receive(:ask).and_return(user_input)
    allow(instance).to receive(:vpns).and_return(vpns)
    allow(instance).to receive(:running_in_skytap_vm?).and_return(running_in_skytap_vm)
    allow(vpn).to receive(:choice_for_setup).and_return(vpn_choice)
    stub_request(:get, /.*/).to_return(body: "{}", status: 200)
  end

  describe "connection_choices" do
    subject do
      instance.send(:connection_choices, instance.current_vm.interfaces.first)
    end

    context "when there are choices" do
      it "should return a matching choice" do
        expect(subject.count).to be 1
        expect(subject.first.vpn).to be vpn
      end
    end

    context "when there are no choices" do
      let(:vpns) {[]}
      it { should eq [] }
    end
  end

  describe "ask_routing" do
    subject do
      instance.send(:ask_routing)
    end

    before do
      allow(instance).to receive(:connection_choices).and_return(choices)
    end

    context "when not running in Skytap VM" do
      let(:choices) { [vpn_choice] }

      context "when valid vpn_url specified" do
        it {should eq ["1.2.3.4", 22]}
      end

      context "when invalid vpn_url specified" do
        let(:vpn_url) {"bogus"}
        it "raises error" do
          expect{subject}.to raise_error Errors::DoesNotExist
        end
      end

      context "when vpn_url unspecified" do
        let(:vpn_url)    {nil}
        let(:user_input) {"1"}
        it {should eq ["1.2.3.4", 22]}
      end

      context "when no valid vpns exist" do
        before do
          allow(vpn_choice).to receive(:valid?).and_return(false)
        end
        it "raises error" do
          expect{subject}.to raise_error Errors::NoConnectionOptions
        end
      end
    end

    context "when running in Skytap VM" do
      let(:running_in_skytap_vm) {true}
      let(:choices) { [icnr_choice] }

      context "when choice is valid" do
        it {should eq ["10.0.0.1", 22]}
      end

      context "when choice is not valid" do
        let(:icnr_valid)  { false }
        it "raises error" do
          expect{subject}.to raise_error Errors::NoSkytapConnectionOptions
        end
      end
    end
  end

  describe "ask_credentials" do
    subject do
      instance.send(:ask_credentials)
    end

    context "when username and password are set" do
      let(:ssh_config) {double(:ssh_config, username: "foo", password: "bar", host: nil, port: nil)}
      it {should eq %w[foo bar]}
    end

    context "when only username is set and it matches a set of stored credentials" do
      let(:ssh_config) {double(:ssh_config, username: "skytap", password: nil, host: nil, port: nil)}
      it {should eq ["skytap", nil]}
    end

    context "when username and password are not set but stored credentials exist" do
      let(:user_input) {"1"}
      it {should eq %w[skytap skypass]}
    end

    context "when username and password are not set and no stored credentials exist" do
      before do
        allow(instance.current_vm).to receive(:credentials).and_return([])
      end
      it {should eq [nil, nil]}
    end
  end

  describe "ask_from_list" do
    subject do
      instance.send(:ask_from_list, "Prompt", ["aaa", "bbb"], 0)
    end

    context "when user enters nothing" do
      let(:user_input) {""}
      it {should eq 0}
    end

    context "when user enters numeral" do
      let(:user_input) {" 2 "}
      it {should eq 1}
    end
  end

  describe "credentials_choices" do
    subject do
      instance.send(:credentials_choices, instance.current_vm.credentials)
    end
    it "returns a list of the vm's credentials plus the default vagrant login" do
      expect(subject).to eq([
        "Use VM credentials stored in Skytap: skytap / skypass",
        "Don't specify credentials: Use standard 'vagrant' login with insecure keypair"
      ])
    end
  end
end
