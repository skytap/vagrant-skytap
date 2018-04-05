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

require 'optparse'
require 'vagrant-skytap/command/helpers'

module VagrantPlugins
  module Skytap
    module Command
      module PublishUrl
        class Create < Vagrant.plugin("2", :command)
          include Command::Helpers

          def execute
            options = {}

            opts = OptionParser.new do |o|
              o.banner = "Usage: vagrant publish-url create [options]"
              o.separator ""
              o.separator "Share an environment via the Skytap Cloud UI."
              o.separator ""
              o.separator "Options:"
              o.separator ""


              o.on("-p", "--password PASSWORD", "Set a password for the publish set") do |p|
                options[:password] = p
              end

              o.on("-n", "--no-password", "Do not set a password") do |n|
                options[:no_password] = true
              end

              o.separator ""
              o.separator "You will be prompted for a password unless one of the"
              o.separator "options --password or --no-password have been provided."
              o.separator "Blank passwords are allowed."
              o.separator ""
            end

            return unless argv = parse_options(opts)

            unless options[:no_password] || password = options[:password]
              password = @env.ui.ask("Password for publish set (will be hidden; blank for no password): ", echo: false)
            end
            password ||= ""

            environment = fetch_environment
            if (environment).nil?
              @env.ui.info(I18n.t("vagrant_skytap.commands.publish_urls.fetch_environment_is_undefined"))
            else
              ps = environment.create_publish_set(
                name: "Vagrant publish set",
                publish_set_type: "single_url",
                vms: target_skytap_vms.collect do |vm|
                  {
                    vm_ref: vm.url,
                    access: "run_and_use",
                  }
                end,
                password: password
              )
              @logger.debug("New publish set: #{ps.url}")

              @env.ui.info(I18n.t("vagrant_skytap.commands.publish_urls.created", url: ps.desktops_url))
            end

            # Success, exit status 0
            0
          end
        end
      end
    end
  end
end
