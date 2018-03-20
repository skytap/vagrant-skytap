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

require "vagrant"

module VagrantPlugins
  module Skytap
    class Config < Vagrant.plugin("2", :config)
      # The user id for accessing Skytap.
      #
      # @return [String]
      attr_accessor :username

      # The secret API token for accessing Skytap.
      #
      # @return [String]
      attr_accessor :api_token

      # The base URL for Skytap API calls.
      #
      # @return [String]
      attr_accessor :base_url

      # The url of the source VM to use.
      #
      # @return [String]
      attr_accessor :vm_url

      # The url of the VPN to use for connecting to the VM.
      #
      # @return [String]
      attr_accessor :vpn_url

      # The timeout to wait for a VM to become ready.
      #
      # @return [Fixnum]
      attr_accessor :instance_ready_timeout

      # The total number of virtual CPUs for this VM.
      #
      # @return [Integer]
      attr_accessor :cpus

      # The number of virtual CPUs per socket.
      #
      # @return [Integer]
      attr_accessor :cpuspersocket

      # The RAM to use for this machine (measured in MB).
      #
      # @return [Integer]
      attr_accessor :ram

      # The VMware guest OS setting for this machine.
      #
      # @return [String]
      attr_accessor :guestos

      # The VMware guest OS setting for this machine.
      #
      # @return [Array]
      attr_accessor :disks

      # The Skytap Environment Name.
      #
      # @return [String]
      attr_accessor :environment_name

      # The Skytap Project to assign Environment.
      #
      # @return [String]
      attr_accessor :project_id

      def initialize(region_specific=false)
        @username               = UNSET_VALUE
        @api_token              = UNSET_VALUE
        @base_url               = UNSET_VALUE
        @vm_url                 = UNSET_VALUE
        @vpn_url                = UNSET_VALUE
        @instance_ready_timeout = UNSET_VALUE
        @region                 = UNSET_VALUE
        @environment_name       = UNSET_VALUE
        @project_id             = UNSET_VALUE

        @cpus                   = UNSET_VALUE
        @cpuspersocket          = UNSET_VALUE
        @ram                    = UNSET_VALUE
        @guestos                = UNSET_VALUE
        @disks                  = UNSET_VALUE
      end

      #-------------------------------------------------------------------
      # Internal methods.
      #-------------------------------------------------------------------

      def finalize!
        # Try to get access keys from standard Skytap environment variables; they
        # will default to nil if the environment variables are not present.
        @username  = ENV['VAGRANT_SKYTAP_USERNAME']  if @username  == UNSET_VALUE
        @api_token = ENV['VAGRANT_SKYTAP_API_TOKEN'] if @api_token == UNSET_VALUE

        # Base URL for API calls.
        @base_url = "https://cloud.skytap.com/" if @base_url == UNSET_VALUE

        # Source VM url must be set.
        @vm_url = nil if @vm_url == UNSET_VALUE

        # VPN to use for connection to VM
        @vpn_url = nil if @vpn_url == UNSET_VALUE

        # Set the default timeout for runstate changes (e.g. running a VM)
        @instance_ready_timeout = 300 if @instance_ready_timeout == UNSET_VALUE

        # Default Environment name
        @environment_name = "Default Environment Name" if @environment_name == UNSET_VALUE

        # Project ID defaults to nil
        @project_id = nil if @project_id == UNSET_VALUE

        # Hardware settings default to nil (will be obtained
        # from the source VM)
        @cpus          = nil if @cpus          == UNSET_VALUE
        @cpuspersocket = nil if @cpuspersocket == UNSET_VALUE
        @ram           = nil if @ram           == UNSET_VALUE
        @guestos       = nil if @guestos       == UNSET_VALUE
        @disks         = nil if @disks         == UNSET_VALUE

        # Mark that we finalized
        @__finalized = true
      end

      def validate(machine)
        errors = _detected_errors

        errors << I18n.t('vagrant_skytap.config.username_required') unless username
        errors << I18n.t('vagrant_skytap.config.api_token_required') unless api_token
        errors << I18n.t('vagrant_skytap.config.vm_url_required') unless vm_url

        { "Skytap Provider" => errors }
      end
    end
  end
end
