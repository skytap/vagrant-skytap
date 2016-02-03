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
      # This is based on code from the VirtualBox provider.
      class PrepareForwardedPortCollisionParams
        def initialize(app, env)
          @app = app
        end

        def call(env)
          # Get the forwarded ports used by other virtual machines and
          # consider those in use as well.
          env[:port_collision_extra_in_use] = env[:host].capability(:read_used_ports, env[:machine])

          # Build the remap for any existing collision detections
          remap = {}
          env[:port_collision_remap] = remap
          env[:host].capability(:read_forwarded_ports, env[:machine]).each do |fp|
            env[:machine].config.vm.networks.each do |type, options|
              next if type != :forwarded_port

              # If the ID matches the name of the forwarded port, then
              # remap.
              if options[:id] == fp.id
                remap[options[:host]] = fp.host_port
                break
              end
            end
          end

          @app.call(env)
        end
      end
    end
  end
end
