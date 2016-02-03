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
    module Model
      # This is based on code from the VirtualBox provider.
      class ForwardedPort
        # If true, this port should be auto-corrected.
        #
        # @return [Boolean]
        attr_reader :auto_correct

        # The unique ID for the forwarded port.
        #
        # @return [String]
        attr_reader :id

        # The protocol to forward.
        #
        # @return [String]
        attr_reader :protocol

        # The IP that the forwarded port will connect to on the guest machine.
        #
        # @return [String]
        attr_reader :guest_ip

        # The port on the guest to be exposed on the host.
        #
        # @return [Integer]
        attr_reader :guest_port

        # The IP that the forwarded port will bind to on the host machine.
        #
        # @return [String]
        attr_reader :host_ip

        # The port on the host used to access the port on the guest.
        #
        # @return [Integer]
        attr_reader :host_port

        def initialize(id, host_port, guest_port, options)
          @id         = id
          @guest_port = guest_port
          @host_port  = host_port

          options ||= {}
          @auto_correct = false
          @auto_correct = options[:auto_correct] if options.key?(:auto_correct)
          @guest_ip = options[:guest_ip] || nil
          @host_ip = options[:host_ip] || nil
          @protocol = options[:protocol] || "tcp"
        end

        # This corrects the host port and changes it to the given new port.
        #
        # @param [Integer] new_port The new port
        def correct_host_port(new_port)
          @host_port = new_port
        end

        # Returns true if the host port is privileged.
        #
        # @param [Boolean]
        def privileged_host_port?
          host_port <= 1024
        end

        # Returns true if this is the SSH port used internally
        # by Vagrant.
        #
        # @param [Boolean]
        def internal_ssh_port?
          (guest_port == 22 && host_port == 2222) || id == "ssh"
        end
      end
    end
  end
end
