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
require 'vagrant-skytap/api/vpn_attachment'
require 'vagrant-skytap/util/subnet'

module VagrantPlugins
  module Skytap
    module API
      class Network < Resource
        attr_reader :environment

        reads :id, :subnet, :vpn_attachments

        def initialize(attrs, environment, env)
          super
          @environment = environment
        end

        def refresh(attrs)
          @vpn_attachments = nil
          super
        end

        def vpn_attachments
          @vpn_attachments ||= (get_api_attribute('vpn_attachments') || []).collect do |att_attrs|
            VpnAttachment.new(att_attrs, self, env)
          end
        end

        def subnet
          Util::Subnet.new(get_api_attribute('subnet'))
        end

        def attachment_for(vpn)
          vpn = vpn.id unless vpn.is_a?(String)
          vpn_attachments.detect {|att| att.vpn['id'] == vpn}
        end
      end
    end
  end
end
