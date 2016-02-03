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

require "vagrant/util/subprocess"
require "vagrant/util/safe_chdir"
require "vagrant-skytap/model/forwarded_port"
require 'log4r'

# Port forwarding for the Skytap provider is implemented
# using the autossh utility, which starts, monitors, and
# restarts SSH tunnels, and optionally creates pidfiles.
# We specify pidfile names which correspond to the
# forwarded port fields.

# Methods such as #ssh_args, which may need to return a
# different value for a particular OS, can be overridden
# by subclassing this capability file and registering
# the new host capability in the provider plugin.

module VagrantPlugins
  module Skytap
    module HostCommon
      module Cap
        class SSHTunnel
          class << self
            def create_logger
              raise NotImplementedError
            end

            # Start an autossh process for the given [Model::ForwardedPort]
            # on the given [Vagrant::Machine]. If autossh is not
            # available on the host, an appropriate error message
            # will be shown, asking the user to install it.
            #
            # @return [Vagrant::Util::Subprocess::Result]
            def start_ssh_tunnel(env, fp, machine)
              kill_ssh_tunnel(env, fp, machine)
              args = ssh_args(fp, machine)
              args << {env: autossh_environment_variables(fp, machine)}
              Vagrant::Util::Subprocess.execute("autossh", "-f", *args)
            end

            # Kill the autossh process for the given [Model::ForwardedPort]
            # on the given [Vagrant::Machine]. autossh will kill the ssh
            # child process before terminating.
            #
            # @return [Vagrant::Util::Subprocess::Result]
            def kill_ssh_tunnel(env, fp, machine)
              if pid = read_pid(pidfile_path(fp, machine))
                Vagrant::Util::Subprocess.execute("kill", pid.to_s)
              end
            end

            # Convenience method which kills all autossh processes for
            # the given [Vagrant::Machine].
            #
            # @return [Array] of [Model::ForwardedPort] objects
            def clear_forwarded_ports(env, machine)
              get_fp_from_directory(machine.data_dir).each do |fp|
                kill_ssh_tunnel(env, fp, machine)
              end
            end

            # The currently forwarded ports for this [Vagrant::Machine].
            #
            # @return [Array] of [Model::ForwardedPort] objects
            def read_forwarded_ports(env, machine)
              get_fp_from_directory(machine.data_dir)
            end

            # The currently forwarded ports for all *other*
            # [Vagrant::Machine]s in this project.
            #
            # @return [Array] of [Model::ForwardedPort] objects
            def read_used_ports(env, machine)
              search_paths = machine_data_dirs(env).reject!{|k,v| k == machine.name.to_s}.values
              search_paths.collect{|path| get_fp_from_directory(path)}.flatten
            end



            # Reads the process id (pid) from the given pidfile.
            #
            # @return [Integer], or nil if not found.
            def read_pid(pidfile_path)
              File.read(pidfile_path).presence.try(:to_i) if File.exist?(pidfile_path)
            end

            # Gets forwarded ports by reading pidfiles in the given
            # directory.
            #
            # @return [Array] of [Model::ForwardedPort] objects
            def get_fp_from_directory(dir)
              pidfiles = []
              Vagrant::Util::SafeChdir.safe_chdir(dir) do
                pidfiles = Dir.glob("*.pid")
              end
              pidfiles.collect{|pidfile| pidfile_to_fp(pidfile)}
            end

            # Returns a mapping of machine names to their data_dirs
            # (full paths).
            #
            # @return [Hash]
            def machine_data_dirs(env)
              h = {}
              env_path = env.local_data_path
              Vagrant::Util::SafeChdir.safe_chdir(env.local_data_path) do
                Dir.foreach("machines") do |machine_name|
                  data_dir = "machines/#{machine_name}/skytap"
                  if Dir.exist?(data_dir)
                    h[machine_name] = env_path.join(data_dir)
                  end
                end
              end
              h
            end

            # Gets the full path to the pidfile for the given
            # [Model::ForwardedPort] and [Vagrant::Machine].
            #
            # @return [Model::ForwardedPort]
            def pidfile_path(fp, machine)
              machine.data_dir.join(fp_to_pidfile(fp)).to_s
            end

            # Generate a pidfile name which encodes enough information
            # to reconstruct the given [Model::ForwardedPort].
            #
            # @return [String]
            def fp_to_pidfile(fp)
              "#{fp.id}_#{fp.protocol}_#{fp.host_port}_#{fp.guest_port}.pid"
            end

            # Create a [Model::ForwardedPort] from a parsed pidfile name.
            #
            # @return [Model::ForwardedPort]
            def pidfile_to_fp(pidfile)
              pidfile =~ /(\w*)_(\w*)_(\w*)_(\w*)\.pid/
              id, protocol, host_port, guest_port = $1, $2, $3, $4
              Model::ForwardedPort.new(id, host_port.to_i, guest_port.to_i, protocol: protocol)
            end



            # Gets the arguments to be passed to ssh for the given
            # [Model::ForwardedPort] on the given [Vagrant::Machine].
            #
            # @return [Array] of [String]
            def ssh_args(fp, machine)
              ssh_info = machine.ssh_info
              ssh_options = {
                "ServerAliveInterval" => 10,
                "ServerAliveCountMax" => 3,
                "StrictHostKeyChecking" => "no",
              }

              args = []
              args << "-q" # quiet
              args << "-N" # no remote command
              args << "-i" << machine.data_dir.join("private_key").to_s
              args << "-L" << "#{fp.host_port}:localhost:#{fp.guest_port}"
              ssh_options.each do |k, v|
                # options in ssh config file format
                args << "-o" << "#{k}=#{v}"
              end
              args << "#{ssh_info[:username]}@#{ssh_info[:host]}"
            end

            # Gets the environment variables to be set when calling
            # autossh.
            #
            # @return [Hash]
            def autossh_environment_variables(fp, machine, monitoring_port = 0)
              {
                "AUTOSSH_PIDFILE" => pidfile_path(fp, machine),
                "AUTOSSH_PORT" => monitoring_port,
              }
            end
          end
        end
      end
    end
  end
end
