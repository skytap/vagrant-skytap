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

module VagrantPlugins
  module Skytap
    module API
      module RunstateOperations
        RUNSTATE_RETRY = 5

        def run!
          set_runstate :running
        end

        def suspend!
          set_runstate :suspended
        end

        def stop!
          set_runstate :stopped
        end

        def poweroff!
          set_runstate :halted, completed_runstate: :stopped
        end

        def set_runstate(new_runstate, opts = {})
          completed_runstate = opts.delete(:completed_runstate) || new_runstate

          params = {runstate: new_runstate}.tap do |ret|
            ret[:multiselect] = opts[:vm_ids] if opts[:vm_ids]
          end
          update(params)

          wait_for_runstate(completed_runstate) unless runstate == completed_runstate
        end

        def wait_until_ready
          wait_for_runstate :ready
        end

        def wait_for_runstate(expected_runstate)
          expected_runstate = expected_runstate.to_s
          begin
            Timeout.timeout(provider_config.instance_ready_timeout) do
              loop do
                unless reload.busy?
                  break if runstate == expected_runstate || expected_runstate == 'ready'
                end
                sleep RUNSTATE_RETRY
              end
            end
          rescue Timeout::Error => ex
            raise Errors::InstanceReadyTimeout, timeout: provider_config.instance_ready_timeout
          end
        end

        def runstate
          get_api_attribute('runstate')
        end

        def busy?
          runstate == 'busy'
        end

        def stopped?
          runstate == 'stopped'
        end

        def running?
          runstate == 'running'
        end
      end
    end
  end
end
