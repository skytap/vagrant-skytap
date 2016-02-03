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

require 'vagrant-skytap/api/vm'
require_relative 'action_helpers'

module VagrantPlugins
  module Skytap
    module Action
      # This can be used with "Call" built-in to check if the environment
      # is created and branch in the middleware.
      class ExistenceCheck
        include ActionHelpers

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_skytap::action::existence_check")
        end

        def call(env)
          environment = env[:environment]
          env[:result] = if !environment
            :missing_environment
          elsif environment.vms.count == 0
            :no_vms
          elsif !current_vm(env)
            # Could be confusing. The *current* vm is not present. This response also implies that there are other vms.
            :missing_vm
          elsif environment.vms.count == 1
            :solitary_vm
          else
            :one_of_many_vms
          end
          @logger.debug("ExistenceCheck returning #{env[:result]}")

          @app.call(env)
        end
      end
    end
  end
end
