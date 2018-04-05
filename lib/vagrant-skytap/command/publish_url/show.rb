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
        class Show < Vagrant.plugin("2", :command)
          include Command::Helpers

          def execute
            options = {}
            opts = OptionParser.new do |o|
              o.banner = "Usage: vagrant publish-url show [<args>]"
              o.separator ""
              o.separator "Show the sharing portal, the VMs included, and whether"
              o.separator "the URL is password-protected."
              o.separator ""
              o.separator "Available subcommands:"
            end

            return unless argv = parse_options(opts)

            environment = fetch_environment
            if (environment).nil?
              @env.ui.info(I18n.t("vagrant_skytap.commands.publish_urls.fetch_environment_is_undefined"))
            elsif publish_sets = environment.publish_sets.presence
              results = publish_sets.collect do |ps|
                "#{ps.desktops_url || 'n/a'}\n" \
                  "  VMs: #{machine_names(ps.vm_ids).join(', ').presence || '(none)'}" \
                  "  Password protected? #{ps.password_protected? ? 'yes' : 'no'}"
              end
              @env.ui.info(I18n.t("vagrant_skytap.commands.publish_urls.list", publish_urls: results.join("\n")))
            else
              @env.ui.info(I18n.t("vagrant_skytap.commands.publish_urls.empty_list"))
            end

            # Success, exit status 0
            0
          end
        end
      end
    end
  end
end
