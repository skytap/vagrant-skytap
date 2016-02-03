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

class PublishedServiceChoice
  attr_reader :env, :iface, :service, :execution

  def self.uncreated_choice(env, iface)
    new(env, iface, nil)
  end

  def initialize(env, iface, service=nil)
    @env = env
    @iface = iface
    @service = service
    @execution = ServiceExecution.make(env, iface, service)
  end

  def to_s
    execution.message
  end

  def choose
    execution.execute
    @service = execution.service
    [service.external_ip, service.external_port]
  end

  def valid?
    service.nil? || service.internal_port == 22
  end

  class ServiceExecution
    def self.make(env, iface, service=nil)
      if service
        UseServiceExecution.new(env, iface, service)
      else
        CreateAndUseServiceExecution.new(env, iface, service)
      end
    end

    attr_reader :env, :iface, :service

    def initialize(env, iface, service)
      @env = env
      @iface = iface
      @service = service
    end
  end

  class UseServiceExecution < ServiceExecution
    def message
      "Use published service #{service.external_ip}:#{service.external_port}"
    end

    def execute
      # No-op
    end
  end

  class CreateAndUseServiceExecution < ServiceExecution
    def message
      'Create and use published service'
    end

    def execute
      @service = iface.create_published_service(22)
    end
  end
end

module VagrantPlugins
  module Skytap
    module API
      class PublishedService < Resource
        attr_reader :interface

        reads :id, :internal_port, :external_ip, :external_port

        def initialize(attrs, interface, env)
          super
          @interface = interface
        end

        def choice_for_setup
          PublishedServiceChoice.new(env, self)
        end
      end
    end
  end
end
