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

require 'vagrant-skytap/util/compile_forwarded_ports'

module VagrantPlugins
  module Skytap
    module Action
      # This is based on code from the VirtualBox provider.
      class ForwardPorts
        include Util::CompileForwardedPorts

        def initialize(app, env)
          @app = app
        end

        def call(env)
          @env = env
          env[:forwarded_ports] ||= compile_forwarded_ports(env[:machine].config)

          if env[:forwarded_ports].any?(&:privileged_host_port?)
            env[:ui].warn I18n.t("vagrant.actions.vm.forward_ports.privileged_ports")
          end

          env[:ui].output(I18n.t("vagrant.actions.vm.forward_ports.forwarding"))
          forward_ports

          @app.call(env)
        end

        def forward_ports
          @env[:forwarded_ports].each do |fp|
            unless fp.internal_ssh_port?
              @env[:ui].detail(I18n.t("vagrant.actions.vm.forward_ports.forwarding_entry",
                                        adapter: fp.adapter,
                                        guest_port: fp.guest_port,
                                        host_port: fp.host_port))
              @env[:host].capability(:start_ssh_tunnel, fp, @env[:machine])
            end
          end
        end
      end
    end
  end
end
