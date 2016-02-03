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
#require 'vagrant'
require_relative 'action_helpers'

module VagrantPlugins
  module Skytap
    module Action
      # sets VM hostname via the API
      class SetHostname
        include ActionHelpers

        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_skytap::action::set_hostname")
        end

        def call(env)
          if hostname = env[:machine].config.vm.hostname
            if vm = current_vm(env)
              if nic = vm.interfaces.first
                if hostname != nic.get_api_attribute('hostname')
                  @logger.info("Updating hostname: #{hostname}")
                  nic.update_with_retry(hostname: hostname)
                end
              end
            end
          end

          @app.call(env)
        end
      end
    end
  end
end
