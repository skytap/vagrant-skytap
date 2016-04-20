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
require "vagrant-skytap/action/update_hardware"

describe VagrantPlugins::Skytap::Action::UpdateHardware do
  include_context "skytap"

  let(:app) { lambda { |env| } }
  let(:env) { { machine: machine, machines: [machine], environment: environment} }

  let(:machine)         { double(:machine, name: "vm1", id: nil, provider_config: provider_config) }
  let(:provider_config) { double(:provider_config, cpus: 4, cpuspersocket: 2, ram: 1024, guestos: "linux") }
  let(:environment)     { double(:environment) }
  let(:vm)              { double(:vm, hardware: {'cpus' => 1, 'cpus_per_socket' => 1, 'ram' => 1024, 'guestOS' => 'other'}) }

  let(:subject)     { described_class.new(app, env) }

  describe "#call" do
    it "filters out unchanged hardware properties" do
      allow(subject).to receive(:current_vm).and_return(vm)
      expect(vm).to receive(:update).with(hardware: {cpus: 4, cpus_per_socket: 2, guestOS: "linux"})
      subject.call(env)
    end
  end

  describe "current_vm" do
    it "returns nil if environment does not exist" do
      myenv = env.merge(environment: nil)
      subject = described_class.new(app, myenv)
      expect(subject.current_vm(myenv)).to be nil
      subject.call(myenv)
    end

    it "returns nil if no such vm exists" do
      expect(environment).to receive(:get_vms_by_id).once.and_return([])
      subject = described_class.new(app, env)
      expect(subject.current_vm(env)).to be(nil)
    end

    it "returns nil if machine is nil for some reason" do
      expect(environment).to_not receive(:get_vms_by_id)
      myenv = env.merge(machine: nil)
      subject = described_class.new(app, myenv)
      expect(subject.current_vm(myenv)).to be nil
    end

    it "returns the vm if found" do
      expect(environment).to receive(:get_vms_by_id).once.and_return([vm])
      subject = described_class.new(nil, env)
      expect(subject.current_vm(env)).to be(vm)
    end
  end
end
