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

module VagrantPlugins
  module Skytap
    module Command
      module Helpers
        def target_vms
          @target_vms ||= [].tap do |ret|
            with_target_vms{|machine| ret << machine}
          end
        end

        def fetch_environment
          if machine = target_vms.first
            @environment ||= machine.action(:fetch_environment)[:environment]
          end
        end

        def target_skytap_vms
          fetch_environment.get_vms_by_id(target_vms.collect(&:id))
        end

        def machine_names(vm_ids)
          target_vms.select{|m| vm_ids.include?(m.id)}.collect{|m| m.name.to_s}
        end
      end
    end
  end
end



