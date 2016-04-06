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

require 'net/ssh/transport/session'

# Encapsulates a chooseable option for establishing communication with the
# guest VM over SSH/WinRM. All valid options (e.g. using specific VPNs,
# creating a published service, etc.) are collected as Choices and
# presented to the user.

module VagrantPlugins
  module Skytap
    module Connection
      DEFAULT_PORT = Net::SSH::Transport::Session::DEFAULT_PORT

      # A Choice represents the potential for establishing a connection to the
      # guest VM via a specific resource.
      class Choice
        attr_reader :env, :iface, :execution, :validation_error_message

        # Thia method should be overridden to call #make on the
        # [Connection::Execution] subclass for this particular resource type.
        # The execution holds all the information needed to establish the
        # connection.
        def initialize(*args)
          @env = args.first
        end

        # Invokes the execution, and determines the IP address and port for
        # communicating with the guest VM.
        #
        # @return [Array] Tuple of [String], [Integer] The IP address and port
        #   for communicating with the guest VM.
        def choose
          raise NotImplementedError.new('Must override')
        end

        # Override this method to add any validation logic needed by a specific
        # resource type. For example, [Connection::TunnelChoice] must check for
        # subnet overlaps. If this method returns false, this particular choice
        # should not be offered to the user. For some resource types, it may
        # be useful to set @validation_error_message on this choice when
        # returning false.
        #
        # @return [Boolean]
        def valid?
          true
        end

        def to_s
          execution.message
        end
      end

      # An Execution implements a strategy for establishing a connection
      # to the guest VM using a given resource. A resource may have more
      # than one strategy, depending on the initial state of the connection.
      # (When the guest VM is first created, no connection will exist.)
      class Execution
        attr_reader :env, :iface

        def initialize(*args)
          @env, @iface, _ = args
        end

        # Creates an execution object which will perform the correct actions
        # to establish a connection via a specific connectable resource. This
        # method should be overridden to return an object of the correct
        # execution subclass given the resource's initial state. For example,
        # if the guest's network is already attached to this VPN, but
        # disconnected, this method would return a ConnectAndUseExecution.
        #
        # @return [Connection::Execution]
        def make(*args)
          raise NotImplementedError.new('Must override')
        end

        # Performs the API calls which establish the connection for
        # communicating with the guest VM. If the connection is already
        # established, as in the case of a guest VM which already exists,
        # this may be a no-op.
        def execute
          raise NotImplementedError.new('Must override')
        end

        # The name of the action(s) performed by this execution subclass,
        # e.g. "Connect and use".
        #
        # @return [String]
        def verb
          raise NotImplementedError.new('Must override')
        end

        # The description of the actions to be taken when this choice is
        # executed, e.g. "Connect to and use VPN 1".
        #
        # @return [String]
        def message
          verb
        end
      end
    end
  end
end
