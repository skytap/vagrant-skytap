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

module VagrantPlugins
  module Skytap
    module API
      class PublishSet < Resource

        attr_reader :environment
        reads :id, :url, :desktops_url

        def self.rest_name
          "publish_set"
        end

        def initialize(attrs, environment, env)
          super
          @environment = environment
        end

        def password_protected?
          # password attribute contains asterisks or null
          get_api_attribute('password').present?
        end

        def vm_ids
          vm_refs = get_api_attribute("vms").collect{|ref| ref['vm_ref']}
          vm_refs.collect{|ref| ref.match(/\/vms\/(\d+)/)}.compact.map{|match| match[1]}
        end

        def vms
          environment.get_vms_by_id(vm_ids)
        end

        def delete
          api_client.delete(url)
        end
      end
    end
  end
end
