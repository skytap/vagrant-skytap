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
require 'vagrant-skytap/connection/public_ip_choice'

describe VagrantPlugins::Skytap::Connection::PublicIpChoice do
  include_context "skytap"

  let(:env)             { {} }
  let(:ip_address)      { '10.5.0.1' }
  let(:port)            { 22 }
  let(:host_port_tuple) { [ip_address, port] }
  let(:ip)              { double(:ip, address: ip_address, :attached? => false) }
  let(:interface)       { double(:interface, id: 1, attach_public_ip: nil) }

  let(:instance) { described_class.new(env, ip, interface) }

  describe "choose" do
    subject { instance.choose }

    context "when not attached" do
      before do
        expect(interface).to receive(:attach_public_ip)
      end
      it { should == host_port_tuple }
    end

    context "when attached" do
      before do
        allow(ip).to receive(:attached?).and_return(true)
        expect(interface).to_not receive(:attach_public_ip)
      end
      it { should == host_port_tuple }
    end
  end
end

