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
      class PublicIpChoice < Choice
        attr_reader :ip

        def initialize(env, ip, iface)
          @env = env
          @ip = ip
          @iface = iface
          @execution = PublicIpAttachmentExecution.make(env, iface, ip)
        end

        def choose
          execution.execute

          host = ip.address
          [host, DEFAULT_PORT]
        end

        class PublicIpAttachmentExecution < Execution
          attr_reader :ip

          def self.make(env, iface, ip)
            if ip.attached?
              UseExecution.new(env, iface, ip)
            else
              AttachAndUseExecution.new(env, iface, ip)
            end
          end

          def initialize(env, iface, ip)
            super
            @ip = ip
          end

          def message
            "#{verb}: #{ip.address}".tap do |ret|
              if ip.deployed?
                ret << " " << I18n.t("vagrant_skytap.connections.public_ip.deployed")
              elsif ip.attached?
                ret << " " << I18n.t("vagrant_skytap.connections.public_ip.attached")
              end
            end
          end
        end

        class UseExecution < PublicIpAttachmentExecution
          def verb
            I18n.t("vagrant_skytap.connections.public_ip.verb_use")
          end

          def execute
            # No-op
          end
        end

        class AttachAndUseExecution < PublicIpAttachmentExecution
          def verb
            I18n.t("vagrant_skytap.connections.public_ip.verb_attach")
          end

          def execute
            iface.attach_public_ip(ip)
          end
        end
      end
    end
  end
end
