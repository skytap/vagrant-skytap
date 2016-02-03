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

describe VagrantPlugins::Skytap::Action::ComposeEnvironment do
  include_context "rest_api"

  let(:app) { lambda { |env| } }
  let(:env) { { machine: machine, machines: [machine], environment: environment, ui: ui, api_client: api_client } }
  let(:provider_config) do
    double(:provider_config, vm_url: "/vms/1", username: "jsmith", api_token: "123123", base_url: base_url)
  end
  let(:api_client) { API::Client.new(provider_config) }

  let(:machine)          { double(:machine, name: "vm1", id: nil, :id= => nil, provider_config: provider_config) }
  let(:existing_machine) { double(:existing_machine, name: "vm2", id: 2) }

  let(:environment)     { double(:environment, url: "foo") }
  let(:new_environment) { double(:environment, url: "foo", vms: [vm], properties: environment_properties) }
  let(:vm)              { double(:vm, id: 1, parent_url: "https://example.com/templates/1") }

  let(:environment_properties) { double(:environment_properties, read: nil, write: nil) }

  let(:subject) { described_class.new(app, env) }

  before do
    stub_request(:get, /.*/).to_return(body: '{}', status: 200)
  end

  describe "#call" do
    it "does nothing if all machines exist" do
      machine.stub(id: 1)
      expect(app).to receive(:call).with(env)

      expect(API::Environment).to_not receive(:create!)
      expect(API::Vm).to_not receive(:fetch)
      expect(environment).to_not receive(:add_vms)

      subject.call(env)
    end

    it "makes a single create! call when creating an environment with 1 machine", run: true do
      myenv = env.merge(environment: nil)
      expect(app).to receive(:call).with(myenv)

      expect(API::Environment).to receive(:create!).and_return(new_environment)
      expect(API::Vm).to receive(:fetch).once.and_return(vm)
      expect(environment).to_not receive(:add_vms)

      subject.call(myenv)
    end

    it "makes a single add_vms call when adding 1 machine to existing environment" do
      myenv = env.merge(machines: [machine, existing_machine])
      expect(app).to receive(:call).with(myenv)

      expect(API::Environment).to_not receive(:create!)
      expect(API::Vm).to receive(:fetch).once.and_return(vm)
      expect(environment).to receive(:add_vms).once.and_return([vm])

      subject.call(myenv)
    end
  end

  describe "fetch_source_vms" do
    it "fetches a vm and returns a mapping" do
      vms = subject.fetch_source_vms([machine])
      expect(a_request(:get, %r{/vms/\d+$})).to have_been_made.once
      expect(vms.count).to eq(1)
      expect(vms.keys.first).to eq("vm1")
      expect(vms.values.first).to be_a_kind_of(API::Vm)
    end
  end

  describe "get_groupings" do
    let(:vm_in_same_template)      { double(:vm_in_same_template,      id: 2, parent_url: "https://example.com/templates/1")}
    let(:vm_in_different_template) { double(:vm_in_different_template, id: 3, parent_url: "https://example.com/templates/2")}

    it "returns a single group for a single vm" do
      expect(subject.get_groupings({"vm1" => vm})).to eq([ ["vm1"] ])
    end

    it "groups vms in same template together" do
      expect(subject.get_groupings({"vm1" => vm, "vm2" => vm_in_same_template})).to eq([ ["vm1", "vm2"] ])
    end

    it "groups vms in different templates separately" do
      # These are expected to be in reverse order, because we sort them descending by count
      expect(subject.get_groupings({"vm1" => vm, "vm2" => vm_in_different_template})).to eq([ ["vm2"], ["vm1"] ])
    end

    it "groups identical vms separately" do
      expect(subject.get_groupings({"vm1" => vm, "vm2" => vm})).to eq([ ["vm2"], ["vm1"] ])
    end

    it "respects parallel flag" do
      expect(subject.get_groupings({"vm1" => vm, "vm2" => vm_in_same_template}, parallel: false)).to eq([ ["vm1"], ["vm2"] ])
    end
  end
end
