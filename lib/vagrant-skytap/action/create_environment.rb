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

require 'log4r'
require 'json'

require 'vagrant-skytap/setup_helper'
require 'vagrant-skytap/util/timer'
require 'vagrant-skytap/api/environment'
require 'vagrant-skytap/api/vm'

require 'net/https'
require 'uri'
require 'base64'
require 'json'
require 'timeout'

module VagrantPlugins
  module Skytap
    module Action
      # Creates an environment from the template URL present in the config
      # file. Stores the new environment URL in the environment properties.
      class CreateEnvironment
        attr_reader :env

        def initialize(app, env)
          @app = app
          @env = env
          @logger = Log4r::Logger.new("vagrant_skytap::action::create_environment")
        end

        def call(env)
          vm = API::Vm.fetch(env, vm_url)
          environment = API::Environment.create!(env, [vm])
          env[:environment] = environment
          environment.properties.write('url' => environment.url)
          env[:machine].id = environment.vms.first.id
          environment.wait_until_ready

          @app.call(env)
        end

        def vm_url
          env[:machine].provider_config.vm_url
        end
      end
    end
  end
end
