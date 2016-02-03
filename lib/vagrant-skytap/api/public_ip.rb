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

class PublicIpChoice
  attr_reader :env, :ip, :iface, :execution

  def initialize(env, ip, iface)
    @env = env
    @ip = ip
    @iface = iface
    @execution = AttachmentExecution.make(env, ip, iface)
  end

  def to_s
    "#{execution.verb} public IP: #{ip.address}".tap do |ret|
      if ip.deployed?
        ret << ' (attached and deployed to another VM)'
      elsif ip.attached?
        ret << ' (attached to another VM)'
      end
    end
  end

  def choose
    execution.execute

    host = ip.address
    port = 22
    [host, port]
  end

  def valid?
    true
  end

  class AttachmentExecution
    def self.make(env, ip, iface)
      if ip.attached?
        UseAttachmentExecution.new(env, ip, iface)
      else
        AttachAndUseExecution.new(env, ip, iface)
      end
    end

    attr_reader :env, :ip, :iface

    def initialize(env, ip, iface)
      @env = env
      @ip = ip
      @iface = iface
    end
  end

  class UseAttachmentExecution < AttachmentExecution
    def verb
      'Use'
    end

    def execute
      # No-op
    end
  end

  class AttachAndUseExecution < AttachmentExecution
    def verb
      'Attach and use'
    end

    def execute
      iface.attach_public_ip(ip)
    end
  end
end

module VagrantPlugins
  module Skytap
    module API
      class PublicIp < Resource
        attr_reader :interface

        reads :id, :address, :nics

        # +interface+ may be nil; i.e., this IP isn't attached to anything.
        def initialize(attrs, interface, env)
          super
          @interface = interface
        end

        def choice_for_setup(iface)
          PublicIpChoice.new(env, self, iface)
        end

        def attached?
          interface || nics.present?
        end

        def deployed?
          nics.any? {|nic_attrs| nic_attrs['deployed']}
        end
      end
    end
  end
end
