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

require 'vagrant-skytap/connection'

module VagrantPlugins
  module Skytap
    module Connection
      class PublishedServiceChoice < Choice
        attr_reader :service

        def self.uncreated_choice(env, iface)
          new(env, iface, nil)
        end

        def initialize(env, iface, service=nil)
          @env = env
          @iface = iface
          @service = service
          @execution = PublishedServiceExecution.make(env, iface, service)
        end

        def choose
          execution.execute
          @service = execution.service
          [service.external_ip, service.external_port]
        end

        def valid?
          service.nil? || service.internal_port == DEFAULT_PORT
        end

        class PublishedServiceExecution < Execution
          attr_reader :service

          def self.make(env, iface, service=nil)
            if service
              UseExecution.new(env, iface, service)
            else
              CreateAndUseExecution.new(env, iface, service)
            end
          end

          def initialize(env, iface, service)
            @env = env
            @iface = iface
            @service = service
          end

          def message
            verb.tap do |ret|
              if self.is_a?(UseExecution)
                ret << " #{service.external_ip}:#{service.external_port}"
              end
            end
          end
        end

        class UseExecution < PublishedServiceExecution
          def verb
            I18n.t("vagrant_skytap.connections.published_service.verb_use")
          end

          def execute
            # No-op
          end
        end

        class CreateAndUseExecution < PublishedServiceExecution
          def verb
            I18n.t("vagrant_skytap.connections.published_service.verb_create_and_use")
          end

          def execute
            @service = iface.create_published_service(DEFAULT_PORT)
          end
        end
      end
    end
  end
end
