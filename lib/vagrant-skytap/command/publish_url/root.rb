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

module VagrantPlugins
  module Skytap
    module Command
      module PublishUrl
        class Root < Vagrant.plugin("2", :command)
          def self.synopsis
            "manages published URLs"
          end

          def initialize(argv, env)
            super

            @main_args, @sub_command, @sub_args = split_main_and_subcommand(argv)

            @subcommands = Vagrant::Registry.new
            @subcommands.register(:create) do
              require_relative "create"
              Create
            end

            @subcommands.register(:delete) do
              require_relative "delete"
              Delete
            end

            @subcommands.register(:show) do
              require_relative "show"
              Show
            end
          end

          def execute
            if @main_args.include?("-h") || @main_args.include?("--help")
              # Print the help for all the publish-url commands.
              return help
            end

            # If we reached this far then we must have a subcommand. If not,
            # then we also just print the help and exit.
            command_class = @subcommands.get(@sub_command.to_sym) if @sub_command
            return help if !command_class || !@sub_command
            @logger.debug("Invoking command class: #{command_class} #{@sub_args.inspect}")

            # Initialize and execute the command class
            command_class.new(@sub_args, @env).execute
          end

          # Prints the help out for this command
          def help
            opts = OptionParser.new do |opts|
              opts.banner = "Usage: vagrant publish-url <subcommand> [<args>]"
              opts.separator ""
              opts.separator "Manages Skytap sharing portals."
              opts.separator ""
              opts.separator "Available subcommands:"

              # Add the available subcommands as separators in order to print them
              # out as well.
              keys = []
              @subcommands.each { |key, value| keys << key.to_s }

              keys.sort.each do |key|
                opts.separator "     #{key}"
              end

              opts.separator ""
              opts.separator "For help on any individual subcommand run `vagrant publish-url <subcommand> -h`"
            end

            @env.ui.info(opts.help, prefix: false)
          end
        end
      end
    end
  end
end
