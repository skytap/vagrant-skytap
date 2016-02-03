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

require 'timeout'
require "log4r"

module VagrantPlugins
  module Skytap
    module Action
      # Extends the builtin WaitForCommunicator action to retry on
      # "network unreachable" errors, which can sometimes occur when
      # a Skytap environment is started.
      class WaitForCommunicator < Vagrant::Action::Builtin::WaitForCommunicator

        def initialize(app, env, states=nil)
          super
          @logger = Log4r::Logger.new("vagrant_skytap::action::wait_for_communicator")
        end

        alias_method :builtin_action_call, :call

        def call(env)
          # The SSH communicator handles certain exceptions by raising a
          # corresponding VagrantError which can be handled gracefully,
          # i.e. by the #wait_for_ready method, which continues to retry
          # until the boot_timeout expires.
          #
          # The communicator does a limited number of retries for
          # Errno::ENETUNREACH, but then allows the exception to bubble up
          # to the user. Here we swallow this exception and essentially
          # retry the original WaitForCommunicator action.
          begin
            Timeout.timeout(env[:machine].config.vm.boot_timeout) do
              while true do
                begin
                  break builtin_action_call(env)
                rescue Errno::ENETUNREACH
                  @logger.info("Rescued Errno::ENETUNREACH and retrying original WaitForCommunicator action.")
                  env[:ui].detail("Warning: The network was unreachable. Retrying...")
                end
                return if env[:interrupted]
              end
            end
          rescue Timeout::Error
            raise Vagrant::Errors::VMBootTimeout
          end
        end
      end
    end
  end
end
