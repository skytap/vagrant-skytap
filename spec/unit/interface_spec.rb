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

describe VagrantPlugins::Skytap::API::Interface do
  include_context "rest_api"

  let(:json_path)       { File.join(File.expand_path('..', __FILE__), 'support', 'api_responses') }
  let(:vm1_attrs)       { read_json(json_path, 'vm1.json') }
  let(:interface_attrs) { vm1_attrs['interfaces'].first }

  let(:env)             { {} }
  let(:network)         { double(:network, id: "2") }
  let(:vm)              { nil }

  let(:attrs)       { interface_attrs }
  let(:instance)    { described_class.new(attrs, vm, env) }

  describe "nat_address_for_network" do
    subject { instance.nat_address_for_network(network) }

    context "when subject has a nat address from the network" do
      it { should eq "10.0.4.1" }
    end

    context "when subject has a nat address from a different network" do
      before do
        allow(network).to receive(:id).and_return("3")
      end
      it { should be nil }
    end
  end
end
