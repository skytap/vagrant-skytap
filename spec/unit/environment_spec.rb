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

describe VagrantPlugins::Skytap::API::Environment do
  include_context "rest_api"

  let(:json_path) { File.join(File.expand_path('..', __FILE__), 'support', 'api_responses') }
  let(:vm1_attrs) { read_json(json_path, 'vm1.json') }
  let(:vm2_attrs) { vm1_attrs.merge("id" => "6981851", "name" => "VM2") }
  let(:config_vm_attrs) do
    vm1_attrs.merge("configuration_url" => "https://example.com/configurations/5570024", "template_url" => nil)
  end
  let(:network1_attrs) { read_json(json_path, 'network1.json') }
  let(:vpn_attachment1_attrs) { read_json(json_path, 'vpn_attachment1.json') }
  let(:empty_environment_attrs) { read_json(json_path, 'empty_environment.json') }
  let(:empty_publish_set_attrs) { read_json(json_path, 'empty_publish_set.json') }

  let(:attrs_one_vm) do
    empty_environment_attrs.dup.tap do |ret|
      ret['vms'] = [vm1_attrs]
      ret['networks'] = [network1_attrs.dup.tap do |ret|
        ret['vpn_attachments'] = [vpn_attachment1_attrs]
      end]
    end
  end

  let(:attrs) do
    attrs_one_vm.dup.tap do |ret|
      ret['vms'] = [vm1_attrs, vm2_attrs]
      ret['publish_sets'] = [empty_publish_set_attrs.dup]
      ret['publish_sets'].first['vms'] = [
        {"vm_ref" => "http://example.com/vms/#{vm1_attrs['id']}"},
        {"vm_ref" => "http://example.com/vms/#{vm2_attrs['id']}"}
      ]
    end
  end

  let(:provider_config) do
    double(:provider_config, vm_url: "/vms/1", username: "jsmith", api_token: "123123", base_url: base_url)
  end
  let(:api_client) { API::Client.new(provider_config) }
  let(:machine)    { double(:machine, name: "vm1", id: nil, :id= => nil, provider_config: provider_config) }
  let(:env)        { { machine: machine, api_client: api_client } }
  let(:instance)   { described_class.new(attrs, env) }

  # Ensure tests are not affected by Skytap credential environment variables
  before :each do
    ENV.stub(:[] => nil)
    stub_request(:get, /.*/).to_return(body: '{}', status: 200)
    stub_request(:get, %r{/configurations/\d+}).to_return(body: JSON.dump(attrs), status: 200)
  end

  describe "check_vm_before_adding class method" do
    let(:template_vm)    {double(:template_vm,    id: 1, :stopped? => true,  parent_url: "https://example.com/templates/1")}
    let(:environment_vm) {double(:environment_vm, id: 2, :stopped? => true,  parent_url: "https://example.com/configurations/1")}
    let(:running_vm)     {double(:running_vm,     id: 3, :stopped? => false, parent_url: "https://example.com/templates/1", url: "https://example.com/vms/1")}

    let(:vm_in_different_template)        {double(:vm_in_different_template, id: 4, :stopped? => true, parent_url: "https://example.com/templates/2")}
    let(:vm_in_different_environment)     {double(:vm_in_different_environment, id: 5, :stopped? => true, parent_url: "https://example.com/configurations/2")}
    let(:environment_in_different_region) {double(:environment_in_different_region, region: "EMEA")}
    let(:vm_in_different_region)          {double(:vm_in_different_region, id: 6, :stopped? => true, parent_url: "https://example.com/templates/3", parent: environment_in_different_region)}

    it "raises SourceVmNotStopped if the vm is not stopped" do
      expect {described_class.check_vms_before_adding([running_vm])}.to raise_error(Errors::SourceVmNotStopped)
    end

    it "raises nothing if the vm is stopped" do
      expect {described_class.check_vms_before_adding([template_vm])}.to_not raise_error
    end

    it "raises nothing if the vm is part of a template" do
      expect {described_class.check_vms_before_adding([template_vm])}.to_not raise_error
    end

    it "raises nothing if the vm is part of an environment" do
      expect {described_class.check_vms_before_adding([environment_vm])}.to_not raise_error
    end

    it "raises nothing if both vms are part of same template" do
      expect {described_class.check_vms_before_adding([template_vm, template_vm])}.to_not raise_error
    end

    it "raises nothing if both vms are part of same environment" do
      expect {described_class.check_vms_before_adding([environment_vm, environment_vm])}.to_not raise_error
    end

    it "raises VmParentMismatch if vms are from different environments" do
      expect {described_class.check_vms_before_adding([environment_vm, vm_in_different_environment])}.to raise_error(Errors::VmParentMismatch)
    end

    it "raises VmParentMismatch if vms are from different templates" do
      expect {described_class.check_vms_before_adding([template_vm, vm_in_different_template])}.to raise_error(Errors::VmParentMismatch)
    end

    it "raises VmParentMismatch if vms are from an environment and template" do
      expect {described_class.check_vms_before_adding([template_vm, environment_vm])}.to raise_error(Errors::VmParentMismatch)
    end

    it "raises RegionMismatch if vm is from a template in a different region from the given environment" do
      expect {described_class.check_vms_before_adding([vm_in_different_region], instance)}.to raise_error(Errors::RegionMismatch)
    end
  end

  describe "vms" do
    subject do
      instance.vms.first
    end
    it { should be_a VagrantPlugins::Skytap::API::Vm }
  end

  describe "networks" do
    subject do
      instance.networks.first
    end
    it { should be_a VagrantPlugins::Skytap::API::Network }
  end

  describe "publish_sets" do
    subject do
      instance.publish_sets.first
    end
    it { should be_a VagrantPlugins::Skytap::API::PublishSet }
  end

  describe "get_vm_by_id" do
    subject do
      instance
    end

    it "should return the appropriate vm from the collection" do
      expect(subject.vms.count).to eq 2
      expect(subject.get_vm_by_id('6981850').get_api_attribute('name')).to eq 'VM1'
      expect(subject.get_vm_by_id('6981851').get_api_attribute('name')).to eq 'VM2'
    end
  end

  describe "get_vms_by_id" do
    subject do
      instance
    end

    it "should return the appropriate vms from the collection" do
      expect(subject.vms.count).to eq 2
      expect(subject.get_vms_by_id(['6981850', '6981851']).collect(&:name)).to eq ['VM1', 'VM2']
    end
  end

  describe "reload" do
    before do
      new_attrs = attrs.merge('name' => 'Environment with 2 vms')
      stub_request(:get, %r{/configurations/\d+}).to_return(body: JSON.dump(new_attrs), status: 200)
    end

    subject do
      old_attrs = attrs_one_vm.merge('networks' => [], 'publish_sets' => [])
      described_class.new(old_attrs, env)
    end

    it "reloads the child objects" do
      expect(subject.name).to eq 'Environment 1'
      expect(subject.vms.count).to eq 1
      expect(subject.networks.count).to eq 0
      expect(subject.publish_sets.count).to eq 0
      subject.reload
      expect(subject.name).to eq 'Environment with 2 vms'
      expect(subject.vms.count).to eq 2
      expect(subject.networks.count).to eq 1
      expect(subject.publish_sets.count).to eq 1
    end
  end

  describe "busy?" do
    subject do
      instance
    end

    it "returns false when stopped" do
      allow(subject).to receive(:runstate).and_return('stopped')
      expect(subject.busy?).to eq false
      allow(subject).to receive(:runstate).and_call_original
    end

    it "returns false when running" do
      allow(subject).to receive(:runstate).and_return('running')
      expect(subject.busy?).to eq false
      allow(subject).to receive(:runstate).and_call_original
    end

    it "returns true when runstate is busy" do
      allow(subject).to receive(:runstate).and_return('busy')
      expect(subject.busy?).to eq true
      allow(subject).to receive(:runstate).and_call_original
    end
  end
end
