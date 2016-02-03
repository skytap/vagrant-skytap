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
require_relative "mixin_machine_index"

module VagrantPlugins
  module Skytap
    module Action
      # Creates a list of vm ids from all Skytap VMs in Vagrant's global machine
      # index. Any Vagrant machine not on this list will have its NFS entry
      # pruned by the SyncedFolderCleanup action.
      # NOTE: Unfortunately Vagrant providers have no way to know about each
      # other's machines, so there's an impact on NFS mounts for machines
      # from other providers. https://github.com/mitchellh/vagrant/issues/6439
      class PrepareNFSValidIds
        include MixinMachineIndex

        def initialize(app, env)
          @app = app
          @env = env
          @logger = Log4r::Logger.new("vagrant_skytap::action::prepare_nfs_valid_ids")
        end

        def call(env)
          env[:nfs_valid_ids] = machine_index.collect{|entry| entry.extra_data['vm_id']}.compact
          @app.call(env)
        end
      end
    end
  end
end
