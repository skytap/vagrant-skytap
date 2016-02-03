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
require 'json'

require 'vagrant-skytap/util/timer'
require 'vagrant-skytap/api/environment'
require_relative 'action_helpers'

require 'net/https'
require 'uri'
require 'base64'
require 'json'
require 'timeout'

module VagrantPlugins
  module Skytap
    module Action
      # Stops the Skytap VM and waits until stopped.
      class StopVm
        include ActionHelpers

        attr_reader :env

        def initialize(app, env)
          @app = app
          @env = env
          @logger = Log4r::Logger.new("vagrant_skytap::action::stop_vm")
        end

        def call(env)
          vm = current_vm(env)
          if env[:force_halt]
            vm.poweroff!
          else
            begin
              vm.stop!
            rescue Errors::InstanceReadyTimeout
              @logger.info(I18n.t("vagrant_skytap.graceful_halt_vm_failed"))
              vm.poweroff!
            end
          end
          @app.call(env)
        end
      end
    end
  end
end
