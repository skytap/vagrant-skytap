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

require 'log4r'
require 'yaml'
require 'vagrant-skytap/vm_properties'
require 'vagrant-skytap/api/vpn'
require 'net/ssh/transport/session'

module VagrantPlugins
  module Skytap
    class SetupHelper
      attr_reader :env, :environment, :host_vm, :machine, :provider_config
      attr_reader :username, :password, :host, :port

      def self.run!(env, environment)
        new(env, environment).run!
      end

      def initialize(env, environment)
        @env = env
        @logger = Log4r::Logger.new("vagrant_skytap::setup_helper")
        @environment = environment
        @host_vm = env[:vagrant_host_vm]
        @machine = env[:machine]
        @provider_config = env[:machine].provider_config
        @username = @machine.config.ssh.username
        @password = @machine.config.ssh.password
        @host = @machine.config.ssh.host
        @port = @machine.config.ssh.port || Net::SSH::Transport::Session::DEFAULT_PORT
      end

      def current_vm
        if @environment && @machine
          @environment.get_vms_by_id([@machine.id]).first
        end
      end

      def running_in_skytap_vm?
        !!host_vm
      end

      def run!
        ask_routing
        ask_credentials
        write_properties
      end


      private


      def ask_credentials
        @logger.debug("ask_credentials")

        if !username
          creds = current_vm.credentials.select(&:recognized?)
          if creds.present?
            question = "How do you want to choose SSH credentials for machine '#{@machine.name}'?\n" \
              "Note that credentials retrieved from the Skytap VM will be stored in cleartext on your local filesystem."
            ask_from_list(question, credentials_choices(creds), 0) do |i|
              if cred = creds[i]
                @username = cred.username
                @password = cred.password
              end
            end
          else
            @logger.info("No login credentials found for the VM. Allowing fallback to default vagrant login.")
          end
        end
        [@username, @password]
      end

      def credentials_choices(creds)
        creds.collect do |c|
          "Use VM credentials stored in Skytap: #{c}"
        end.tap do |choices|
          choices << "Don't specify credentials: Use standard 'vagrant' login with insecure keypair"
        end
      end

      def ask_routing
        unless host && port
          iface = current_vm.interfaces.first
          choices = connection_choices(iface)

          if running_in_skytap_vm?
            unless choices.any?(&:valid?)
              raise Errors::NoSkytapConnectionOptions, message: choices.collect(&:validation_error_message).first
            end
          end

          choices.select!(&:valid?)
          raise Errors::NoConnectionOptions unless choices.present?

          choice = nil
          if !running_in_skytap_vm? && vpn_url = @provider_config.vpn_url
            choice = choices.detect do |choice|
              choice.vpn && vpn_url.include?(choice.vpn.id)
            end
            raise Errors::DoesNotExist, object_name: vpn_url unless choice
          elsif choices.count == 1
            choice = choices.first
            env[:ui].info("Using only available connection option: #{choice}")
          else
            question = "How do you want to connect to machine '#{@machine.name}'?"
            ask_from_list(question, choices, 0) do |i, _choice|
              choice = _choice
            end
          end
          @host, @port = choice.choose
        end
        @logger.debug("ask_routing returning guest VM address and port: #{@host}:#{@port}")
        [@host, @port]
      end

      def connection_choices(iface)
        if running_in_skytap_vm?
          tunnel_choices(iface)
        else
          vpn_choices(iface)
        end
      end

      def vpn_choices(iface)
        candidates = vpns.select do |vpn|
          vpn.nat_enabled? || vpn.subsumes?(iface.network)
        end

        candidates.collect {|vpn| vpn.choice_for_setup(iface.vm) }
      end

      def public_ip_choices(iface)
        ips = iface.public_ips + iface.available_ips
        ips.collect {|ip| ip.choice_for_setup(iface) }
      end

      def published_service_choices(iface)
        iface.published_service_choices
      end

      def tunnel_choices(guest_iface)
        candidates = host_vm.interfaces.collect(&:network)
        candidates.collect {|network| network.choice_for_setup(guest_iface) }
      end

      def vpns
        VagrantPlugins::Skytap::API::Vpn.all(env, query: {region: environment.region})
      end

      # Given a message and an array of choices, displays them to the user as a
      # numbered list and asks the user to choose one. Returns the index that
      # the user chose.
      #
      # The choices are presented to the user starting at 1, but the return
      # value is a 0-based Ruby index. If specified, +default_index+ should be
      # 0-based.
      #
      # If a block is given, yields chosen index.
      def ask_from_list(message, choices, default_index=nil, &block)
        if default_index && (default_index < 0 || default_index >= choices.size)
          raise ArgumentError.new("Bad value for default #{default_index.inspect}")
        end

        numbered_choices = choices.each_with_index.collect do |choice, i|
          "#{i+1}. #{choice}"
        end.join("\n")

        default_choice = " [#{default_index+1}]" if default_index
        prompt = "Enter choice number:#{default_choice} "

        index = nil

        until index && index >= 0 && index < choices.length
          input = env[:ui].ask([message, numbered_choices, prompt].join("\n\n"),
                               prefix: false)
          begin
            if default_index && input.blank?
              index = default_index
            else
              index = Integer(input, 10) - 1
            end
          rescue ArgumentError
            # No-op
          end
        end

        yield index, choices[index] if block_given?

        index
      end

      def ask(message, options={})
        prompt = message
        if default = options[:default]
          prompt = "#{message} [#{default}] "
        else
          prompt = "#{message} "
        end

        env[:ui].ask(prompt, {prefix: false}.merge(options))
      end

      def write_properties
        VmProperties.write(env[:machine].data_dir,
                              'username' => username,
                              'password' => password,
                              'host' => host,
                              'port' => port)
      end
    end
  end
end
