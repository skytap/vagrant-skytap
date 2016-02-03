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

require "log4r"
require_relative 'action_helpers'

module VagrantPlugins
  module Skytap
    module Action
      # Runs multiple VMs in parallel. Ensures that the REST call happens
      # only once.
      class RunEnvironment
        include ActionHelpers

        attr_reader :env

        def initialize(app, env)
          @app = app
          @env = env
          @logger = Log4r::Logger.new("vagrant_skytap::action::run_environment")
        end

        def call(env)
          environment = env[:environment]
          vm_ids = vm_ids_to_run

          if current_vm(env).id == vm_ids.first
            env[:ui].info(I18n.t("vagrant_skytap.running_environment"))
            @logger.info("Running VMs: #{vm_ids}")
            environment.run!(vm_ids)
          end

          @app.call(env)
        end

        def vm_ids_to_run
          @env[:initial_states].reject{|id, state| state == :running}.keys
        end
      end
    end
  end
end
