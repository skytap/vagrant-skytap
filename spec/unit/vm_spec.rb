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

describe VagrantPlugins::Skytap::API::Vm do
  include_context "rest_api"

  let(:json_path) { File.join(File.expand_path('..', __FILE__), 'support', 'api_responses') }

  let(:vm1_attrs) { read_json(json_path, 'vm1.json') }
  let(:vm2_attrs) { vm1_attrs.merge("id" => "6981851", "name" => "VM2") }
  let(:network1_attrs) { read_json(json_path, 'network1.json') }
  let(:empty_environment_attrs) { read_json(json_path, 'empty_environment.json') }

  let(:provider_config) do
    double(:provider_config, vm_url: "/vms/1", username: "jsmith", api_token: "123123", base_url: base_url)
  end
  let(:api_client) { API::Client.new(provider_config) }
  let(:machine)    { double(:machine, name: "vm1", id: nil, :id= => nil, provider_config: provider_config) }
  let(:env)        { { machine: machine, api_client: api_client } }

  let(:environment) do
    env_attrs = empty_environment_attrs
    VagrantPlugins::Skytap::API::Environment.new(env_attrs, env)
  end

  let(:attrs)    { vm1_attrs }
  let(:runstate) { nil }
  let(:instance) { described_class.new(attrs, environment, env) }

  let(:get_vm_attrs) { vm1_attrs }
  before :each do
    stub_get(%r{/vms/\d+}, get_vm_attrs)
    allow(instance).to receive(:runstate).and_return(runstate)
  end

  describe "reload" do
    subject { instance.reload }
    let(:get_vm_attrs) {vm1_attrs.merge('name' => 'VM1, renamed')}
    its("name") {should eq 'VM1, renamed'}
  end

  describe "url" do
    subject do
      instance
    end
    its("url") { should == '/vms/6981850'}
  end

  describe "busy?" do
    subject { instance.busy? }

    context "when stopped" do
      let(:runstate) {'stopped'}
      it {should be false}
    end

    context "when running" do
      let(:runstate) {'running'}
      it {should be false}
    end

    context "when busy" do
      let(:runstate) {'busy'}
      it {should be true}
    end
  end

  describe "running?" do
    subject { instance.running? }

    context "when stopped" do
      let(:runstate) {'stopped'}
      it {should be false}
    end

    context "when suspended" do
      let(:runstate) {'suspended'}
      it {should be false}
    end

    context "when busy" do
      let(:runstate) {'busy'}
      it {should be false}
    end

    context "when running" do
      let(:runstate) {'running'}
      it {should be true}
    end
  end

  describe "parent" do
    subject {instance.region}

    context "when environment was passed in" do
      before do
        expect(a_request(:any, %r{.*})).not_to have_been_made
      end
      it { should eq 'US-West'}
    end

    context "when environment was not passed in" do
      let(:environment) {nil}
      before do
        stub_get(%r{/templates/\d+}, {region: 'US-East'})
      end
      it { should eq 'US-East'}
    end
  end

  describe "region" do
    subject {instance.region}

    before do
      allow(environment).to receive(:region).and_return('EMEA')
    end
    it { should eq 'EMEA' }
  end
end
