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
require "vagrant-skytap/api/client"

describe VagrantPlugins::Skytap::API::Client do
  include_context "rest_api"

  let(:provider_config) do
    double(:provider_config, vm_url: "/vms/1", username: "jsmith", api_token: "123123", base_url: base_url)
  end
  let(:instance)   { described_class.new(provider_config) }

  before :each do
    stub_request(:get, /.*/).to_return(body: "{}", status: 200)
  end

  describe "user_agent_string" do
    subject do
      instance.send(:user_agent_string)
    end
    it {should match %r{^Vagrant-Skytap/.* Vagrant/.*}}
  end
end
