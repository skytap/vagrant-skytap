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

require 'vagrant-skytap/api/resource'
require 'vagrant-skytap/api/interface'
require 'vagrant-skytap/api/credentials'
require_relative 'runstate_operations'

module VagrantPlugins
  module Skytap
    module API
      class Vm < Resource
        include RunstateOperations

        attr_reader :provider_config

        reads :id, :interfaces, :credentials, :name, :configuration_url, :template_url

        class << self
          def fetch(env, url)
            raise Errors::BadVmUrl, url: url unless url =~ /\/vms\/\d+/
            resp = env[:api_client].get(url)
            new(JSON.load(resp.body), env[:environment], env)
          end
        end

        def initialize(attrs, environment, env)
          super
          @parent = environment
          @provider_config = env[:machine].provider_config
        end

        def refresh(attrs)
          @interfaces = nil
          @credentials = nil
          super
        end

        def interfaces
          @interfaces ||= (get_api_attribute('interfaces') || []).collect do |iface_attrs|
            Interface.new(iface_attrs, self, env)
          end
        end

        def get_interfaces_by_id(ids)
          interfaces.select{|iface| ids.include?(iface.id)}
        end

        def get_interface_by_id(id)
          get_interfaces_by_id([id]).first
        end

        def credentials
          @credentials ||= (get_api_attribute('credentials') || []).collect do |cred_attrs|
            Credentials.new(cred_attrs, self, env)
          end
        end

        def hardware
          get_api_attribute('hardware')
        end

        def from_template?
          !!template_url
        end

        def template_id
          template_url =~ /templates\/(\d+)/
          $1
        end

        def configuration_id
          configuration_url =~ /configurations\/(\d+)/
          $1
        end

        def parent_url
          template_url || configuration_url
        end

        def parent
          @parent ||= Environment.fetch(env, parent_url)
        end
        alias_method :environment, :parent

        def region
          @region ||= parent.region
        end
      end
    end
  end
end
