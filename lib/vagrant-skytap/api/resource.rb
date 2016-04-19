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

# Base class for all resources accessible through the REST API.

module VagrantPlugins
  module Skytap
    module API
      class Resource
        include SpecifiedAttributes

        attr_reader :attrs, :env

        class << self
          # Last segment of the class name (without the namespace).
          #
          # @return [String]
          def short_name
            name.split("::").last
          end

          # Resource name suitable for use in URLs. This should be overridden
          # for classes with camel-cased names (e.g., VpnAttachment).
          #
          # @return [String]
          def rest_name
            short_name.downcase
          end
        end

        def initialize(*args)
          @attrs = args.first
          @env = args.last
        end

        # The URL for this specific instance. This method should be overridden
        # for more complex routes such as Rails nested resources.
        #
        # @return [String]
        def url
          "/#{self.class.rest_name}s/#{id}"
        end

        # Re-fetch the object from the API and update attributes.
        #
        # @return [API::Resource]
        def reload
          resp = api_client.get(url)
          refresh(JSON.load(resp.body))
        end

        # Replace the object's attributes hash. Subclasses may override this
        # method to perform additional operations such as discarding cached child
        # collections.
        #
        # @return [API::Resource]
        def refresh(attrs)
          @attrs = attrs
          self
        end

        # Sets attributes on the Skytap model, then refreshes this resource
        # from the response.
        #
        # @param [Hash] attrs The attributes to update on the resource.
        # @param [String] path The path to this resource, if different from
        #   the default.
        # @return [API::Resource]
        def update(attrs, path=nil)
          resp = api_client.put(path || url, JSON.dump(attrs))
          refresh(JSON.load(resp.body))
        end

        # Remove this resource from Skytap.
        #
        # @return [NilClass]
        def delete
          api_client.delete(url)
        end

        private

        # Return a reference to the API client which was passed in when
        # the object was created.
        #
        # @return [API::Client]
        def api_client
          env[:api_client]
        end
      end
    end
  end
end
