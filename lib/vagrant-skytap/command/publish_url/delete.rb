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
        class Delete < Vagrant.plugin("2", :command)
          include Command::Helpers

          def execute
            options = {}

            opts = OptionParser.new do |o|
              o.separator ""
              o.separator "Delete the sharing portal. Users can no longer access"
              o.separator "the environment through the URL."

              o.banner = "Usage: vagrant publish-url delete [options]"
              o.separator ""
              o.separator "Options:"
              o.separator ""

              o.on("-f", "--force", "Delete without prompting") do |f|
                options[:force] = f
              end
            end

            return unless argv = parse_options(opts)

            environment = fetch_environment
            if (environment).nil?
              @env.ui.info(I18n.t("vagrant_skytap.commands.publish_urls.fetch_environment_is_undefined"))
            elsif publish_sets = environment.publish_sets.presence
              unless options[:force]
                confirm = @env.ui.ask(I18n.t("vagrant_skytap.commands.publish_urls.confirm_delete"))
                return unless confirm.downcase == 'y'
              end
              publish_sets.each(&:delete)
              @env.ui.info(I18n.t("vagrant_skytap.commands.publish_urls.deleted"))
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
