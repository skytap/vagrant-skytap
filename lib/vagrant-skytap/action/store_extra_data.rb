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
require_relative "mixin_machine_index"

module VagrantPlugins
  module Skytap
    module Action
      # Stores some provider-specific data in Vagrant's global machine index.
      class StoreExtraData
        include MixinMachineIndex
        attr_reader :env

        def initialize(app, env)
          @app = app
          @env = env
          @logger = Log4r::Logger.new("vagrant_skytap::action::store_extra_data")
        end

        def call(env)
          entry = machine_index_entry
          unless entry.extra_data.has_key?('vm_id')
            entry.extra_data.merge!(provider_extra_data)
            entry = machine_index.set(entry)
          end
          machine_index.release(entry)

          @app.call(env)
        end

        def provider_extra_data
          {
            'vm_id' => env[:machine].id
          }
        end
      end
    end
  end
end
