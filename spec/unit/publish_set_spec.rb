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

describe VagrantPlugins::Skytap::API::PublishSet do
  include_context "rest_api"

  let(:json_path) { File.join(File.expand_path('..', __FILE__), 'support', 'api_responses') }
  let(:vm1_attrs) { read_json(json_path, 'vm1.json') }
  let(:vm2_attrs) { vm1_attrs.merge("id" => "6981851", "name" => "VM2") }
  let(:empty_environment_attrs) { read_json(json_path, 'empty_environment.json')}
  let(:empty_publish_set_attrs) { read_json(json_path, 'empty_publish_set.json')}

  let(:env_attrs) do
    empty_environment_attrs.dup.tap do |ret|
      ret['vms'] = [vm1_attrs, vm2_attrs]
    end
  end

  let(:provider_config) do
    double(:provider_config, vm_url: "/vms/1", username: "jsmith", api_token: "123123", base_url: base_url)
  end
  let(:api_client) { API::Client.new(provider_config) }
  let(:machine)    { double(:machine, name: "vm1", id: nil, :id= => nil, provider_config: provider_config) }
  let(:env)        { { machine: machine, api_client: api_client } }

  let(:environment) do
    VagrantPlugins::Skytap::API::Environment.new(env_attrs, env)
  end

  let(:attrs) do
    empty_publish_set_attrs.dup.tap do |ret|
      ret['vms'] = [
        {"vm_ref" => "http://example.com/vms/#{vm1_attrs['id']}"}
      ]
    end
  end
  let(:instance) { described_class.new(attrs, environment, env) }

  # Ensure tests are not affected by Skytap credential environment variables
  before :each do
    ENV.stub(:[] => nil)
    stub_request(:get, /.*/).to_return(body: '{}', status: 200)
    stub_request(:get, %r{/configurations/\d+}).to_return(body: JSON.dump(attrs), status: 200)
  end

  describe "vms" do
    subject do
      instance
    end

    it "returns only the vms in the publish_set" do
      expect(instance.vms.count).to eq(1)
      expect(instance.vms.first.name).to eq("VM1")
    end
  end

  describe "password_protected?" do
    subject do
      instance
    end

    it "returns false if not set" do
      expect(subject.password_protected?).to eq(false)
    end

    it "returns true if set" do
      w_pw = described_class.new(attrs.merge("password" => "*******"), environment, env)
      expect(w_pw.password_protected?).to eq(true)
    end
  end
end

