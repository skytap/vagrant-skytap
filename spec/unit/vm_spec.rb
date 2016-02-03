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
  let(:instance)   { described_class.new(attrs, env) }

  let(:environment) do
    env_attrs = empty_environment_attrs
    VagrantPlugins::Skytap::API::Environment.new(env_attrs, env)
  end

  let(:attrs)    { vm1_attrs }
  let(:instance) { described_class.new(attrs, environment, env) }

  # Ensure tests are not affected by Skytap credential environment variables
  before :each do
    ENV.stub(:[] => nil)
    stub_request(:get, /.*/).to_return(body: '{}', status: 200)
    stub_request(:get, %r{/vms/\d+}).to_return(body: JSON.dump(attrs), status: 200)
  end

  describe "reload" do
    subject do
      new_attrs = attrs.merge('name' => 'VM1, renamed')
      client = double('api_client',
        get: double('resp', body: JSON.dump(new_attrs))
      )
      myenv = env.merge(api_client: client)
      described_class.new(attrs, environment, myenv)
    end

    it "updates the attrs" do
      expect(subject.get_api_attribute('name')).to eq 'VM1'
      subject.reload
      expect(subject.get_api_attribute('name')).to eq 'VM1, renamed'
    end
  end

  describe "url" do
    subject do
      instance
    end
    its("url") { should == '/vms/6981850'}
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

  describe "running?" do
    subject do
      instance
    end

    it "returns false when stopped" do
      allow(subject).to receive(:runstate).and_return('stopped')
      expect(subject.running?).to eq false
      allow(subject).to receive(:runstate).and_call_original
    end

    it "returns false when suspended" do
      allow(subject).to receive(:runstate).and_return('suspended')
      expect(subject.running?).to eq false
      allow(subject).to receive(:runstate).and_call_original
    end

    it "returns false when runstate is busy" do
      allow(subject).to receive(:runstate).and_return('busy')
      expect(subject.running?).to eq false
      allow(subject).to receive(:runstate).and_call_original
    end

    it "returns true when running" do
      allow(subject).to receive(:runstate).and_return('running')
      expect(subject.running?).to eq true
      allow(subject).to receive(:runstate).and_call_original
    end
  end

  describe "region" do
    subject do
      fake_template_attrs = {'id' => '5570024', 'region' => 'EMEA'}
      client = double('api_client',
        get: double('resp', body: JSON.dump(fake_template_attrs))
      )
      myenv = env.merge(api_client: client)
      described_class.new(attrs, environment, myenv)
    end
    its("region") { should == 'EMEA' }
  end
end
