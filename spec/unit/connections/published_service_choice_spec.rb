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
require 'vagrant-skytap/connection/published_service_choice'

describe VagrantPlugins::Skytap::Connection::PublishedServiceChoice do
  include_context "skytap"

  let(:env)               { {} }
  let(:ip_address)        { '10.5.0.1' }
  let(:port)              { 12345 }
  let(:internal_port)     { 22 }
  let(:host_port_tuple)   { [ip_address, port] }
  let(:interface)         { double(:interface, create_published_service: published_service) }
  let(:published_service) { double(:published_service, external_ip: ip_address, external_port: port, internal_port: internal_port) }
  let(:service)           { published_service }

  let(:instance) { described_class.new(env, interface, service) }

  describe "choose" do
    subject { instance.choose }

    context "when service does not exist" do
      let(:service) { nil }
      before do
        expect(interface).to receive(:create_published_service)
      end
      it { should == host_port_tuple }
    end

    context "when service exists" do
      before do
        expect(interface).to_not receive(:create_published_service)
      end
      it { should == host_port_tuple }
    end
  end

  describe "valid?" do
    subject { instance.valid? }

    context "when service does not exist" do
      let(:service) { nil }
      it { should be true }
    end

    context "when service exists" do
      context "with default port" do
        it { should be true }
      end

      context "with non-standard port" do
        let(:internal_port) { 9999 }
        it { should be false }
      end
    end
  end
end

