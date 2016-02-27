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

module VagrantPlugins
  module Skytap
    module Action
      class PrepareNFSSettings
        attr_reader :env, :machine

        def initialize(app,env)
          @app = app
          @env = env
          @logger = Log4r::Logger.new("vagrant_skytap::action::prepare_nfs_settings")
        end

        def call(env)
          @machine = env[:machine]

          if using_nfs?
            env[:nfs_host_ip] = read_host_ip
            env[:nfs_machine_ip] = read_machine_ip
          end

          @app.call(env)
        end

        # Determine whether there are enabled synced folders defined
        # for this machine which are either of type :nfs, or of the
        # default type (Vagrant may choose NFS as the default).
        # https://github.com/mitchellh/vagrant/issues/4192
        #
        # @return [Boolean]
        def using_nfs?
          machine.config.vm.synced_folders.any? do |_, opts|
            (opts[:type] == :nfs || opts[:type].blank?) unless opts[:disabled]
          end.tap do |ret|
            @logger.debug("PrepareNFSSettings#using_nfs? returning #{ret}. "\
              "Synced folders: #{machine.config.vm.synced_folders.inspect}")
          end
        end

        # Returns the IP address of the host, preferring one on an interface
        # which the client can route to.
        #
        # @return [String]
        def read_host_ip
          UDPSocket.open do |s|
            s.connect(machine.ssh_info[:host], 1)
            s.addr.last
          end.tap do |ret|
            @logger.debug("PrepareNFSSettings#read_host_ip returning #{ret}")
          end
        end

        # Returns the IP address of the guest VM.
        #
        # @return [String]
        def read_machine_ip
          machine.ssh_info[:host]
        end
      end
    end
  end
end

