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

require 'base64'
require "vagrant-skytap/version"
require 'timeout'

module VagrantPlugins
  module Skytap
    module API
      class Client
        attr_reader :config, :http

        DEFAULT_TIMEOUT = 120
        MAX_RATE_LIMIT_RETRIES = 3
        DEFAULT_RETRY_AFTER_SECONDS = 5

        def initialize(config)
          @logger = Log4r::Logger.new("vagrant_skytap::api_client")

          @config = config
          uri = URI.parse(config.base_url)
          @http = Net::HTTP.new(uri.host, uri.port)

          @http.verify_mode = OpenSSL::SSL::VERIFY_NONE

          @http.use_ssl = uri.port == 443 || uri.scheme == 'https'
        end

        def get(path, options={})
          req('GET', path, nil, options)
        end

        def post(path, body=nil, options={})
          req('POST', path, body, options)
        end

        def put(path, body=nil, options={})
          req('PUT', path, body, options)
        end

        def delete(path, options={})
          req('DELETE', path, nil, options)
        end

        # +path+ may optionally include query and fragment parts
        #
        # +options+ are:
        #   query: A string or hash of the query string
        #   extra_headers: A hash of extra headers
        def req(method, path, body, options={})
          @logger.info("REST API call: #{method} #{path} #{'body: ' + body if body.present?}")

          uri = URI.parse(path)

          if qq = options[:query]
            if qq.is_a?(Hash)
              extra_query = qq.collect{|k,v| [k,v].join('=')}.join('&')
            else
              extra_query = qq.to_s
            end
          end

          if (query = [uri.query, extra_query].compact.join('&')).present?
            path = [uri.path, query].join('?')
          end

          headers = default_headers.merge(options[:extra_headers] || {})
          retry_after = DEFAULT_RETRY_AFTER_SECONDS
          most_recent_exception = nil

          begin
            Timeout.timeout(options[:timeout] || DEFAULT_TIMEOUT) do
              begin
                http.send_request(method, URI.encode(path), body, headers).tap do |ret|
                  @logger.debug("REST API response: #{ret.body}")
                  unless ret.code =~ /^2\d\d/
                    raise Errors::DoesNotExist, object_name: "Object '#{path}'" if ret.code == '404'
                    error_class = case ret.code
                    when '403'
                      Errors::Unauthorized
                    when '422'
                      Errors::UnprocessableEntity
                    when '423'
                      Errors::ResourceBusy
                    when '429'
                      retry_after = ret['Retry-After'] || DEFAULT_RETRY_AFTER_SECONDS
                      Errors::RateLimited
                    else
                      Errors::OperationFailed
                    end
                    raise error_class, err: error_string_from_body(ret)
                  end
                end
              rescue Errors::RateLimited => ex
                most_recent_exception = ex
                @logger.info("Rate limited, wil retry in #{retry_after} seconds")
                sleep retry_after.to_f + 0.1
                retry
              rescue Errors::ResourceBusy => ex
                most_recent_exception = ex
                @logger.debug("Resource busy, retrying")
                sleep DEFAULT_RETRY_AFTER_SECONDS
                retry
              end
            end
          rescue Timeout::Error => ex
            raise most_recent_exception if most_recent_exception
            raise Errors::OperationFailed, "Timeout exceeded"
          end
        end

        def error_string_from_body(resp)
          resp = resp.body if resp.respond_to?(:body)
          begin
            resp = JSON.load(resp)
            errors = resp['error'] || resp['errors']
            errors = errors.join('; ') if errors.respond_to? :join
          rescue
            # treat non-JSON string as error text
            errors = resp
          end
          errors if errors.present?
        end

        private

        def user_agent_string
          "Vagrant-Skytap/#{VagrantPlugins::Skytap::VERSION} Vagrant/#{Vagrant::VERSION}"
        end

        def default_headers
          {
            'Authorization' => auth_header,
            'Content-Type' => 'application/json',
            'Accept' => 'application/json',
            'User-Agent' => user_agent_string,
          }
        end

        def auth_header
          "Basic #{Base64.encode64(config.username + ":" +
                                   config.api_token)}".gsub("\n", '')
        end
      end
    end
  end
end
