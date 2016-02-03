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
require "vagrant-skytap/model/forwarded_port"

describe VagrantPlugins::Skytap::Model::ForwardedPort do
  let(:fp1) { VagrantPlugins::Skytap::Model::ForwardedPort.new("tcp9000", 9000, 80, protocol: 'tcp') }
  let(:fp2) { VagrantPlugins::Skytap::Model::ForwardedPort.new("tcp80", 80, 80, protocol: 'tcp') }
  let(:fp3) { VagrantPlugins::Skytap::Model::ForwardedPort.new("tcp2222", 2222, 22, protocol: 'tcp') }
  let(:fp4) { VagrantPlugins::Skytap::Model::ForwardedPort.new("ssh", 2201, 22, protocol: 'tcp') }
  let(:fp5) { VagrantPlugins::Skytap::Model::ForwardedPort.new("tcp1024", 1024, 80, protocol: 'tcp') }
  let(:fp6) { VagrantPlugins::Skytap::Model::ForwardedPort.new("tcp9000", 80, 1025, protocol: 'tcp') }

  describe "privileged_host_port?" do
    it "returns false for host port above 1024" do
      expect(fp1.privileged_host_port?).to be false
    end

    it "returns true for host port below 1024" do
      expect(fp2.privileged_host_port?).to be true
    end

    it "returns true for host port 1024" do
      expect(fp5.privileged_host_port?).to be true
    end

    it "returns true for host port 80 if guest port is over 1024" do
      expect(fp6.privileged_host_port?).to be true
    end
  end

  describe "internal_ssh_port?" do
    it "returns false for typical host port" do
      expect(fp1.internal_ssh_port?).to be false
    end

    it "returns true when guest port is 22 and host port is 2222" do
      expect(fp3.internal_ssh_port?).to be true
    end

    it "returns true when id has special value 'ssh'" do
      expect(fp4.internal_ssh_port?).to be true
    end
  end
end
