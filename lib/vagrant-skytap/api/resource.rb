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

require_relative 'specified_attributes'

module VagrantPlugins
  module Skytap
    module API
      class Resource
        include SpecifiedAttributes

        attr_reader :attrs, :env

        class << self
          def resource_name
            name.split("::").last
          end
        end

        def initialize(*args)
          @attrs = args.first
          @env = args.last
        end

        def url
          "/#{self.class.resource_name.downcase}s/#{id}"
        end

        def reload
          resp = api_client.get(url)
          refresh(JSON.load(resp.body))
        end

        def refresh(attrs)
          @attrs = attrs
          self
        end

        private

        def api_client
          env[:api_client]
        end
      end
    end
  end
end
