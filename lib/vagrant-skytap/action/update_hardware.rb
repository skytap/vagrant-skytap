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
require 'vagrant-skytap/api/vm'
require_relative 'action_helpers'

module VagrantPlugins
  module Skytap
    module Action
      # This action compares the machine's hardware settings with the
      # vm's hardware attributes and updates if needed.
      class UpdateHardware
        include ActionHelpers

        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_skytap::action::update_hardware")
        end

        def call(env)
          if vm = current_vm(env)
            provider_config = env[:machine].provider_config
            hardware_info = {
              cpus:            provider_config.cpus,
              cpus_per_socket: provider_config.cpuspersocket,
              ram:             provider_config.ram,
              guestOS:         provider_config.guestos,
            }.reject{|k, v| v.nil? || v == vm.hardware[k.to_s]}

            if hardware_info.present?
              @logger.info("Updating hardware properties: #{hardware_info}")
              vm.update(hardware: hardware_info)
            end

            unless provider_config.vm_name.nil?
              vm.update(name: provider_config.vm_name)
            end
          end

          @app.call(env)
        end
      end
    end
  end
end
