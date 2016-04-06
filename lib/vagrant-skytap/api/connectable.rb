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

require 'vagrant-skytap/connection'

module VagrantPlugins
  module Skytap
    module API
      module Connectable
        # Determine the corresponding [Connection::Choice] subclass for this
        # resource type; e.g. for [API::Vpn] this would return
        # [Connection::VpnChoice]. This method may be overridden where the
        # class name varies from this pattern.
        #
        # @return [Class]
        def connection_choice_class
          require "vagrant-skytap/connection/#{self.class.rest_name}_choice"
          Class.const_get("VagrantPlugins::Skytap::Connection::#{self.class.name.split('::').last}Choice")
        end

        # Return a choice object representing the potential to connect
        # via this resource. Arguments depend on resource type.
        #
        # @return [Connection::Choice]
        def choice_for_setup(*args)
          connection_choice_class.new(env, self, *args)
        end
      end
    end
  end
end
