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

require "vagrant-skytap/api/vm"

module VagrantPlugins
  module Skytap
    module Action
      # If Vagrant is running in a Skytap VM, retrieve the VM's metadata,
      # instantiate the VM, and store the result in env[:vagrant_host_vm].
      # The request does not go through the REST API, so it can be made
      # without an api token.
      class GetHostVM
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_skytap::action::get_host_metadata")
        end

        def call(env)
          unless env[:vagrant_host_vm]
            if (metadata = env[:machine].provider.host_metadata)
              # The environment will be lazy loaded
              env[:vagrant_host_vm] = vm = API::Vm.new(metadata, nil, env)
              @logger.info("Running Vagrant in a Skytap VM. ID: #{vm.try(:id)}")
            end
          end

          @app.call(env)
        end
      end
    end
  end
end
