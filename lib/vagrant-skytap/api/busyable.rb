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
      module Busyable
        WAIT_TIMEOUT = 300
        WAIT_ITERATION_PERIOD = 2

        def update_with_retry(attrs, path=nil)
          retry_while_resource_busy do
            resp = api_client.put(path || url, JSON.dump(attrs))
            refresh(JSON.load(resp.body))
            break
          end
        end

        def retry_while_resource_busy(timeout=WAIT_TIMEOUT, &block)
          begin
            Timeout.timeout(timeout) do
              loop do
                break if env[:interrupted]
                begin
                  yield
                rescue Errors::ResourceBusy
                end
                sleep WAIT_ITERATION_PERIOD
              end
            end
          rescue Timeout::Error => ex
            raise Errors::InstanceReadyTimeout, timeout: timeout
          end
        end
      end
    end
  end
end
