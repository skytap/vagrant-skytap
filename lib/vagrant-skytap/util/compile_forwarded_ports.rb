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

require "vagrant/util/scoped_hash_override"
require 'vagrant-skytap/model/forwarded_port'
module VagrantPlugins
  module Skytap
    module Util
      # This is based on code from the VirtualBox provider.
      module CompileForwardedPorts
        include Vagrant::Util::ScopedHashOverride

        # This method compiles the forwarded ports into [ForwardedPort]
        # models.
        def compile_forwarded_ports(config)
          mappings = {}

          config.vm.networks.each do |type, options|
            if type == :forwarded_port
              guest_port = options[:guest]
              host_port  = options[:host]
              protocol   = options[:protocol] || "tcp"
              options    = scoped_hash_override(options, :skytap)
              id         = options[:id]

              # If the forwarded port was marked as disabled, ignore.
              next if options[:disabled]
              mappings[host_port.to_s + protocol.to_s] =
                Model::ForwardedPort.new(id, host_port, guest_port, options)
            end
          end

          mappings.values
        end
      end
    end
  end
end
