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

begin
  require "vagrant"
rescue LoadError
  raise "The Vagrant Skytap plugin must be run within Vagrant."
end

# This is a sanity check to make sure no one is attempting to install
# this into an early Vagrant version.
if Vagrant::VERSION < "1.2.0"
  raise "The Vagrant Skytap plugin is only compatible with Vagrant 1.2+"
end

module VagrantPlugins
  module Skytap
    class Plugin < Vagrant.plugin("2")
      name "Skytap"
      description <<-DESC
      This plugin installs a provider that allows Vagrant to manage
      machines in Skytap.
      DESC

      config(:skytap, :provider) do
        require_relative "config"
        Config
      end

      provider(:skytap, parallel: true) do
        # Setup logging and i18n
        setup_logging
        setup_i18n

        # Return the provider
        require_relative "provider"
        Provider
      end

      command("up", primary: true) do
        require_relative "command/up"
        Skytap::Command::Up
      end

      command("publish-url", primary: true) do
        require_relative "command/publish_url/root"
        Skytap::Command::PublishUrl::Root
      end

      provider_capability(:skytap, :public_address) do
        require_relative "cap/public_address"
        Cap::PublicAddress
      end

      provider_capability(:skytap, :host_metadata) do
        require_relative "cap/host_metadata"
        Cap::HostMetadata
      end

      %w[start_ssh_tunnel kill_ssh_tunnel clear_forwarded_ports read_forwarded_ports read_used_ports].each do |cap|
        host_capability("bsd", cap) do
          require_relative "hosts/bsd/cap/ssh_tunnel"
          HostBSD::Cap::SSHTunnel
        end
        host_capability("linux", cap) do
          require_relative "hosts/linux/cap/ssh_tunnel"
          HostLinux::Cap::SSHTunnel
        end
        host_capability("windows", cap) do
          require_relative "hosts/windows/cap/ssh_tunnel"
          HostWindows::Cap::SSHTunnel
        end
      end

      # This initializes the internationalization strings.
      def self.setup_i18n
        I18n.load_path << File.expand_path("locales/en.yml", Skytap.source_root)
        I18n.reload!
      end

      # This sets up our log level to be whatever VAGRANT_LOG is.
      def self.setup_logging
        require "log4r"

        level = nil
        begin
          level = Log4r.const_get(ENV["VAGRANT_LOG"].upcase)
        rescue NameError
          # This means that the logging constant wasn't found,
          # which is fine. We just keep `level` as `nil`. But
          # we tell the user.
          level = nil
        end

        # Some constants, such as "true" resolve to booleans, so the
        # above error checking doesn't catch it. This will check to make
        # sure that the log level is an integer, as Log4r requires.
        level = nil if !level.is_a?(Integer)

        # Set the logging level on all "vagrant" namespaced
        # logs as long as we have a valid level.
        if level
          logger = Log4r::Logger.new("vagrant_skytap")
          logger.outputters = Log4r::Outputter.stderr
          logger.level = level
          logger = nil
        end
      end
    end
  end
end
