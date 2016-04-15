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

require "socket"
require "net/http"
require "log4r"

module VagrantPlugins
  module Skytap
    module Cap
      module HostMetadata
        METADATA_LINK_LOCAL_ADDRESS = '169.254.169.254'
        OPEN_TIMEOUT = 2
        READ_TIMEOUT = 5

        # If Vagrant is running in a Skytap VM, returns metadata from which an
        # [API::Vm] can be constructed. Otherwise returns nil.
        #
        # @param [Vagrant::Machine] machine The guest machine (ignored).
        # @return [Hash] or [NilClass]
        def self.host_metadata(machine)
          logger = Log4r::Logger.new("vagrant_skytap::cap::host_metadata")

          # There are two addresses to try for the metadata service. If using
          # the default DNS, 'gw' will resolve to the endpoint address. If
          # using custom DNS, be prepared to fall back to the hard-coded IP
          # address.
          ['gw', METADATA_LINK_LOCAL_ADDRESS].each do |host|
            begin
              http = Net::HTTP.new(host)
              http.open_timeout = OPEN_TIMEOUT
              http.read_timeout = READ_TIMEOUT

              # Test for a working web server before actually hitting the
              # metadata service. The response is expected to be 404.
              http.request(Net::HTTP::Get.new("/"))

              begin
                response = http.request(Net::HTTP::Get.new("/skytap"))
              rescue Timeout::Error => ex
                raise Errors::MetadataServiceUnavailable
              end

              if response.is_a?(Net::HTTPServerError)
                raise Errors::MetadataServiceUnavailable
              elsif response.is_a?(Net::HTTPOK)
                attrs = JSON.parse(response.body)
                return attrs if attrs.key?('configuration_url')
                logger.debug("The JSON retrieved was not VM metadata! Ignoring.")
              end
            rescue SocketError => ex
              logger.debug("Could not resolve hostname '#{host}'.")
            rescue Errno::ENETUNREACH => ex
              logger.debug("No route exists for '#{host}'.")
            rescue Timeout::Error => ex
              logger.debug("Response timed out for '#{host}'.")
            rescue JSON::ParserError
              logger.debug("Response from '#{host}' was garbled.")
            end
          end

          nil
        end
      end
    end
  end
end
