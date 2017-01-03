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
        OPEN_TIMEOUT = 5
        READ_TIMEOUT = 15

        # If Vagrant is running in a Skytap VM, returns metadata from which an
        # [API::Vm] can be constructed. Otherwise returns nil.
        #
        # @param [Vagrant::Machine] machine The guest machine (ignored).
        # @return [Hash] or [NilClass]
        def self.host_metadata(machine)
          logger = Log4r::Logger.new("vagrant_skytap::cap::host_metadata")

          # A Skytap VM can request information about itself from the metadata
          # service at http://gw/skytap. If the network is set to use custom
          # DNS, 'gw' may resolve to something else, in which case we fall back
          # to the service's link local address.
          ['gw', METADATA_LINK_LOCAL_ADDRESS].each do |host|
            begin
              http = Net::HTTP.new(host)
              http.open_timeout = OPEN_TIMEOUT
              http.read_timeout = READ_TIMEOUT

              # Test for a working web server before actually hitting the
              # metadata service. The response is expected to be 404.
              logger.debug("Checking for HTTP service on host '#{host}' ...")
              http.request(Net::HTTP::Get.new("/"))

              begin
                logger.debug("Fetching VM metadata from http://#{host}/skytap ...")
                response = http.request(Net::HTTP::Get.new("/skytap"))
              rescue Timeout::Error => ex
                logger.debug("The request timed out.")
                raise Errors::MetadataServiceUnavailable
              end

              if response.is_a?(Net::HTTPOK)
                if (attrs = JSON.parse(response.body)) && attrs.key?('configuration_url')
                  logger.debug('Metadata retrieved successfully.')
                  return attrs
                end
                logger.debug('The response did not contain VM metadata.')
                logger.debug("Response body: #{response.body}")
              else
                logger.debug("The server responded with status #{response.code}.")
                logger.debug("Response body: #{response.body}")
                raise Errors::MetadataServiceUnavailable if response.is_a?(Net::HTTPServerError)
              end
            rescue SystemCallError, SocketError, Timeout::Error, JSON::ParserError => ex
              logger.debug(ex)
              logger.debug("Response body: #{response.body}") if response.try(:body)
            end
          end

          logger.debug("Could not obtain VM metadata. Host is not a Skytap VM.")
          nil
        end
      end
    end
  end
end
