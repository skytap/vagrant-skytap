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

require File.expand_path("../../../../base", __FILE__)
require "vagrant-skytap/model/forwarded_port"

describe "VagrantPlugins::Skytap::HostCommon::Cap::SSHTunnel" do
  let(:described_class) do
    VagrantPlugins::Skytap::Plugin.components.host_capabilities[:bsd].get(:start_ssh_tunnel)
  end

  let(:machine)         { double("machine") }
  let(:forwarded_port1) { VagrantPlugins::Skytap::Model::ForwardedPort.new('tcp9000', 9000, 80, protocol: "tcp") }
  let(:forwarded_port2) { VagrantPlugins::Skytap::Model::ForwardedPort.new('tcp9001', 9001, 81, protocol: "tcp") }
  let(:pidfile1)        { "tcp9000_tcp_9000_80.pid" }
  let(:ssh_info)        { {username: 'user', host: '10.0.0.1'} }
  let(:env_path)        { Pathname.new(File.expand_path("../../../../support/forwarded_ports", __FILE__)) }
  let(:env)             { double("env") }

  let(:subprocess)      { double("Vagrant::Util::Subprocess") }
  let(:result)          { Vagrant::Util::Subprocess::Result.new(0, "", "") }

  before do
    allow(env).to receive(:local_data_path).and_return(env_path)
    allow(machine).to receive(:data_dir).and_return(env.local_data_path.join("machines/vm1/skytap"))
    allow(machine).to receive(:ssh_info).and_return(ssh_info)
    allow(machine).to receive(:name).and_return('vm1')

    result
    stub_const("Vagrant::Util::Subprocess", subprocess)
    allow(subprocess).to receive(:execute).and_return(result)
  end

  describe "start_ssh_tunnel" do
    it "kills an existing tunnel" do
      expect(described_class).to receive(:kill_ssh_tunnel)
      #expect(subprocess).to receive(:execute).with('kill', '99999')
      #expect(subprocess).to receive(:execute).with('autossh', "-f", anything)
      described_class.start_ssh_tunnel(env, forwarded_port1, machine)
    end
  end

  describe "kill_ssh_tunnel" do
    it "kills the right process" do
      expect(subprocess).to receive(:execute).once.with('kill', '99999')
      described_class.kill_ssh_tunnel(env, forwarded_port1, machine)
    end
  end

  describe "clear_forwarded_ports" do
    it "kills two processes" do
      expect(subprocess).to receive(:execute).with('kill', '99999')
      expect(subprocess).to receive(:execute).with('kill', '90210')
      described_class.clear_forwarded_ports(env, machine)
    end
  end

  describe "read_forwarded_ports" do
    it "returns two ForwardedPort objects for vm1 only" do
      fps = described_class.read_forwarded_ports(env, machine)
      expect(fps.count).to eq(2)
      fp1, fp2 = fps.sort_by(&:id)

      expect(fp1.id).to eq("tcp9000")
      expect(fp1.host_port).to eq(9000)
      expect(fp1.guest_port).to eq(80)
      expect(fp1.protocol).to eq("tcp")

      expect(fp2.id).to eq("tcp9001")
      expect(fp2.host_port).to eq(9001)
      expect(fp2.guest_port).to eq(81)
      expect(fp2.protocol).to eq("tcp")
    end
  end

  describe "read_used_ports" do
    it "returns one ForwardedPort object for all skytap machines except vm1" do
      fps = described_class.read_used_ports(env, machine)
      expect(fps.count).to eq(2)
      fp1, fp2 = fps.sort_by(&:id)

      expect(fp1.id).to eq("tcp8080")
      expect(fp1.host_port).to eq(8080)
      expect(fp1.guest_port).to eq(80)
      expect(fp1.protocol).to eq("tcp")

      expect(fp2.id).to eq("tcp8888")
      expect(fp2.host_port).to eq(8888)
      expect(fp2.guest_port).to eq(80)
      expect(fp2.protocol).to eq("tcp")
    end
  end

  describe "read_pid" do
    it "reads the pid" do
      pid = described_class.read_pid(machine.data_dir.join(pidfile1))
      expect(pid).to eq(99999)
    end

    it "returns nil if pidfile missing" do
      pid = described_class.read_pid(machine.data_dir.join("tcp12345.pid"))
      expect(pid).to be(nil)
    end
  end

  describe "get_fp_from_directory" do
    it "gets the ForwardedPorts for the directory" do
      fps = described_class.get_fp_from_directory(machine.data_dir)
      expect(fps.count).to eq(2)
      fp1, fp2 = fps.sort_by(&:id)

      expect(fp1.id).to eq("tcp9000")
      expect(fp1.host_port).to eq(9000)
      expect(fp1.guest_port).to eq(80)
      expect(fp1.protocol).to eq("tcp")

      expect(fp2.id).to eq("tcp9001")
      expect(fp2.host_port).to eq(9001)
      expect(fp2.guest_port).to eq(81)
      expect(fp2.protocol).to eq("tcp")
    end
  end

  describe "machine_data_dirs" do
    it "gets only skytap machine dirs" do
      map = described_class.machine_data_dirs(env)
      expect(map).to eq({
        'vm1' => env_path.join("machines/vm1/skytap"),
        'vm2' => env_path.join("machines/vm2/skytap"),
        'vm4' => env_path.join("machines/vm4/skytap"),
      })
      expect(map.values.first).to be_a(Pathname)
    end
  end

  describe "pidfile_to_fp" do
    it "parses the pidfile name" do
      fp = described_class.pidfile_to_fp(pidfile1)
      expect(fp.id).to eq("tcp9000")
      expect(fp.host_port).to eq(9000)
      expect(fp.guest_port).to eq(80)
      expect(fp.protocol).to eq("tcp")
    end
  end

  describe "fp_to_pidfile" do
    it "creates the pidfile name" do
      pidfile = described_class.fp_to_pidfile(forwarded_port1)
      expect(pidfile).to eq(pidfile1)
    end
  end

  describe "pidfile_path" do
    it "gets the pidfile path" do
      path = described_class.pidfile_path(forwarded_port1, machine)
      expect(path).to eq(machine.data_dir.join(pidfile1).to_s)
    end
  end

  describe "ssh_args" do
    it "returns expected args" do
      args = described_class.ssh_args(forwarded_port1, machine)
      expect(args).to eq(["-q", "-N",
        "-i", machine.data_dir.join("private_key").to_s,
        "-L", "9000:localhost:80",
        "-o", "ServerAliveInterval=10",
        "-o", "ServerAliveCountMax=3",
        "-o", "StrictHostKeyChecking=no",
        "user@10.0.0.1"
      ])
    end
  end

  describe "autossh_environment_variables" do
    it "defaults monitoring port to 0" do
      vars = described_class.autossh_environment_variables(forwarded_port1, machine)
      expect(vars).to eq({
        "AUTOSSH_PIDFILE" => machine.data_dir.join(pidfile1).to_s,
        "AUTOSSH_PORT"    => 0,
      })
    end
  end
end
